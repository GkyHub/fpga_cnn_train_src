import  GLOBAL_PARAM::DDR_W

module ddr2dbuf#(
    
    )(
    input   clk,
    input   rst,
    
    // configuration port
    input           start,
    output          done,
    input   [1 : 0] mode,
    input   [3 : 0] ch_num,
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr_data,
    input                   ddr_valid,
    
    // dbuf write port
    output         [bw(BUF_DEPTH)  -1 : 0] dbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data,
    output  [3 : 0]                        dbuf_wr_en
    )