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
    input               conf_is_new,
    
    // index read port
    output  [ADDR_W     -1 : 0] idx_rd_addr,
    input   [IDX_W * 2  -1 : 0] idx,
    
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
    
    reg     [ADDR_W     -1 : 0] idx_rd_addr_r;
    
    reg     [ADDR_W     -1 : 0] dbuf_addr_r;
    reg                         dbuf_mask_r;
    reg     [2          -1 : 0] dbuf_mux_r;
    
    reg     [ADDR_W     -1 : 0] pbuf_addr_r;
    reg     [bw(BATCH)  -1 : 0] pbuf_sel_r;
    
    reg     [ADDR_W     -1 : 0] abuf_addr_r;
    reg     [BATCH      -1 : 0] abuf_acc_en_r;
    reg                         abuf_acc_new_r;
    
    reg     idx_rd_done_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            idx_rd_addr_r <= 0;
        end
        else if (start) begin
            idx_rd_addr_r <= 0;
        end
        else if (idx_rd_addr_r < conf_idx_cnt) begin
            idx_rd_addr_r <= idx_rd_addr_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            idx_rd_done_r <= 1'b1;
        end
        else if (start) begin
            idx_rd_done_r <= 1'b0;
        end
        else if (idx_rd_addr_r == conf_idx_cnt) begin
            idx_rd_done_r <= 1'b1;
        end
    end
    
    always @ (posedge clk) begin
        dbuf_addr_r <= {(ADDR_W - IDX_W){1'b0}, idx[IDX_W - 1 : 0]};
        dbuf_mask   <= '1;
        dbuf_mux    <= 2'b00;
    end
    
    assign  idx_rd_addr     = idx_rd_addr_r;
    assign  dbuf_addr       = dbuf_addr_r;
    assign  dbuf_mask       = dbuf_mask_r;
    assign  dbuf_mux        = dbuf_mux_r;    
    assign  pbuf_addr       = pbuf_addr_r;
    assign  pbuf_sel        = pbuf_sel_r;    
    assign  abuf_addr       = abuf_addr_r;
    assign  abuf_acc_en     = abuf_acc_en_r;
    assign  abuf_acc_new    = abuf_acc_new_r;
    
endmodule