`timescale 1ns / 1ps

module baudrate_gen(
	input wire i_clk, i_rst_n,
	//input wire en_br
	
	output wire o_bd
    );
	
parameter size = 9;
parameter br_th = (10'h363-1); //115200 baudrate

reg [size:0] cnt_bd; 
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n || o_bd) begin
		cnt_bd <= 10'h0;
	end
	else begin
		cnt_bd <= cnt_bd + 10'h1;
	end
end

assign o_bd = (cnt_bd == br_th) ? 1'b1 : 1'b0;
//assign o_bd = (cnt_bd == br_th);

endmodule: baudrate_gen
