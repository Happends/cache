

module cache 
    #(  parameter RAM_ADDRESS_BITS = 10,    // change to size
        parameter CACHE_ADDRESS_BITS = 5,   // change to size
        parameter DATA_WIDTH=32,
        parameter ASOC_BITS=1,
        parameter BLOCK_BITS=2)

    (   input   clk,
                reset_n,
                request,
                [RAM_ADDRESS_BITS-1:0] address, 
                [DATA_WIDTH-1:0] write_data, 
                write_en,

        output  [DATA_WIDTH-1:0] read_data,
                valid,
                miss,
                [RAM_ADDRESS_BITS-1:0] prop_address, 
                [DATA_WIDTH-1:0] prop_write_data, 
                prop_write_en);

    
    typedef struct {
        logic [RAM_ADDRESS_BITS-CACHE_ADDRESS_BITS-ASOC_BITS-BLOCK_BITS-1:0] tag;
        logic [CACHE_ADDRESS_BITS-ASOC_BITS-BLOCK_BITS-1:0] index;
        logic [BLOCK_BITS-1: 0] offset;
    } cache_address_t;

    typedef struct {
        logic [RAM_ADDRESS_BITS-1:CACHE_ADDRESS_BITS-ASOC_BITS] tag;
        logic [DATA_WIDTH-1: 0] data;
    } cache_entry_t;
    
    logic [RAM_ADDRESS_BITS-1:0] address_net;
    cache_address_t cache_address;
    assign cache_address = address_net;

    parameter SIZE = 2**CACHE_ADDRESS_BITS;
    cache_entry_t cache [0:SIZE-1];

    parameter assoc = ASOC_BITS**2;


    initial begin
        if ((ASOC_BITS+BLOCK_BITS) < CACHE_ADDRESS_BITS) begin 
            $display("cache settings ok");
        end else begin
            $error("ERROR: cache settings wrong");
        end
        cache <= '{ default: '0};
    end
    
    
    always_ff @(posedge clk)
    begin
        cache_address <= address;
    end


    // HOW TO IMPLEMENT GETTING THE BLOCKS FROM RAM 
    //      iterate every line for block?
    //      get entire block through like 256 signals

    // idea: request needed? or unneccessary since address shouldnt change unless new data wanted!?
    // always_comb begin
    //     if request begin
    //         // index into cache
    //         // for each entry in set (asoc_bits**2)
    //             // if tag in cache
    //                 // clock output index
    //             // else
    //                 // MISS
    //                 // clock output miss and prop
    //                 // wait for request from ram
    //                 // clock set entry in cache and output request
    //     end
    // end

    // always @ (posedge clk) begin
    //     if request && 
    // end





endmodule