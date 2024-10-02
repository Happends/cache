module tb;
	parameter RAM_ADDRESS_BITS = 10;
	parameter CACHE_ADDRESS_BITS = 5;
	parameter DATA_WIDTH = 32;
	parameter ASOC_BITS = 1;
	parameter BLOCK_BITS = 2;


	logic clk;
	logic reset_n;
	logic read_en;
	logic [RAM_ADDRESS_BITS-1:0] address;
	logic [DATA_WIDTH-1:0] write_data;
	logic write_en;

	logic [DATA_WIDTH-1:0] read_data;
	logic valid;
	logic miss;
	logic [RAM_ADDRESS_BITS-1:0] prop_address;
	logic [DATA_WIDTH-1:0] prop_write_data;
	logic prop_write_en;
	
	cache cache(
		.clk(clk),
		.reset_n(reset_n),
		.read_en(read_en),
		.address(address),
		.write_data(write_data),
		.write_en(write_en),
	   
		.read_data(read_data),
		.valid(valid),
		.miss(miss),
		.prop_address(prop_address),
		.prop_write_data(prop_write_data),
		.prop_write_en(prop_write_en)
		);


	always #5 clk = ~clk;


	initial begin
		$dumpfile("waves.vcd");
		$dumpvars(0, top.cache);

		reset_n = 1;

		#10;

		address = 0;
		read_en = 1;

		#10;

		read_en = 0;
		address = 10;
		write_en = 1;
		write_data = 'h55;

		#10;

		write_en = 0;

		#200;
		$finish;
	end


endmodule
