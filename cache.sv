

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


	parameter BLOCK_SIZE = BLOCK_BITS**2;
	parameter ASOC_SIZE = ASOC_BITS**2;

	// typedef for cache entries
    	typedef struct {
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

	parameter INDEX_SIZE = INDEX_BITS**2;
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
		cache = '{default: '{block: '{default: '{tag: '0, data: '{default: '1}}}}};
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
	

	always_comb begin
		if (read_en_reg) begin
			foreach (cache[cache_address.index].block[i]) begin
				if (cache[cache_address.index].block[i].tag == cache_address.tag) begin 
					read_data_logic = cache[cache_address.index].block[i].data[cache_address.offset];
					miss_logic = 0;
					valid_logic = 1;
					prop_read_en_logic = 0;
					prop_address_logic = '0;
					break;
				end else begin
					read_data_logic = '0;
					miss_logic = 1;
					valid_logic = 0;
					prop_read_en_logic = 1;
					prop_address_logic = address_reg;
				end
			end
		end else begin
			read_data_logic = '0;
			miss_logic = 0;
			valid_logic = 0;
			prop_read_en_logic = 0;
			prop_address_logic = '0;
		end
	end

	logic found;

	// ff? to put it in cache mem should be ff? or could it be comb? if
	// comb -> could miss write through, dirty bit etc be in one clock?
	always_ff @(posedge clk) begin	
		if (write_en_reg) begin
			found = 0;
			foreach (cache[cache_address.index].block[i]) begin
				if (cache[cache_address.index].block[i].tag == cache_address.tag) begin 
					cache[cache_address.index].block[i].data[cache_address.offset] = write_data_reg;
					found = 1;
					break;
				end 
			end
			if (!found) begin
				foreach (cache[cache_address.index].block[i]) begin
					if (cache[cache_address.index].block[i].tag == '0) begin 
						cache[cache_address.index].block[i].data[cache_address.offset] = write_data_reg;
						cache[cache_address.index].block[i].tag = cache_address.tag;
						break;
					end 
				end
			end
		end
	end





endmodule
