`timescale 1ns / 1ps

//Testbench for top controller
module tb_top_controller();

//stimulus signals
reg i_clk, i_rst_n;
reg i_rx;
reg i_bt;
reg i_i2c_en;
reg rw_req;
reg en_iosda;
reg i_miso;

//wire toggle_temp;

wire w_clk, w_rst_n;
//probed(output) signals
wire o_bd;
wire o_tx;
wire [3:0] o_sel_bcd;
wire [7:0] o_display;
wire [7:0] o_rx_data;
wire o_bt;

reg  i_spi_en;
wire o_sclk, o_mosi, o_cs_n;


wire io_scl, io_sda;
assign io_sda = (en_iosda) ? 1'b0 : 1'bz; //for ack
//assign io_sda = (en_iosda) ? 1'b1 : 1'bz; //for nack

//////////////////////////////////////////////////////////////////////////////// Stimulus Signals Patterns /////////////////////////////////////////////////////////////////////////////////////////////
//generate clk signal
initial begin
	clk_ctrl(10);
	//10  refers to 10ns for a single period, f=100Mhz
	//50  refers to 50ns, 20Mhz
	//100 refers to 100ns, 1Mhz
	//unit 1ns
end
//generate reset signal
initial begin
	i_rst_n	= 1'bx;
	#33;
	reset_task(100); //reset 100ns;
end

//simulate debounce
/*
initial begin
	i_bt = 1'bx;
	#33;
	#120;
	
	i_bt = 1'b0;
	#5;
	i_bt = 1'b1;
	#5;
	i_bt = 1'b0;
	#5;
	i_bt = 1'b1;
	#5;
	i_bt = 1'b0;
	#5;
	i_bt = 1'b1;
	#10;
	i_bt = 1'b0;
	#10;
	i_bt = 1'b1;
	#5;
	i_bt = 1'b0;
	#5;
	i_bt = 1'b1;
end
*/

//generate input patterns
/*
initial begin
	#95;
	i_rx = 1'b1;
	#5000;
	i_rx = 1'b0;
	#4000;
	i_rx = 1'b1; 
	# 36000
	i_rx = 1'b0;
end
*/

initial begin 
	i_rx = 1'bx;
	#10;
	i_rx = 1'b1;
	#200;
	
	//when rising edge of o_bd comes and delays 2ns, i_rx starts transition
	@(posedge o_bd) #20;
	i_rx = 1'b0;
	@(posedge o_bd) #20;
	i_rx = 1'b1;
	@(posedge o_bd) #20;
	i_rx = 1'b0;
	@(posedge o_bd) #20;
	i_rx = 1'b1;
	@(posedge o_bd) #20;
	i_rx = 1'b0;
	@(posedge o_bd) #20;
	i_rx = 1'b1;
	@(posedge o_bd) #20;
	i_rx = 1'b0;
	@(posedge o_bd) #20;
	i_rx = 1'b1;
	//$stop;
	
	print.sim_complete;
	//$stop;
end

//i2c master script
initial begin
	i_i2c_en = 1'bx;
	#30;
	i_i2c_en = 1'b0;
	#30;
	i_i2c_en = 1'b1;
	//testbench only i_i2c_en
	#137460;
	i_i2c_en = 1'b0;
end

//i2c rw request
initial begin
	rw_req = 1'bx; 
	#153;
	//rw_req = 1'b0; 
	rw_req = 1'b1; 
end

//i2c ack and nack testing
initial begin
	en_iosda = 1'b0; 
	#42430;
	en_iosda = 1'b1;
	#5000;
	en_iosda = 1'b0;
	#40000;
	en_iosda = 1'b1;
	#5000; 
	en_iosda = 1'b0;
	#40000;
	en_iosda = 1'b1;
	#5000; 
	en_iosda = 1'b0;
end

//spi master script
initial begin
	i_spi_en = 1'bx;
	#30;
	i_spi_en = 1'b0;
	#30;
	#100;
	i_spi_en = 1'b1;
	#200;
	//#5000;
	i_spi_en = 1'b0;
	#1600;
	i_spi_en = 1'b1;
	#200;
	i_spi_en = 1'b0;
	
end

//spi master i_mosi script, spidata = 0xaah
initial begin
	i_miso = 1'bz;
	#1000;
	#30;
	i_miso = 1'b1;
	#100;
	i_miso = 1'b0;
	#100;
	i_miso = 1'b1;
	#100;
	i_miso = 1'b0;
	#100;
	i_miso = 1'b1;
	#100;
	i_miso = 1'b0;
	#100;
	i_miso = 1'b1;
	#100;
	i_miso = 1'b0;
	#100;
	i_miso = 1'bz;
end

//scan system status
always@(*) begin : warning
	print.warning("Warning", i_rst_n);
end


//////////////////////////////////////////////////////////////////////////////// Devices Under Test /////////////////////////////////////////////////////////////////////////////////////////////////////
top_controller DUT(
	.i_clk(i_clk), 
	.i_rst_n(i_rst_n),
	//.o_bd(o_bd),
	.i_rx(i_rx),
	.o_tx(o_tx),
	//.o_rx_data(o_rx_data)
	.o_sel_bcd(o_sel_bcd),
	.o_display(o_display),
	
	//.i_bt(i_bt),
	//.o_bt(o_bt)
	
	
	//i2c master testing
	.i_i2c_en(i_i2c_en),
	.rw_req(rw_req), 
	.io_scl(io_scl),
	.io_sda(io_sda),
	
	//spi master testing
	.i_spi_en(i_spi_en), //external enable spi signal
	.i_miso(i_miso),
	
	.o_sclk(o_sclk),
	.o_mosi(o_mosi),
	.o_cs_n(o_cs_n)
	
	
	
);

//////////////////////////////////////////////////////////////////////////////// Clk and Task Group //////////////////////////////////////////////////////////////////////////////////////////////////////
//system clock task
task clk_ctrl;
	//parameter PERIOD = 10; //10ns fpr one clock period
	input wire [15:0] i_clk_period;
	begin
		i_clk = 1'b0; 
		#20;
		forever begin
			i_clk = ~i_clk; #(i_clk_period/2);
		end
	end
endtask

//system reset task
task reset_task;
	input [15:0] reset_time;
	begin
		i_rst_n = 1'b0;
		# reset_time;
		
		i_rst_n = 1'b1;
	end
endtask

//////////////////////////////////////////////////////////////////////////////// Common Task Group //////////////////////////////////////////////////////////////////////////////////////////////////////
//Only System Verilog complier can support nested module
//print module
module print_task();
	task warning;
		input wire [30*8:1] msg_warn;
		input wire en;
		begin
			if(~en)
			begin
				$write("The time value is at %t ns\n", $time);
				$write("The value is at %s\n",msg_warn);
				//$write("The the value is !!! at %t",$time);
			end
		end
	endtask
	
	task error;
		input wire [80*8:1] msg_error;
		begin
			$display("Please show error\n");
			$display("Please show %s\n", msg_error);
		end
	endtask
	
	task sim_complete;
		begin
			$display("The simulation is complete !\n");
		end
	endtask
	
	task state_machice_status;
		input wire [80*8:1] msg_sms; //sms refers to state machine status
		begin
			$display("The current state machine is %s\n", msg_sms);
		end
	endtask
endmodule : print_task




//////////////////////////////////////////////////////////////////////////////// Call Module for tasks ///////////////////////////////////////////////////////////////////////////////////////////////////
print_task print();




endmodule : tb_top_controller
