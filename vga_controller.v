`timescale 1ns / 1ps

//for 640x480 resolution with 60hz refresh rate
module vga_controller(
	input wire i_clk,
	input wire i_rst_n,
	
	output wire video_on,
	output wire [3:0] o_vga_red,
	output wire [3:0] o_vga_green,
	output wire [3:0] o_vga_blue,
	output wire vga_hsync,
	output wire vga_vsync
	
    );

//paramters for VGA screen
parameter HD = 640; //horizontal display area width in pixels unit
parameter HF = 16;  //horizontal front porch width in pixels unit
parameter HB = 48;  //horizontal back porch width in pixels unit
parameter HR = 96;  //horizontal retrace width in pixels unit
parameter VD = 480; //vertical display area width in pixels unit
parameter VF = 10;  //vertical front porch width in pixels unit
parameter VB = 29;  //vertical back porch width in pixels unit
parameter VR = 2;   //vertical retrace width in pixels unit
parameter HMAX = (HD+HF+HB+HR-1); //horizontal threshold, 799
parameter VMAX = (VD+VF+VB+VR-1); //horizontal threshold, 521

/*
horizontal width = 640, vertical width = 480
/////////////////////////////////////////////////////////////////////////
/																		/
/																		/
/						VGA screen										/
/																		/
/																		/
/////////////////////////////////////////////////////////////////////////
*/

//pixel clk, 25Mhz
reg [1:0] pixel_cnt;
reg r_pxiel;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) begin 
		pixel_cnt <= 2'h0;
		r_pxiel   <= 1'b0;
	end
	else if(pixel_cnt == 2'h3) begin 
		pixel_cnt <= 2'h0;
		r_pxiel   <= 1'b1;
	end
	else begin
		pixel_cnt <= pixel_cnt + 2'h1;
		r_pxiel   <= 1'b0;
	end
end

//initialize r, b and g.
//testing only
reg [3:0] r_vga_red, r_vga_green, r_vga_blue;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) {r_vga_red, r_vga_green, r_vga_blue} <= {4'h0, 4'h0, 4'h0};
	else {r_vga_red, r_vga_green, r_vga_blue} <= {4'h0, 4'h0, 4'hF};
end

/*	
//horizontal counter
reg [9:0] r_hcnt;
always@ (posedge r_pxiel or negedge i_rst_n) begin
	if(~i_rst_n) r_hcnt <= 10'h0;
	else if(r_hcnt == HMAX) r_hcnt <= 10'h0; //count to the end of row
	else r_hcnt <= r_hcnt + 10'h1;
end
*/ 

//horizontal counter, another coding style of clock constraint
reg [9:0] r_hcnt;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) r_hcnt <= 10'h0;
	else if (r_pxiel)
		 if (r_hcnt == HMAX) r_hcnt <= 10'h0;
		 else r_hcnt <= r_hcnt + 10'h1;
end
/*
//vertical counter
reg [9:0] r_vcnt;
always@ (posedge r_pxiel or negedge i_rst_n) begin
	if(~i_rst_n) r_vcnt <= 10'h0;
	else if(r_hcnt == HMAX)
		if(r_vcnt == VMAX) r_vcnt <= 10'h0;
		else r_vcnt <= r_vcnt + 10'h1; 
	//else do nothing. it means when (r_hcnt < HMAX), r_vcnt keeps current status
end
*/

//vertical counter, another coding style of clock constraint
reg [9:0] r_vcnt;
always@ (posedge i_clk or negedge i_rst_n) begin
	if(~i_rst_n) r_vcnt <= 10'h0;
	else if(r_pxiel)
		if(r_hcnt == HMAX)
			if(r_vcnt == VMAX) r_vcnt <= 10'h0;
			else r_vcnt <= r_vcnt + 10'h1; 
		//else do nothing. it means when (r_hcnt < HMAX), r_vcnt keeps current status
	//else do nothing. it means when (r_pxiel != 1'b1)
end

//w_h_sync asserted within the horizontal retrace area
wire w_h_sync;
assign w_h_sync = (r_hcnt > (HR-1)) ? 1'b1 : 1'b0;

//w_v_sync asserted within the vertical retrace area
wire w_v_sync;	
assign w_v_sync = (r_vcnt > (VR-1)) ? 1'b1 : 1'b0;

//video_on signal to determine when vga data will be sent to monitor from fpga
wire w_video_on_h, w_video_on_v;
assign w_video_on_h = (r_hcnt > (HB+HR-1)) & (r_hcnt < (HMAX-HF-1)) ? 1'b1 : 1'b0;
assign w_video_on_v = (r_vcnt > (VB+VR-1)) & (r_vcnt < (VMAX-VR-1)) ? 1'b1 : 1'b0;
assign video_on = w_video_on_h & w_video_on_v;

//output ports
assign vga_hsync = w_h_sync;
assign vga_vsync = w_v_sync;
assign o_vga_red   = (video_on) ? r_vga_red   : 4'h0;
assign o_vga_blue  = (video_on) ? r_vga_blue  : 4'h0;
assign o_vga_green = (video_on) ? r_vga_green : 4'h0;

endmodule : vga_controller
