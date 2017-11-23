module sync_fifo#(
    parameter   DATA_W  = 8,
    parameter   DEPTH   = 16,
    parameter   AF_TH   = 10,       // almost full threshold
    parameter   AE_TH   = 3,        // almost empty threshold
    parameter   TYPE    = "block",  // RAM type
    )(
    input   clk,
    input   rst,
    
    input   [DATA_W -1 : 0] wr_data,
    input                   wr_en,
    output                  full,
    output                  a_full,
    
    output  [DATA_W -1 : 0] rd_data,
    input                   rd_en,
    output                  empty,
    output                  a_empty
    );
    
    
    
endmodule