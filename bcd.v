`timescale 1ns / 1ps

module bcd(
	input wire [7:0] i_data,
	input wire i_rst_n,
	
	output wire [3:0] o_sel_bcd,
	output reg  [7:0] o_display 
    );
    
//to enable 4-digit BCD LED segment	
assign o_sel_bcd = 4'b0111 ;

//BCD decoder
always@ (*) begin
	/*if (i_rst_n == 1'b0) 
	begin 
		o_display = 8'b00000011;
	end
	else begin
	*/
	case(i_data)
	/*
	8'h30: o_display = 8'b00000011;	//0
	8'h31: o_display = 8'b10011111;	//1
	8'h32: o_display = 8'b00100101;	//2
	8'h33: o_display = 8'b00001101;	//3
	8'h34: o_display = 8'b10011001;	//4
	8'h35: o_display = 8'b01001001;	//5
	8'h36: o_display = 8'b11000001;	//6
	8'h37: o_display = 8'b00011111;	//7
	8'h38: o_display = 8'b00000001;	//8
	8'h39: o_display = 8'b00001001;	//9
	//default: o_display = 8'b00000011 ; //aviod to stnthesize latch.
	default: o_display = 8'b00001001 ; //aviod to stnthesize latch.
	*/
	8'h0: o_display = 8'b00000011;	//0
	8'h1: o_display = 8'b10011111;	//1
	8'h2: o_display = 8'b00100101;	//2
	8'h3: o_display = 8'b00001101;	//3
	8'h4: o_display = 8'b10011001;	//4
	8'h5: o_display = 8'b01001001;	//5
	8'h6: o_display = 8'b11000001;	//6
	8'h7: o_display = 8'b00011111;	//7
	8'h8: o_display = 8'b00000001;	//8
	8'h9: o_display = 8'b00001001;	//9
	//default: o_display = 8'b00000011 ; //aviod to stnthesize latch.
	default: o_display = 8'b00001001 ; //aviod to stnthesize latch.
	
	endcase
	end	  
endmodule:bcd
