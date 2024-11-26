`timescale 1ns / 1ps

module uart_tx(
	input wire i_clk, i_rst_n,
	input wire i_bd,
	input wire tx_en, //enable uart tx transmitter
	input wire [7:0] i_tx_data,
	
	output reg o_tx
	//parallel 2 serial transmission
	
    );

//state defi of machines
parameter T_IDLE  = 3'b000;
parameter T_START = 3'b001;
parameter T_DATA  = 3'b010;
parameter T_STOP  = 3'b011;
parameter T_CLEAN = 3'b100;

reg [7:0] r_tx_data;
reg [7:0] o_tf_data;
reg [2:0] bitcnt;
reg [2:0] nt_state, state;

reg en_dat, end_tx, end_st;
reg bd_cnt, bdcnt2;

//sample buffer of tx
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		r_tx_data <= 8'h0;
	end
	else begin
		r_tx_data <= i_tx_data;
	end
end

//state machine indicators
wire ind_T_IDLE, ind_T_START,ind_T_DATA, ind_T_STOP, ind_T_CLEAN; 
assign ind_T_IDLE  = (state == T_IDLE)  ? 1'b1 : 1'b0;
assign ind_T_START = (state == T_START) ? 1'b1 : 1'b0;
assign ind_T_DATA  = (state == T_DATA)  ? 1'b1 : 1'b0;
assign ind_T_STOP  = (state == T_STOP)  ? 1'b1 : 1'b0;
assign ind_T_CLEAN = (state == T_CLEAN) ? 1'b1 : 1'b0;

//sequential cell
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		state <= T_IDLE;
	end
	else begin
		state <= nt_state;
	end
end

//combinational cell
always@ (*) begin
	//initial values to avoid latch
	o_tx = 1'b1;
	
	case(state)
	T_IDLE:
	begin
		o_tx = 1'b1;
		if(tx_en) begin
			nt_state = T_START;
		end
		else begin
			nt_state = T_IDLE;
		end
	end
	T_START:
	begin
		o_tx = 1'b0; //send start bit
		if(en_dat) begin 
			nt_state = T_DATA;
		end
		else begin
			nt_state = T_START;
		end
	end
	T_DATA:
	begin
		o_tx = r_tx_data[bitcnt];
		if(end_tx) begin
			nt_state = T_STOP;
		end
		else begin
			nt_state = T_DATA;
		end
	end
	T_STOP:
	begin
		o_tx = 1'b1;
		if(end_st)
			nt_state = T_CLEAN;
		else begin
			nt_state = T_STOP;
		end
	end
	T_CLEAN:
	begin
		o_tx = 1'b1;
		nt_state = T_IDLE;
	end
	default: nt_state = T_IDLE;
	endcase
end

//transfer data
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		bitcnt <= 3'h0;
		end_tx <= 1'b0;
	end
	else if(i_bd && ind_T_DATA) begin
		if(bitcnt < 7) begin
			bitcnt <= bitcnt + 1'b1;
		end
		else begin
			bitcnt <= 3'h0;
			end_tx <= 1'b1;
		end
	end
	else if(ind_T_STOP)
	begin
		end_tx <= 1'b0;
	end		
end

//one period for start bit
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		en_dat <= 1'b0;
	end
	else if(i_bd && ind_T_START) 
	begin
		en_dat <= 1'b1;
	end
	else if(~ind_T_START) 
	begin
		en_dat <= 1'b0;
	end
end

//Last one-two baudrate period for stop bit
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		bdcnt2  <= 1'b0;
		end_st  <= 1'b0;
	end
	else if(i_bd && ind_T_STOP) begin
		if(bdcnt2 < 1) begin
			bdcnt2  <= bdcnt2 + 1'b1;
			end_st  <= 1'b0;
		end
		else begin
			bdcnt2  <= 1'b0;
			end_st  <= 1'b1;
		end
	end
	else begin
		end_st <= 1'b0; //last one ~ two baudrate period for T_START state
	end
end

endmodule: uart_tx
