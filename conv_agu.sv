import GLOBAL_PARAM::bw;
import GLOBAL_PARAM::IDX_W;
import GLOBAL_PARAM::BATCH;

module conv_agu#(
    parameter   ADDR_W  = 8
    )(
    input   clk,
    input   rst,
    
    input   start,
    output  done,
    input   [2  -1 : 0] conf_mode,
    input   [8  -1 : 0] conf_idx_cnt,   // number of idx to deal with
    input   [8  -1 : 0] conf_trip_cnt,
    input               conf_is_new,
    input               conf_pad_u,
    input               conf_pad_l,
    input   [6  -1 : 0] conf_lim_r,
    input   [6  -1 : 0] conf_lim_d,
    input   [6  -1 : 0] conf_row_cnt,
    
    // index read port
    output  [ADDR_W     -1 : 0] idx_rd_addr,
    input   [IDX_W * 2  -1 : 0] idx,
    
    // buffer address generation port
    output  [ADDR_W     -1 : 0] dbuf_addr,  // data buffer address
    output                      dbuf_mask,  // padding mask
    output  [2          -1 : 0] dbuf_mux,   // data sharing mux
    
    output  [ADDR_W     -1 : 0] pbuf_addr,  // parameter buffer address
    output  [bw(BATCH)  -1 : 0] pbuf_sel,   // parameter scalar selection 
    
    output                      mac_new_acc,
    
    output  [ADDR_W     -1 : 0] abuf_addr,  // accumulate buffer address
    output  [BATCH      -1 : 0] abuf_acc_en,// enable mask
    output                      abuf_acc_new
    );
    
    always @ (posedge clk) begin
    
    
    end
    
    
endmodule