import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::bw;

module ddr2pbuf#(
    parameter   BUF_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    // configuration port
    input           start,
    output          done,
    input   [2 : 0] mode,
    input   [3 : 0] ch_num,     // only for conv_update
    input   [3 : 0] pix_num,    // only for conv_update
    input           depool,     // only for conv_update
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr1_data,
    input                   ddr1_valid,
    
    input   [DDR_W  -1 : 0] ddr2_data,
    input                   ddr2_valid,
    
    // pbuf write port
    output  [3 : 0][ADDR_W         -1 : 0] pbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    output  [3 : 0]                        pbuf_wr_en,
    
    // bbuf write port
    output  [DATA_W -1 : 0] bbuf_wr_data,
    output  [ADDR_W -1 : 0] bbuf_wr_addr,
    output                  bbuf_wr_en
    );
    
    
    
endmodule