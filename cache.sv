

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
	input	[DATA_BITS-1:0] ram_data [BLOCK_SIZE-1:0],

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
		logic [ASOC_BITS-1:0] lru_number;
	} cache_entry_control_bits_t;

    	typedef struct {
		cache_entry_control_bits_t control_bits;
        	logic [TAG_BITS-1:0] tag;
       		logic [DATA_BITS-1:0] data [0:BLOCK_SIZE-1];     // might have to be packed to match input from RAM
    	} cache_entry_t;

	typedef struct {
		cache_entry_t block [0:ASOC_SIZE-1];
	} cache_set_t;

	logic [DATA_BITS-1:0] read_data_logic;
        logic valid_logic;
	logic miss_logic;
       	logic [RAM_ADDRESS_BITS-1:0] prop_address_logic;
	logic prop_read_en_logic;
        logic [DATA_BITS-1:0] prop_write_data_logic [0:BLOCK_SIZE-1];
        logic prop_write_en_logic;


    	logic [RAM_ADDRESS_BITS-1:0] address_reg;
       	logic read_en_reg;
       	logic [DATA_BITS-1:0] write_data_reg;
        logic write_en_reg;
    	logic ram_valid_reg;
	logic [DATA_BITS-1:0] ram_data_reg [BLOCK_SIZE-1:0];


	cache_address_t cache_address;
	assign cache_address = address_reg;

	parameter INDEX_SIZE = 2**INDEX_BITS;
	cache_set_t cache [INDEX_SIZE-1:0];

	assign read_data = read_data_logic;
	assign valid = valid_logic;
	assign miss = miss_logic;
	assign prop_address = prop_address_logic;
	assign prop_read_en = prop_read_en_logic;
	assign prop_write_en = prop_write_en_logic;

	initial begin

		if (RAM_ADDRESS_BITS < CACHE_ADDRESS_BITS) begin
			$error("ERROR: cache settings wrong");
		end 
        	if ((ASOC_BITS+BLOCK_BITS) > CACHE_ADDRESS_BITS) begin 
			$error("ERROR: cache settings wrong");
        	end
        	$display("cache settings ok");
		cache = '{default: '{block: '{default: '{control_bits: '{valid: 0, dirty: 0, lru_number: '0}, tag: '0, data: '{default: '1}}}}}; // valid temporary
    	end


	always_ff @(posedge clk)
	begin
		if (!reset_n) begin
        		address_reg <= '0;
        		read_en_reg <= 0;
        		write_data_reg <= '0;
        		write_en_reg <= 0;

			ram_valid_reg <= 0;
			ram_data_reg <= '{default: '0};


		end else if(stop_cache) begin
        		address_reg <= address_reg;
        		read_en_reg <= read_en_reg;
        		write_data_reg <= write_data_reg;
        		write_en_reg <= write_en_reg;

			// not these two
			ram_valid_reg <= ram_valid;
			ram_data_reg <= ram_data;

		end else begin
        		address_reg <= address;
        		read_en_reg <= read_en;
        		write_data_reg <= write_data;
        		write_en_reg <= write_en;

			ram_valid_reg <= ram_valid;
			ram_data_reg <= ram_data;
		end
	end


    
	
	logic hit;
	int  index;

	logic read_hit;
	logic write_hit;

	int replace_index;
	logic replace;

	logic replace_write;
	logic replace_read;

	logic stop_cache;

	logic prop_dirty_wait; 

	assign read_hit = hit & read_en_reg;
	assign write_hit = hit & write_en_reg;

	assign replace_read = replace & read_en_reg;
	assign replace_write = replace & write_en_reg;

	assign valid_logic = hit | ram_valid_reg;

	assign stop_cache = (replace_read & ~ram_valid_reg) | prop_dirty_wait; 

	//TODO: handle dirty bit
	//TODO: write miss prop signals

	always_comb begin: check_hit
		if (read_en_reg | write_en_reg) begin
			foreach (cache[cache_address.index].block[i]) begin
				if (cache[cache_address.index].block[i].tag == cache_address.tag && cache[cache_address.index].block[i].control_bits.valid == 1) begin 
					index = i;
					hit = 1;
					miss_logic = 0;
					break;
				end else begin
					hit = 0;
					index = 0;
					miss_logic = 1;
				end
			end
		end else begin
			hit = 0;
			index = 0;
			miss_logic = 0;
		end
	end

	always_ff @(posedge clk)  begin: lru_number_update
		if (hit) begin
			foreach (cache[cache_address.index].block[i]) begin
				if(cache[cache_address.index].block[i].control_bits.lru_number > cache[cache_address.index].block[index].control_bits.lru_number) begin
					cache[cache_address.index].block[i].control_bits.lru_number = cache[cache_address.index].block[i].control_bits.lru_number - 1;
				end
			end
			cache[cache_address.index].block[index].control_bits.lru_number = '1;

		end else if (replace_write | (replace_read & ram_valid_reg)) begin
			foreach (cache[cache_address.index].block[i]) begin
				if(cache[cache_address.index].block[i].control_bits.lru_number > cache[cache_address.index].block[replace_index].control_bits.lru_number) begin
					cache[cache_address.index].block[i].control_bits.lru_number = cache[cache_address.index].block[i].control_bits.lru_number - 1;
				end
			end
			cache[cache_address.index].block[replace_index].control_bits.lru_number = '1;
		end

	end

	always_comb begin: read_request
		if (read_hit) begin
			read_data_logic = cache[cache_address.index].block[index].data[cache_address.offset];
			prop_read_en_logic = 0;
			prop_address_logic = '0;
		end else begin			
			read_data_logic = '0;
			prop_read_en_logic = 1;
			prop_address_logic = address_reg;
		end
	end


	always_comb begin: replace_index_calc_LSR
		if (miss_logic) begin
			foreach (cache[cache_address.index].block[i]) begin
				if (~|cache[cache_address.index].block[i].control_bits.lru_number) begin
					replace_index = i;
					replace = 1;
					break;
				end else begin
					replace_index = 0;
					replace = 0;
				end
			end
			
		end else begin
			replace_index = 0;
			replace = 0;
		end
	end


	always_comb  begin: dirty_replace
		if (replace & cache[cache_address.index].block[replace_index].control_bits.dirty) begin
			prop_write_en_logic = 1;
			prop_write_data_logic = cache[cache_address.index].block[replace_index].data;
		end else begin
			prop_write_en_logic = 0;
			prop_write_data_logic = '{default: '0};
		end
	end


	always_ff @(posedge clk) begin: dirty_replace_wait
		if (~ram_valid & prop_write_en_logic) begin
			prop_dirty_wait = 1;
		end else begin
			prop_dirty_wait = 0;
		end
	end


	always_ff @(posedge clk) begin: replace_block
		if (write_hit) begin
			cache[cache_address.index].block[index].data[cache_address.offset] = write_data_reg;
			cache[cache_address.index].block[index].tag = cache_address.tag;
			cache[cache_address.index].block[index].control_bits.dirty = 1;
			cache[cache_address.index].block[index].control_bits.valid = 1;
		end else if (replace_write) begin
			cache[cache_address.index].block[replace_index].data[cache_address.offset] = write_data_reg;
			cache[cache_address.index].block[replace_index].tag = cache_address.tag;
			cache[cache_address.index].block[replace_index].control_bits.dirty = 1;
			cache[cache_address.index].block[replace_index].control_bits.valid = 1;
		end else if (replace_read) begin
			if (ram_valid_reg) begin
				cache[cache_address.index].block[replace_index].data = ram_data_reg;
				cache[cache_address.index].block[replace_index].tag = cache_address.tag;
				cache[cache_address.index].block[replace_index].control_bits.dirty = 0;
				cache[cache_address.index].block[replace_index].control_bits.valid = 1;
			end
		end
	end



endmodule
