`timescale 1ns / 1ps

//Top controller
module top_controller(
	input wire i_clk, i_rst_n,
	//input wire [7:0] i_data,
	input wire i_rx,
	
	output wire o_tx,
	//output wire [7:0] o_rx_data,
	//debugging only on silumlation

	output wire [3:0] o_sel_bcd,
	output wire [7:0] o_display,
	
	//input wire  i_bt, 
	//output wire o_bt 
	//i2c io
	input wire i_i2c_en,
	input wire rw_req,
	inout wire io_sda, io_scl,
	
	//spi io
	input wire i_spi_en, //external enable spi signal
	input wire i_miso,
	
	output wire o_sclk,
	output wire o_mosi,
	output wire o_cs_n,
	
	//vga io
	output wire [3:0] o_vga_red,
	output wire [3:0] o_vga_green,
	output wire [3:0] o_vga_blue,
	output wire vga_hsync,
	output wire vga_vsync
	
    );
	
//internal wires
wire w_bd, w_rx, w_txen;
wire [7:0] w_data, w_i2c_data, w_spidata;
//wire [3:0] w_vga_red, w_vga_green, w_vga_blue;


////////////debug only
//assign o_bd = w_bd;
//wire duty;
//sub modules 
//design module name call sign name
baudrate_gen baudrate_gen(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.o_bd(w_bd)
);

uart_rx uart_rx(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_bd(w_bd), 
	.i_rx(i_rx),
	.o_rx_data(w_data),
	.rf_en(w_txen)
);

uart_tx uart_tx(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_bd(w_bd), 
	//.tx_en(w_txen),
	.tx_en(i_i2c_en),
	.o_tx(o_tx),
	//.i_tx_data(w_data)
	.i_tx_data(w_i2c_data)
	//.i_tx_data(w_spidata)
);

i2c_master i2c_master(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	
	.i_i2c_en(i_i2c_en),
	.rw_req(rw_req), 
	
	.o_i2c_data(w_i2c_data), //testing only
	
	.io_scl(io_scl), 
	.io_sda(io_sda)
);

 spi_master spi_master(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_spi_en(i_spi_en),
	
	//testing only
	.o_spidata(w_spidata),
	
	.i_miso(i_miso),
	.o_sclk(o_sclk),
	.o_mosi(o_mosi),
	.o_cs_n(o_cs_n)
 );

vga_controller vga_controller(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	
	.video_on(),
	.o_vga_red(o_vga_red),
	.o_vga_green(o_vga_green),
	.o_vga_blue(o_vga_blue),
	.vga_hsync(vga_hsync),
	.vga_vsync(vga_vsync)
    );


bcd bcd(
	//.i_data(w_data),
	//.i_data(w_i2c_data),
	.i_data(w_spidata),
	
	.i_rst_n(i_rst_n),
	.o_sel_bcd(o_sel_bcd),
	.o_display(o_display) 
    );
	

	
/*
 debounce debounce(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_bt(i_bt), 
	.o_bt(o_bt),
	.duty(duty)
 );
  */
  

endmodule: top_controller
