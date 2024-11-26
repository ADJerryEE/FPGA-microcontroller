`timescale 1ns / 1ps

module uart_rx(
	input wire i_clk, i_rst_n,
	input wire i_bd, i_rx,
	//input wire rf_en,
	
	//debug only
	//output reg [7:0] o_rx_data
	output reg [7:0] o_rx_data,
	output reg rf_en
	/*
	output wire ind_R_IDLE,
	output wire ind_R_START,
	output wire ind_R_DATA,
	output wire ind_R_STOP,
	output wire ind_R_CLEAN
	*/
    );

//state defi of machines
parameter R_IDLE  = 3'b000;
parameter R_START = 3'b001;
parameter R_DATA  = 3'b010;
parameter R_STOP  = 3'b011;
parameter R_CLEAN = 3'b100;

reg r_rx1, r_rx2;
reg [2:0] nt_state, state;
//reg [7:0] r_data, t_rx_data;
reg [7:0] r_data;
reg [2:0] bitcnt;
reg data_done; 

//state machine indicators, synthesize RTL ROM
wire ind_R_IDLE, ind_R_START,ind_R_DATA, ind_R_STOP, ind_R_CLEAN; 
assign ind_R_IDLE  = (state == R_IDLE)  ? 1'b1 : 1'b0;
assign ind_R_START = (state == R_START) ? 1'b1 : 1'b0;
assign ind_R_DATA  = (state == R_DATA)  ? 1'b1 : 1'b0;
assign ind_R_STOP  = (state == R_STOP)  ? 1'b1 : 1'b0;
assign ind_R_CLEAN = (state == R_CLEAN) ? 1'b1 : 1'b0;

//sample data
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		{r_rx1, r_rx2} <= {1'b0, 1'b0};
	end
	else begin
		r_rx1 <= i_rx;
		r_rx2 <= r_rx1;
	end
end

//sequential cell
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		state <= R_IDLE;
	end
	else begin
		state <= nt_state;
	end
end

//combinational cell
always@ (*) begin
	//initial values to avoid latch
	rf_en = 1'b0;
	
	case(state)
	R_IDLE:
	begin
		nt_state = R_START;
	end
	R_START: //sample start bit
	begin
		if(i_bd) begin
			if(~r_rx2) begin
				nt_state = R_DATA;
			end
			else begin
				nt_state = R_START;
			end
		end 
		else begin
			nt_state = R_START;
		end
	end
	R_DATA:
	begin
		//if(i_bd && data_done) begin
		if(data_done) begin
			nt_state = R_STOP;
		end
		else begin
			nt_state = R_DATA;
		end
	end
	R_STOP:
	begin
		//rf_en = 1'b1;
		if(i_bd) begin
			if(r_rx2) begin
				nt_state = R_CLEAN;
			end
			else begin
				nt_state = R_STOP;
			end
		end
		else begin
			nt_state = R_STOP;
		end
	end
	R_CLEAN:
	begin
		rf_en    = 1'b1;
		nt_state = R_IDLE;
	end
	default: nt_state = R_IDLE;
	endcase
end

//store data and avoid latch
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		//t_rx_data <= 8'h0;
		o_rx_data <= 8'h0;
	end
	else if(rf_en) begin
		//t_rx_data <= r_data;
		o_rx_data <= r_data;
		//o_rx_data <= t_rx_data;
	end
end

//receive and store data
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin
		bitcnt <= 3'h0;
		r_data <= 8'h0;
		data_done <= 1'b0;
	end
	//else if(i_bd && ind_R_DATA) begin
	else if(i_bd && ind_R_DATA) begin
			if(bitcnt < 7) begin
				r_data [bitcnt] <= r_rx2;
				bitcnt <= bitcnt + 1'b1;
			end
			else begin
				r_data [bitcnt] <= r_rx2;
				bitcnt <= 3'h0;
				data_done <= 1'b1;
			end
	end
	else begin 
		data_done <= 1'b0;
	end
end
	/*
	else begin

	end
	*/
	
endmodule: uart_rx
