module tb;
	parameter RAM_ADDRESS_BITS = 32;
	parameter CACHE_ADDRESS_BITS = 5;
	parameter DATA_BITS = 32;
	parameter ASOC_BITS = 1;
	parameter BLOCK_BITS = 2;


	logic clk;
	logic reset_n;
	logic [RAM_ADDRESS_BITS-1:0] address;
	logic read_en;
	logic [DATA_BITS-1:0] write_data;
	logic write_en;
	logic ram_valid;
	logic [DATA_BITS-1:0] ram_data [BLOCK_BITS-1:0];

	logic [DATA_BITS-1:0] read_data;
	logic valid;
	logic miss;
	logic [RAM_ADDRESS_BITS-1:0] prop_address;
	logic prop_read_en;
	logic [DATA_BITS-1:0] prop_write_data;
	logic prop_write_en;
	
	cache #(.RAM_ADDRESS_BITS(RAM_ADDRESS_BITS),
		.CACHE_ADDRESS_BITS(CACHE_ADDRESS_BITS),
		.DATA_BITS(DATA_BITS),
		.ASOC_BITS(ASOC_BITS),
		.BLOCK_BITS(BLOCK_BITS)
		) cache (

		.clk(clk),
		.reset_n(reset_n),
		.address(address),
		.read_en(read_en),
		.write_data(write_data),
		.write_en(write_en),
		.ram_valid(ram_valid),
		.ram_data(ram_data),
	   
		.read_data(read_data),
		.valid(valid),
		.miss(miss),
		.prop_address(prop_address),
		.prop_read_en(prop_read_en),
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

		#10;

		address = 10;
		write_en = 1;
		write_data = 'h55;

		#10;

		write_en = 0;
		read_en = 1;
		

		#10;

		read_en = 0;
		address = 'h5001;
		write_data = 'hFAFA;
		write_en = 1;

		#10;

		write_en = 0;
		read_en = 1;
		address = 10;

		#10

		read_en = 1;
		address = 'h5001;

		#10

		read_en = 1;
		address = 10;

		#10;

		read_en = 1;
		address = 11;

		#10;

		read_en = 1;
		address = 20;

		#10;

		read_en = 0;
		#50;

		$finish;
	end


endmodule
