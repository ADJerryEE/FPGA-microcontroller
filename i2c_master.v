`timescale 1ns / 1ps

module i2c_master(
	input wire i_clk,
	input wire i_rst_n,
	input wire i_i2c_en,
	input wire rw_req,	//read or write operation request
	
	output wire [7:0] o_i2c_data, //test only
	inout wire io_scl, io_sda
	
    );
	
//state machine definition
parameter M_IDLE  = 4'd0;
parameter M_START = 4'd1;
parameter M_ADDR  = 4'd2;
parameter M_RW	  = 4'd3;
parameter M_ACK   = 4'd4;
parameter M_WORD  = 4'd5;
parameter M_ACKD  = 4'd6;
parameter M_WDATA = 4'd7;
parameter M_RDATA = 4'd8; //current address read
parameter M_ACKS  = 4'd9;
parameter M_ACKR  = 4'd10;
parameter M_NACK  = 4'd11;
parameter M_STOP  = 4'd12;

//parameter divider ratio = 500, fscl = 200khz
parameter f_sclth = (9'h1F4 - 1);
parameter f_duty  = (9'h1F4 / 2); //even number for 50 50 duty
parameter th_start= (8'h64 - 1);

//registers and wire definition
reg r_i2c_en, t_i2c_en;
reg r_rw_req, t_rw_req;
reg addr_done, sda_peri;
 
reg r_i2c_sda, scl_daflow, sda_daflow;
reg r_ack;
reg [6:0] slave_addr;
reg [7:0] i2c_data, i2c_word, rd_i2c_data;
reg [8:0] cnt_scl;
reg [7:0] cnt_start, cnt_stop;

//test counter
reg en_cnt;
wire w_scl, w_sclstb, stb_start, stb_stop;
wire ind_M_IDLE, ind_M_START, ind_M_ACK, ind_M_RW, int_M_DATA, ind_M_STOP, ind_M_ACKD, ind_M_ACKS;
wire ind_M_RDATA, ind_M_NACK, ind_M_ACKR;
wire scl_pos, scl_neg;

reg [3:0] state, nt_state;
reg [2:0] bitcnt;

//state machine indicators
assign ind_M_IDLE = (state == M_IDLE )? 1'b1 : 1'b0;
assign ind_M_START= (state == M_START)? 1'b1 : 1'b0;
assign ind_M_ACK  = (state == M_ACK)  ? 1'b1 : 1'b0;
assign ind_M_RW   = (state == M_RW)   ? 1'b1 : 1'b0;
assign ind_M_ACKD = (state == M_ACKD) ? 1'b1 : 1'b0;
assign ind_M_ACKS = (state == M_ACKS) ? 1'b1 : 1'b0;
assign ind_M_ACKR = (state == M_ACKR) ? 1'b1 : 1'b0;
assign ind_M_RDATA= (state == M_RDATA)? 1'b1 : 1'b0;
assign ind_M_NACK = (state == M_NACK) ? 1'b1 : 1'b0;
assign ind_M_STOP = (state == M_STOP) ? 1'b1 : 1'b0;


assign scl_pos = (cnt_scl == 375) ? 1'b1 : 1'b0; //scl rising, do nothing
assign scl_neg = (cnt_scl == 125) ? 1'b1 : 1'b0; //scl falling , do nothing

//sample i_i2c_en
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		r_i2c_en <= 1'b0;
		t_i2c_en <= 1'b0;
	end
	else begin
		r_i2c_en <= i_i2c_en;
		t_i2c_en <= r_i2c_en;
	end
end

//force to be one time transaction for testing only.
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) en_cnt <= 1'b0;
	else if (ind_M_STOP) en_cnt <= 1'b1;
end

//sample read or write request.  1 for reading 0 for writting.
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		r_rw_req <= 1'b1; 
		t_rw_req <= 1'b1;
	end
	else begin
		r_rw_req <= rw_req;
		t_rw_req <= r_rw_req;
	end
end

//access a specific slave address of an EEPROM
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) 
	begin 
		slave_addr <= 7'h50; //0x50h
		i2c_data   <= 8'hC0; //testing only
		i2c_word   <= 8'h00; //testing only for word address
		
		//i2c_data   <= 8'hF0; //testing only
		//i2c_word   <= 8'h01; //testing only for word address
		
		//i2c_data   <= 8'hB0; //testing only
		//i2c_word   <= 8'h02; //testing only for word address
	end
end

//i2c scl generator, 200khz with 50-50 duty
assign w_sclstb = (cnt_scl == f_sclth) ? 1'b1 : 1'b0;
assign w_scl = (cnt_scl <= f_duty) ? 1'b0 : 1'b1;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || w_sclstb) begin
		cnt_scl <= 9'h0;
	end
	else if(t_i2c_en && ~ind_M_IDLE && ~ind_M_START) begin
		cnt_scl <= cnt_scl + 1'b1;
	end
end

//setup time of start bit lasts 1us since the target eeprom 0.6us minimum.
assign stb_start = (cnt_start == th_start)? 1'b1 : 1'b0;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || ~ind_M_START) begin
		cnt_start <= 8'h0;
	end
	else begin
		cnt_start <= cnt_start + 1'b1; 
	end
end

//setup time of stop bit lasts 1us since the target eeprom 0.6us minimum.
assign stb_stop = (cnt_stop == th_start)? 1'b1 : 1'b0;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || ~ind_M_STOP) begin
		cnt_stop <= 8'h0;
	end
	else begin
		cnt_stop <= cnt_stop + 1'b1; 
	end
end

//sda hold time period
//always@ (posedge i_clk or negedge i_rst_n) begin with mix synchronous and asynchronous issue form critical warning
always@ (posedge i_clk) begin
	if(~i_rst_n || ind_M_IDLE || ind_M_STOP) sda_peri <= 1'b0;
	else if(scl_neg) sda_peri <= 1'b1;
end

//bitcnt for iosda transition, MSB to LSB
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || addr_done) begin
		bitcnt <= 3'h7;
	end
	else if(scl_neg && ~ind_M_RW && ~ind_M_ACK && ~ind_M_ACKD && ~ind_M_ACKS) begin
		bitcnt <= bitcnt - 1'b1;
	end
end

//addr_done indicator
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) addr_done <= 1'b0;
	else if(scl_neg && bitcnt == 0) addr_done <= 1'b1; //for M_ADDR
	else if(scl_neg && ind_M_RW)    addr_done <= 1'b1;
	else if(scl_neg && ind_M_ACK)   addr_done <= 1'b1;
	else if(scl_neg && ind_M_ACKD)  addr_done <= 1'b1;
	else if(scl_neg && ind_M_ACKS)  addr_done <= 1'b1;
	else if(scl_neg && ind_M_ACKR)  addr_done <= 1'b1;
	else if(scl_neg && ind_M_NACK)  addr_done <= 1'b1;
	else addr_done <= 1'b0;
end

//ACK and NACK sample
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) r_ack <= 1'b0; 
	else if((ind_M_ACK || ind_M_ACKD || ind_M_ACKS || ind_M_ACKR) && scl_pos) begin 
		if(~io_sda) r_ack <= 1'b1;
		else r_ack <= 1'b0;
	end
	//else r_ack <= 1'b0;
end

//DATA sample for read option
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) rd_i2c_data <= 8'h00; 
	else if(ind_M_RDATA && scl_pos) rd_i2c_data[bitcnt] <= io_sda;
end

//sequential logic for state machine
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) state <= M_IDLE;
	else state <= nt_state;
end
	
//combinational logic for state machine
always@ (*) begin
//initial values
	scl_daflow = 1'b0;
	sda_daflow = 1'b0;
	r_i2c_sda  = 1'b1;
	case(state)
	M_IDLE:
	begin
		if(t_i2c_en && (~en_cnt)) nt_state = M_START;
		else nt_state = M_IDLE;
	end
	M_START:
	begin
		sda_daflow = 1'b1; //generate start bit
		r_i2c_sda  = 1'b0;
		if(stb_start) begin //last a specific period on purpose
			nt_state = M_ADDR;
		end
		else begin
			nt_state = M_START;
		end
	end
	M_ADDR:
	begin
		scl_daflow = 1'b1; //enable io_scl
		sda_daflow = 1'b1; //enable io_sda
		if(addr_done) begin 
			nt_state  = M_RW;
		end
		else if(sda_peri) begin
			r_i2c_sda = slave_addr[bitcnt];
			nt_state  = M_ADDR;
		end
		else begin 
			r_i2c_sda = 1'b0;
			nt_state  = M_ADDR;
		end
	end
	M_RW:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b1;
		if(addr_done) begin 
			if(t_rw_req) nt_state = M_ACKR;
			else nt_state = M_ACK;
		end
		else if(t_rw_req) begin 
			r_i2c_sda = 1'b1; nt_state = M_RW;
		end
		else begin r_i2c_sda = 1'b0; nt_state = M_RW;
		end
	end
	M_ACKR:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) begin
			if(r_ack) nt_state = M_RDATA;
			else nt_state = M_IDLE;
		end
		else nt_state = M_ACKR;
	end
	M_ACK:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) begin
			if(r_ack) nt_state = M_WORD;
			else nt_state = M_IDLE;
		end
		else nt_state = M_ACK;
	end
	M_WORD:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b1;
		if(addr_done) nt_state = M_ACKD;
		else begin
			r_i2c_sda = i2c_word[bitcnt];
			nt_state  = M_WORD;
		end
	end
	M_ACKD:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) begin
			if(r_ack) nt_state = M_WDATA;
			else nt_state = M_IDLE;
		end
		else nt_state = M_ACKD;
	end
	M_WDATA:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b1;
		if(addr_done) nt_state = M_ACKS;
		else begin
			r_i2c_sda = i2c_data[bitcnt];
			nt_state  = M_WDATA;
		end
	end
	M_RDATA:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) nt_state = M_NACK;
		else nt_state = M_RDATA;
	end
	M_NACK:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) nt_state = M_STOP;
		else begin
			nt_state  = M_NACK;
		end
	end
	M_ACKS:
	begin
		scl_daflow = 1'b1; 
		sda_daflow = 1'b0;
		if(addr_done) begin
			if(r_ack) nt_state = M_STOP;
			else nt_state = M_IDLE;
		end
		else nt_state = M_ACKS;
	end
	M_STOP:
	begin
		scl_daflow = 1'b0; 
		sda_daflow = 1'b1; //generate stop bit
		r_i2c_sda  = 1'b0;
		
		if(stb_stop) begin //last a specific period on purpose
			r_i2c_sda= 1'b1;
			nt_state = M_IDLE;
		end
		else begin
			nt_state = M_STOP;
		end
	end
	default: nt_state = M_IDLE;
	endcase
end

//tri-state control
assign io_scl = (scl_daflow) ? w_scl : 1'bz;
assign io_sda = (sda_daflow) ? r_i2c_sda : 1'bz;

//testing only
assign o_i2c_data = rd_i2c_data;

endmodule : i2c_master
