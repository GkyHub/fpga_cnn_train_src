import GLOBAL_PARAM::bw;
import GLOBAL_PARAM::IDX_W;
import GLOBAL_PARAM::BATCH;

module fc_agu#(
    parameter   ADDR_W  = 8
    )(
    input   clk,
    input   rst,
    
    input   start,
    output  done,
    input   [2  -1 : 0] conf_mode,
    input   [8  -1 : 0] conf_idx_cnt,   // number of idx to deal with
    input   [8  -1 : 0] conf_trip_cnt,  // number of cycles for the agu to work with a single cycle
    input               conf_is_new,
    
    // buffer address generation port
    output  [ADDR_W     -1 : 0] dbuf_addr,  // data buffer address
    output                      dbuf_mask,  // padding mask
    output  [2          -1 : 0] dbuf_mux,   // data sharing mux
    
    output  [ADDR_W     -1 : 0] pbuf_addr,  // parameter buffer address
    output  [bw(BATCH)  -1 : 0] pbuf_sel,   // parameter scalar selection 
    
    output  [ADDR_W     -1 : 0] abuf_addr,  // accumulate buffer address
    output  [BATCH      -1 : 0] abuf_acc_en,// enable mask
    output                      abuf_acc_new
    );
    
    
    
endmodule