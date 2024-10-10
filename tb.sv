module tb;
	parameter RAM_ADDRESS_BITS = 32;
	parameter CACHE_ADDRESS_BITS = 8;
	parameter DATA_BITS = 32;
	parameter ASOC_BITS = 2;
	parameter BLOCK_BITS = 2;


	logic clk = 1;
	logic reset_n;
	logic [RAM_ADDRESS_BITS-1:0] address;
	logic read_en;
	logic [DATA_BITS-1:0] write_data;
	logic write_en;
	logic ram_valid;
	logic [DATA_BITS-1:0] ram_data [BLOCK_BITS**2-1:0];

	logic [DATA_BITS-1:0] read_data;
	logic valid;
	logic miss;
	logic [RAM_ADDRESS_BITS-1:0] prop_address;
	logic prop_read_en;
	logic [DATA_BITS-1:0] prop_write_data;
	logic prop_write_en;
	
	logic found;

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


	task init();
		$dumpfile("waves.vcd");
		$dumpvars(0, top.cache);

		reset_n = 1;
		read_en = 0;
		write_en = 0;

		#10;

	endtask

	task zero_inputs();

		read_en = 0;
		write_en = 0;
		address = 0;
		ram_valid = 0;
		ram_data = '{default: '0};
		write_data = '0;

	endtask

	task stop_cache_from_reading_0();

		read_en = 1;
		address = 0;

		#10;

		read_en = 0;
		write_en = 1;
		write_data = 'haaaa;

		assert(cache.stop_cache == 1);

		#10;

		address = 'h10000;
		write_en = 1;
		write_data = 'haaaa;
		
		ram_valid = 1;
		ram_data = '{default: 'h2};

		assert(cache.stop_cache == 1);
		
		#10;
		
		foreach(cache.cache[0].block[i]) begin
			assert(cache.cache[0].block[i].control_bits.valid == 0);
			assert(cache.cache[0].block[i].control_bits.dirty == 0);
			assert(cache.cache[0].block[i].control_bits.lsr_number == 0);
			assert(cache.cache[0].block[i].tag == '0);
		end

		ram_valid = 0;
		ram_data = '{default: '0};

		#10;

		assert(cache.stop_cache == 0);
		assert(cache.cache[0].block[0].control_bits.valid == 1);
		assert(cache.cache[0].block[0].control_bits.dirty == 0);
		assert(cache.cache[0].block[0].control_bits.lsr_number == '1);
		assert(cache.cache[0].block[0].tag == '0);
		
		// $display("stop_cache: %d", cache.stop_cache);
		// $display("valid: %d", cache.cache[0].block[0].control_bits.valid);
		// $display("dirty: %d", cache.cache[0].block[0].control_bits.dirty);
		// $display("lsr_number: %d", cache.cache[0].block[0].control_bits.lsr_number);
		// $display("tag: %d", cache.cache[0].block[0].tag);

		assert(read_data == '0);
			else $error("read_data not 0");
		assert(prop_read_en == 1);
			else $error("prop_read_en is not 1");
		assert(prop_address == 'h10000);
			else $error("prop_address is not as should be");

		#10;

	endtask


	task check_readout( logic [DATA_BITS-1:0] data);
		assert(valid == 1);
		assert(read_data == data);
	endtask



	task check_cache_controls(input logic write, logic [RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS+ASOC_BITS-1:0] tag1, logic [DATA_BITS-1:0] data1, logic test1, logic [RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS+ASOC_BITS-1:0] tag2, logic [DATA_BITS-1:0] data2, logic test2, logic [RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS+ASOC_BITS-1:0] tag3, logic [DATA_BITS-1:0] data3, logic test3, logic [RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS+ASOC_BITS-1:0] tag4, logic [DATA_BITS-1:0] data4, logic test4);

		found = 0;
		if (test1 == 1) begin
			foreach(cache.cache[0].block[i]) begin
				if (cache.cache[0].block[i].tag == tag1) begin
					assert(found == 0);
					found = 1;
					assert(cache.cache[0].block[i].control_bits.valid == 1);
					assert(cache.cache[0].block[i].control_bits.dirty == write);
					assert(cache.cache[0].block[i].control_bits.lsr_number == 'b11);
					assert(cache.cache[0].block[i].data[0] == data1);
				end
			end
			assert(found);
		end

		if (test2 == 1) begin
			found = 0;
			foreach(cache.cache[0].block[i]) begin
				if (cache.cache[0].block[i].tag == tag2) begin
					assert(found == 0);
					found = 1;
					assert(cache.cache[0].block[i].control_bits.valid == 1);
					assert(cache.cache[0].block[i].control_bits.dirty == write);
					assert(cache.cache[0].block[i].control_bits.lsr_number == 'b10);
					assert(cache.cache[0].block[i].data[0] == data2);
				end
			end
			assert(found);
		end

		if (test3 == 1) begin
			found = 0;
			foreach(cache.cache[0].block[i]) begin
				if (cache.cache[0].block[i].tag == tag3) begin
					assert(found == 0);
					found = 1;
					assert(cache.cache[0].block[i].control_bits.valid == 1);
					assert(cache.cache[0].block[i].control_bits.dirty == write);
					assert(cache.cache[0].block[i].control_bits.lsr_number == 'b01);
					assert(cache.cache[0].block[i].data[0] == data3);
				end
			end
			assert(found);
		end

		if (test4 == 1) begin
			found = 0;
			foreach(cache.cache[0].block[i]) begin
				if (cache.cache[0].block[i].tag == tag4) begin
					assert(found == 0);
					found = 1;
					assert(cache.cache[0].block[i].control_bits.valid == 1);
					assert(cache.cache[0].block[i].control_bits.dirty == write);
					assert(cache.cache[0].block[i].control_bits.lsr_number == 'b00);
					assert(cache.cache[0].block[i].data[0] == data4);
				end
			end
			assert(found);
		end

	endtask	


	task test_write();
		// test assumes ASOC_BITS = 2
		// test for writing to the same index in set
		write_en = 1;
		address = 'h10000;
		write_data = 'h10;

		#10;
		
		address = 'h10000;
		write_data = 'h20;

		#10;
		
		check_cache_controls(	1,	
					'h400, 'h10, 1,  
					'0, '0, 0, 
					'0, '0, 0, 
					'0, '0, 0);	


		// test for writing to two indexes
		address = 'h20000;
		write_data = 'h10;

		#10;

		check_cache_controls(	1,
					'h400, 'h20, 1, 
					'0, '0, 0, 
					'0, '0, 0, 
					'0, '0, 0);	

		
		address = 'h10000;
		write_data = 'h30;


		#10;
		
		check_cache_controls(	1,
					'h800, 'h10, 1,
					'h400, 'h20, 1, 
					'0, '0, 0, 
					'0, '0, 0);	


		address = 'h20000;
		write_data = 'h20;

		#10;

		check_cache_controls(	1,
					'h400, 'h30, 1,
					'h800, 'h10, 1, 
					'0, '0, 0, 
					'0, '0, 0);	
		
		
		address = 'h10000;
		write_data = 'h40;

		#10;

		check_cache_controls(	1,
					'h800, 'h20, 1,
					'h400, 'h30, 1, 
					'0, '0, 0, 
					'0, '0, 0);	


		// test for writing to three indexes

		address = 'h30000;
		write_data = 'h10;

		#10;

		check_cache_controls( 	1,
					'h400, 'h40, 1,
					'h800, 'h20, 1,
					'0, '0, 0,
					'0, '0, 0);

		address = 'h30000;
		write_data = 'h20;

		#10;

		check_cache_controls(	1,
					'hc00, 'h10, 1,
					'h400, 'h40, 1, 
					'h800, 'h20, 1, 
					'0, '0, 0);
		address = 'h20000;
		write_data = 'h30;
		
		#10;
		
		check_cache_controls(	1,
					'hc00, 'h20, 1,
					'h400, 'h40, 1, 
					'h800, 'h20, 1, 
					'0, '0, 0);

		address = 'h10000;
		write_data = 'h50;

		#10;

		check_cache_controls(	1,
					'h800, 'h30,  1,
					'hc00, 'h20, 1,
					'h400, 'h40,  1,
					'0, '0, 0);

		address = 'h30000;
		write_data = 'h30;

		// test for writing to 4 indexes
		#10;

		check_cache_controls(	1,
					'h400, 'h50,  1, 
					'h800, 'h30,  1, 
					'hc00, 'h20, 1,
					'0, '0, 0);

		address = 'h40000;
		write_data = 'h10;
		
		#10;

		check_cache_controls(	1,
					'hc00, 'h30, 1,
					'h400, 'h50, 1, 
					'h800, 'h30, 1, 
					'0, '0, 0);

		address = 'h30000;
		write_data = 'h40;

		#10;

		check_cache_controls(	1,
					'h1000, 'h10,  1,
					'hc00, 'h30,  1,
					'h400, 'h50,  1, 
					'h800, 'h30, 1); 

		address = 'h20000;
		write_data = 'h40;
		
		#10;
	
		check_cache_controls(	1,
					'hc00, 'h40,  1,
					'h1000, 'h10,  1,
					'h400, 'h50,  1, 
					'h800, 'h30, 1); 

	
		address = 'h10000;
		write_data = 'h60;

		#10;
	
		check_cache_controls(	1,
					'h800, 'h40, 1,
					'hc00, 'h40,  1,
					'h1000, 'h10,  1,
					'h400, 'h50,  1); 


		address = 'h30000;
		write_data = 'h50;

		#10;
	
		check_cache_controls(	1,
					'h400, 'h60,  1,
					'h800, 'h40, 1,
					'hc00, 'h40,  1,
					'h1000, 'h10,  1); 

		#10;
	
		check_cache_controls(	1,
					'hc00, 'h50,  1,
					'h400, 'h60,  1,
					'h800, 'h40, 1,
					'h1000, 'h10,  1); 



	endtask

	logic [RAM_ADDRESS_BITS-1:0] addresses [20-1:0];
	logic [DATA_BITS-1:0] datas [20-1:0];

	logic [RAM_ADDRESS_BITS-1:0] check_addresses [19-1:0];
	logic [DATA_BITS-1:0] check_datas [19-1:0];

	task test_read();
		
		write_en = 1;
		address = 'hffffffff; 
		write_data = 'h10;


		#10;

		write_en = 0;
		read_en = 1;
		address = 'hffffffff;

		#10;

		write_en = 1;
		read_en = 0;
		address = 'haaaaaaaa; 
		write_data = 'h20;

		check_readout( 'h10);


		#10;

		write_en = 0;
		read_en = 1;
		address = 'haaaaaaaa; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h12345633; 
		write_data = 'h30;


		check_readout( 'h20);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h12345633; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h87657485; 
		write_data = 'h40;


		check_readout( 'h30);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h87657485; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h98765432; 
		write_data = 'h50;


		check_readout( 'h40);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h98765432; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h90128301; 
		write_data = 'h60;


		check_readout( 'h50);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h90128301; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h094509; 
		write_data = 'h70;


		check_readout( 'h60);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h094509; 

		#10;

		write_en = 1;
		read_en = 0;
		address = 'h1234959; 
		write_data = 'h80;


		check_readout( 'h70);

		#10;

		write_en = 0;
		read_en = 1;
		address = 'h1234959; 

		#10;

		read_en = 0;

		check_readout( 'h80);

		#10;
		


		// many writes into reads
		
		addresses = {	'h12345678, 'h12345678, 
				'h12345679,
				'h12345680,
				'h12345681,
				'h12345682,
				'h12345683,
				'h12345684,
				'h12345685,
				'h12345686,
				'h12345687,
				'h12345688,
				'h12345689,
				'h1234568a,
				'h1234568b,
				'h1234568c,
				'h1234568d,
				'h1234568e,
				'h1234568f,
				'h12345690};
		datas = {	'hac, 'hffffffff,
				'had,
				'hae,
				'haf,
				'hb0,
				'hffff0000,
				'h0f0f0f0f,
				'hf0f0f0f0,
				'hacacacac,
				'h54545454,
				'h88446722,
				'hf0000000,
				'h80000000,
				'h10000000,
				'h11111111,
				'h00000000,
				'h33992188,
				'h88112233,
				'hdc12398c};
		check_addresses = {	'h12345678, 
					'h12345679,
					'h12345680,
					'h12345681,
					'h12345682,
					'h12345683,
					'h12345684,
					'h12345685,
					'h12345686,
					'h12345687,
					'h12345688,
					'h12345689,
					'h1234568a,
					'h1234568b,
					'h1234568c,
					'h1234568d,
					'h1234568e,
					'h1234568f,
					'h12345690};
		check_datas = {	'hffffffff,
				'had,
				'hae,
				'haf,
				'hb0,
				'hffff0000,
				'h0f0f0f0f,
				'hf0f0f0f0,
				'hacacacac,
				'h54545454,
				'h88446722,
				'hf0000000,
				'h80000000,
				'h10000000,
				'h11111111,
				'h00000000,
				'h33992188,
				'h88112233,
				'hdc12398c};

		write_en = 1;
		foreach (addresses[i]) begin
			address = addresses[i];
			write_data = datas[i];
			
			#10;
		end

		write_en = 0;
		read_en = 1;

		foreach (check_addresses[i]) begin
			address = check_addresses[i];

			#10;

			check_readout( check_datas[i]);
		end

		// check replacing one entry

		write_en = 0;
		read_en = 1;
		address = 'h12345678;









	endtask


	initial begin
		init();
		zero_inputs();
		#10;

		stop_cache_from_reading_0();
		zero_inputs();
		#10;

		test_write();
		zero_inputs();
		#10;

		test_read();
		zero_inputs();
		#10;

		$finish;
	end


endmodule
