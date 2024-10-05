

module cache 
    #(  parameter RAM_ADDRESS_BITS = 10,    // change to size
        parameter CACHE_ADDRESS_BITS = 5,   // change to size
        parameter DATA_BITS=32,
        parameter ASOC_BITS=1,
        parameter BLOCK_BITS=2)

    (   input   clk,
        input   reset_n,
        input   [RAM_ADDRESS_BITS-1:0] address, 
        input   read_en,
        input	[DATA_BITS-1:0] write_data, 
        input	write_en,
	input	ram_valid,
	input	[DATA_BITS-1:0] ram_data [BLOCK_BITS-1:0],

	output  [DATA_BITS-1:0] read_data,
        output  valid,
	output  miss,
        output  [RAM_ADDRESS_BITS-1:0] prop_address, 
	output	prop_read_en,
        output	[DATA_BITS-1:0] prop_write_data, 
        output  prop_write_en);

	parameter TAG_BITS = RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS+ASOC_BITS;
	parameter INDEX_BITS = CACHE_ADDRESS_BITS-ASOC_BITS-BLOCK_BITS;



   	// typedef for getting cache_address parts 
    	typedef struct packed {
        	logic [TAG_BITS-1:0] tag;
        	logic [INDEX_BITS-1:0] index;
        	logic [BLOCK_BITS-1:0] offset;
    	} cache_address_t;


	parameter BLOCK_SIZE = 2**BLOCK_BITS;
	parameter ASOC_SIZE = 2**ASOC_BITS;


	// typedef for cache entries
	typedef struct packed {
		logic valid;
		logic dirty;
		logic [ASOC_BITS-1:0] lsr_number;
	} cache_entry_control_bits_t;

    	typedef struct {
		cache_entry_control_bits_t control_bits;
        	logic [TAG_BITS-1:0] tag;
       		logic [DATA_BITS-1:0] data [BLOCK_SIZE-1:0];     // might have to be packed to match input from RAM
    	} cache_entry_t;

	typedef struct {
		cache_entry_t block [ASOC_SIZE-1:0];
	} cache_set_t;

	logic [DATA_BITS-1:0] read_data_logic;
        logic valid_logic;
	logic miss_logic;
       	logic [RAM_ADDRESS_BITS-1:0] prop_address_logic;
	logic prop_read_en_logic;
        logic [DATA_BITS-1:0] prop_write_data_logic;
        logic prop_write_en_logic;


    	logic [RAM_ADDRESS_BITS-1:0] address_reg;
       	logic read_en_reg;
       	logic [DATA_BITS-1:0] write_data_reg;
        logic write_en_reg;
    
	cache_address_t cache_address;
	assign cache_address = address_reg;

	parameter INDEX_SIZE = 2**INDEX_BITS;
	cache_set_t memory [INDEX_SIZE-1:0];

	assign read_data = read_data_logic;
	assign valid = valid_logic;
	assign miss = miss_logic;
	assign prop_address = prop_address_logic;
	assign prop_read_en = prop_read_en_logic;
	assign prop_write_en = prop_write_en_logic;

	initial begin

		$display("TAG_BITS: %d", TAG_BITS);
		$display("INDEX_BITS: %d", INDEX_BITS);
		$display("ASOC_SIZE: %d", ASOC_SIZE);
		$display("BLOCK_SIZE: %d", BLOCK_SIZE);

		if (RAM_ADDRESS_BITS < CACHE_ADDRESS_BITS) begin
			$error("ERROR: cache settings wrong");
		end 
        	if ((ASOC_BITS+BLOCK_BITS) > CACHE_ADDRESS_BITS) begin 
			$error("ERROR: cache settings wrong");
        	end
        	$display("cache settings ok");
		memory = '{default: '{block: '{default: '{control_bits: '{valid: 0, dirty: 0, lsr_number: '0}, tag: '0, data: '{default: '1}}}}}; // valid temporary
    	end


	always_ff @(posedge clk)
	begin
		if (!reset_n) begin
        		address_reg <= '0;
        		read_en_reg <= 0;
        		write_data_reg <= '0;
        		write_en_reg <= 0;

		end else begin
        		address_reg <= address;
        		read_en_reg <= read_en;
        		write_data_reg <= write_data;
        		write_en_reg <= write_en;
		end
	end
    
    
    	// always_ff @(posedge clk)
    	// begin
	//     	if (!reset_n) begin // 		read_data <= 0;
        // 		valid <= 0;
	// 		miss <= 0;
        // 		prop_address <= 0;
        // 		prop_write_data <= 0;
        // 		prop_write_en <= 0;
	// 	end else begin
	// 		read_data <= read_data_reg;
        // 		valid <= valid_reg;
	// 		miss <= miss_reg;
        // 		prop_address <= prop_address_reg;
        // 		prop_write_data <= prop_write_data_reg;
        // 		prop_write_en <= prop_write_en_reg;
	// 	end
    	// end
	
	// logic found;
	// logic [ASOC_BITS-1:0] index;
	
	logic hit;
	int  index;

	logic read_hit;
	logic write_hit;

	int replace_index;
	logic replace;

	logic replace_write;
	logic replace_read;

	assign read_hit = hit && read_en_reg;
	assign write_hit = hit && write_en_reg;

	assign replace_read = replace && read_en_reg;
	assign replace_write = replace && write_en_reg;

	assign valid_logic = hit;
	assign miss_logic = !hit;

	always_comb begin
		if (read_en_reg || write_en_reg) begin
			foreach (memory[cache_address.index].block[i]) begin
				if (memory[cache_address.index].block[i].tag == cache_address.tag && memory[cache_address.index].block[i].control_bits.valid == 1) begin 
					index = i;
					hit = 1;
					break;
				end else begin
					//TODO: handle dirty bit
					hit = 0;
					index = 0;
				end
			end
		end else begin
			hit = 0;
			index = 0;
		end
	end

	always_ff @(posedge clk)  begin
		if (hit) begin
			foreach (memory[cache_address.index].block[i]) begin
				if(memory[cache_address.index].block[i].control_bits.lsr_number > memory[cache_address.index].block[index].control_bits.lsr_number) begin
					memory[cache_address.index].block[i].control_bits.lsr_number = memory[cache_address.index].block[i].control_bits.lsr_number - 1;
				end
			end
			memory[cache_address.index].block[index].control_bits.lsr_number = '1;

		end else if (replace_write) begin
			foreach (memory[cache_address.index].block[i]) begin
				if(memory[cache_address.index].block[i].control_bits.lsr_number > memory[cache_address.index].block[replace_index].control_bits.lsr_number) begin
					memory[cache_address.index].block[i].control_bits.lsr_number = memory[cache_address.index].block[i].control_bits.lsr_number - 1;
				end
			end
			memory[cache_address.index].block[replace_index].control_bits.lsr_number = '1;

		end
	end

	always_comb begin
		if (read_hit) begin
			read_data_logic = memory[cache_address.index].block[index].data[cache_address.offset];
			prop_read_en_logic = 0;
			prop_address_logic = '0;

			// update control_bits.number
		end else begin			
			read_data_logic = '0;
			prop_read_en_logic = 1;
			prop_address_logic = address_reg;
			// replacement policy
		end
	end


	always_ff @(posedge clk) begin
		if (write_hit) begin
			memory[cache_address.index].block[index].data[cache_address.offset] = write_data_reg;
			memory[cache_address.index].block[index].control_bits.dirty = 1;
			// update control_bits.number
		end else if(write_en_reg) begin
					end
	end

	always_comb begin
		if (write_en_reg && miss_logic) begin
			foreach (memory[cache_address.index].block[i]) begin
				if (~|memory[cache_address.index].block[i].control_bits.lsr_number) begin
					replace_index = i;
					replace = 1;
					break;
				end else begin
					replace_index = 0;
					replace = 0;
				end
			end
			
			// replacement policy

		end else begin

			replace_index = 0;
			replace = 0;

		end


	end

	always_ff @(posedge clk) begin
		if (replace_write) begin
			memory[cache_address.index].block[replace_index].data[cache_address.offset] = write_data_reg;
			memory[cache_address.index].block[replace_index].tag = cache_address.tag;
			memory[cache_address.index].block[replace_index].control_bits.dirty = 1;
			memory[cache_address.index].block[replace_index].control_bits.valid = 1;
		end
	end



	// always_comb begin
	// 	if (read_en_reg) begin
	// 		foreach (cache[cache_address.index].block[i]) begin
	// 			if (cache[cache_address.index].block[i].tag == cache_address.tag && cache[cache_address.index].block[i].control_bits.valid == 1) begin 
	// 				read_data_logic = cache[cache_address.index].block[i].data[cache_address.offset];
	// 				miss_logic = 0;
	// 				valid_logic = 1;
	// 				prop_read_en_logic = 0;
	// 				prop_address_logic = '0;
	// 				break;
	// 			end else begin
	// 				read_data_logic = '0;
	// 				miss_logic = 1;
	// 				valid_logic = 0;
	// 				prop_read_en_logic = 1;
	// 				prop_address_logic = address_reg;
	// 				//TODO: handle dirty bit
	// 			end
	// 		end
	// 	end else begin
	// 		read_data_logic = '0;
	// 		miss_logic = 0;
	// 		valid_logic = 0;
	// 		prop_read_en_logic = 0;
	// 		prop_address_logic = '0;
	// 	end
	// end

	// logic found;

	// // ff? to put it in cache mem should be ff? or could it be comb? if
	// // comb -> could miss write through, dirty bit etc be in one clock?
	// always_ff @(posedge clk) begin	
	// 	if (write_en_reg) begin
	// 		found = 0;
	// 		foreach (cache[cache_address.index].block[i]) begin
	// 			if (cache[cache_address.index].block[i].tag == cache_address.tag && cache[cache_address.index].block[i].control_bits.valid == 1) begin 
	// 				cache[cache_address.index].block[i].data[cache_address.offset] = write_data_reg;
	// 				cache[cache_address.index].block[i].control_bits.dirty = 1;
	// 				found = 1;
	// 				break;
	// 			end 
	// 		end
	// 		if (!found) begin
	// 			foreach (cache[cache_address.index].block[i]) begin
	// 				if (cache[cache_address.index].block[i].tag == '0) begin 
	// 					//TODO: handle dirty bit
	// 					cache[cache_address.index].block[i].data[cache_address.offset] = write_data_reg;
	// 					cache[cache_address.index].block[i].tag = cache_address.tag;
	// 					break;
	// 				end 
	// 			end
	// 		end
	// 	end
	// end





endmodule
