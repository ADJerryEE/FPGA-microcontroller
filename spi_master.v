`timescale 1ns / 1ps

//This module is to access spi device with spi mode 3, CPOL = 1'b1 and CPHA = 1'b1;
module spi_master(
	input wire i_clk,
	input wire i_rst_n,
	input wire i_spi_en, //external enable spi signal
	input wire i_miso,
	//input wire i_rwreq,
	//input wire [7:0] instbyte,
	
	//testing only
	output wire [7:0] o_spidata,
	
	output wire o_sclk,
	output wire o_mosi,
	output wire o_cs_n

    );

//state machine definition
parameter M_IDLE  = 3'h0; 
parameter M_CSN   = 3'h1; //start spi transmission
parameter M_INST  = 3'h2; //instructions
parameter M_ADDR  = 3'h3; //address of target registers
parameter M_RDATA = 3'h4; //read spi data
parameter M_WDATA = 3'h5; //read spi data
parameter M_CSH   = 3'h6; //end of spi transmission


reg r_spi_en, t_spi_en;
//sample i_spi_en
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		r_spi_en <= 1'b0; 
		t_spi_en <= 1'b0;
	end
	else begin
		r_spi_en <= i_spi_en;
		t_spi_en <= r_spi_en;
	end
end

//tesging for one time transaction only
reg oneshot;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) oneshot <= 1'b1;
	else if(ind_mcsh) oneshot <= 1'b0;
end

//SCLK genetator, 10Mhz
reg [3:0] sclk_cnt; 
wire w_sclk;
assign w_sclk = (sclk_cnt < 5) ? 1'b0 : 1'b1; //50 50 duty
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || ind_midle) sclk_cnt <= 4'h0;
	else if (sclk_cnt == 9)  sclk_cnt <= 4'h0;
	else if (~ind_midle && ~ind_mcsn && ~ind_mcsh) sclk_cnt <= sclk_cnt + 1'b1;
end

//CS# delay period, 20ns (state transtition 10ns + delay counter 10 ns ideally)
reg csncnt;
wire csn_peri;
assign csn_peri = (csncnt == 1'b1) ? 1'b1 : 1'b0;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || ind_mcsh) csncnt <= 1'b0;
	else if (ind_mcsn) csncnt <= csncnt + 1'b1;
end

//CS# deasserts delay period, 10ns
reg cshcnt;
wire csh_peri;
assign csh_peri = (cshcnt == 1'b1) ? 1'b1 : 1'b0;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || ind_mcsn) cshcnt <= 1'b0;
	else if (ind_mcsh) cshcnt <= cshcnt + 1'b1;
end

//bitcnt initializes
reg [2:0] bitcnt;
wire sclk_low, sclk_high;
assign sclk_low  = (sclk_cnt == 2) ? 1'b1 : 1'b0;
assign sclk_high = (sclk_cnt == 7) ? 1'b1 : 1'b0;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) bitcnt <= 3'h7;
	else if(sclk_low && bitcnt == 0) bitcnt <= 3'h7;
	else if(sclk_low && dir == 1'b0) bitcnt <= bitcnt - 1'b1;
end

//bitcnt direction to avoid not correct bitcnt patten
reg dir;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) dir <= 1'b0;
	else if(ind_mcsn) dir <= 1'b1;
	else if(sclk_high) dir <= 1'b0;
end

//testing instbyte and r_spidata
reg [7:0] r_instbyte;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) 
	//r_instbyte <= 8'h03; //read instruction 0x03h
	r_instbyte <= 8'h05; //read status register 1, 0x05h
	//r_instbyte <= 8'h35; //read status register 2, 0x35h
	//r_instbyte <= 8'h15; //read status register 3, 0x15h
	//else r_instbyte <= instbyte;
end

//sample i_miso and store to r_spidata
reg [7:0] r_spidata;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) r_spidata <= 8'hF0;
	else if(ind_mrdata && sclk_high) r_spidata[bitcnt] <= i_miso;
end

//state machine indicators
wire ind_midle, ind_mcsn, ind_mcsh, ind_mrdata;
assign ind_midle = (state == M_IDLE) ? 1'b1 : 1'b0;
assign ind_mcsn  = (state == M_CSN)  ? 1'b1 : 1'b0;
assign ind_mcsh  = (state == M_CSH)  ? 1'b1 : 1'b0;
assign ind_mrdata= (state == M_RDATA)? 1'b1 : 1'b0;

//sequential logic for state machine
reg [2:0] state, nt_state;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) state <= M_IDLE;
	else state <= nt_state;
end

//combinational logic for state machine
reg r_cs_n, r_mosi;
always@ (*) begin
//initial values
	r_cs_n = 1'b1;
	r_mosi = 1'b1;
	
	case(state)
	M_IDLE:
	begin
		if(t_spi_en && oneshot) nt_state = M_CSN;
		else nt_state = M_IDLE;
	end
	M_CSN:
	begin
		r_cs_n = 1'b0;
		if(csn_peri) nt_state = M_INST;
		else nt_state = M_CSN;
	end
	M_INST:
	begin
		r_cs_n = 1'b0;
		r_mosi = r_instbyte[bitcnt];
		if(bitcnt == 0 && sclk_low) nt_state = M_RDATA;
		//nt_state = M_ADDR;
		else nt_state = M_INST;
	end
	/*
	M_ADDR:
	begin
		
	end
	*/
	M_RDATA:
	begin
		r_cs_n = 1'b0;
		if(bitcnt == 0 && sclk_high) nt_state = M_CSH;
		//nt_state = M_ADDR;
		else nt_state = M_RDATA;
	end
	/*
	M_WDATA:
	begin
		
	end
	*/
	M_CSH:
	begin
		if(csh_peri) nt_state = M_IDLE;
		else nt_state = M_CSH;
	end
	default: nt_state = M_IDLE;
	endcase
end

assign o_sclk = (ind_midle || ind_mcsn || ind_mcsh) ? 1'b1 : w_sclk;
assign o_cs_n = r_cs_n;
assign o_mosi = r_mosi;
assign o_spidata = r_spidata;


endmodule : spi_master
