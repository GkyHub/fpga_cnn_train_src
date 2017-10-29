import GLOBAL_PARAM::bw;
import GLOBAL_PARAM::IDX_W;
import GLOBAL_PARAM::BATCH;

module conv_agu#(
    parameter   ADDR_W  = 8,
    parameter   GRP_ID_Y= 0,
    parameter   GRP_ID_X= 0
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

//=============================================================================
// Counter Status
//=============================================================================
    
    reg     working_r;
    
    // 2-dim counter for kernel x, y
    reg     [2 : 0] ker_x_r, ker_y_r;
    reg     next_pix_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            ker_x_r <= 0;
            ker_y_r <= 0;
        end
        else if (start) begin
            ker_x_r <= 0;
            ker_y_r <= 0;
        end
        else if (ker_x_r < 2) begin
            ker_x_r <= ker_x_r + 1;
            ker_y_r <= ker_y_r;
        end
        else begin
            ker_x_r <= 0;
            ker_y_r <= (ker_y_r < 2) ? (ker_y_r + 1) : 0;
        end
    end
    
    always @ (posedge clk) begin
        next_pix_r <= (ker_x_r == 2) && (ker_y_r == 2);
    end
    
    // pixel row counter
    reg     [3 : 0] pix_cnt_r;
    reg     next_channel_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            pix_cnt_r <= 0;
        end
        else if (start) begin
            pix_cnt_r <= 0;
        end
        else if (next_pix_r) begin
            pix_cnt_r <= (pix_cnt_r == conf_row_cnt) ? 0 : (pix_cnt_r + 1);
        end
    end
    
    always @ (posedge clk) begin
        if (working_r) begin
            next_channel_r <= next_pix_r && (pix_cnt_r == conf_row_cnt);
        end
        else begin
            next_channel_r <= 1'b0;
        end
    end
    
    // channel 
    reg     [4 : 0] channel_cnt_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            channel_cnt_r <= 0;
        end
        else if (start) begin
            channel_cnt_r <= 0;
        end
        else if (next_channel_r) begin
            channel_cnt_r <= (channel_cnt_r < conf_trip_cnt) ? channel_cnt_r + 1 : channel_cnt_r;
        end
    end
    
    // working status
    always @ (posedge clk) begin
        if (rst) begin
            working_r <= 1'b0;
        end
        else if (start) begin
            working_r <= 1'b1;
        end
        else if (channel_cnt_r == conf_trip_cnt && next_channel_r) begin
            working_r <= 1'b0;
        end
    end
    
//=============================================================================
// Calculate address
//=============================================================================

    wire    [IDX_W  -1 : 0] idx_x, idx_y;
    assign  {idx_y, idx_x} = idx;
    
    reg     [2 : 0] 
    
    signed reg  [3 : 0] win_y_r
    signed reg  [5 : 0] win_x_r;
    signed reg  [3 : 0] pe_y_r;
    signed reg  [5 : 0] pe_x_r;
    
    always @ (posedge clk) begin
        win_y_r <= ker_y_r - (conf_pad_u ? 1 : 0);
        win_x_r <= ker_x_r - (conf_pad_l ? 1 : 0) + (pix_cnt_r << 1);
    end
    
    always @ (posedge clk) begin
        pe_y_r <= win_y_r[0] ? (win_y_r + 1 - GRP_ID_Y) : (win_y_r + GRP_ID_Y);
        pe_x_r <= win_x_r[0] ? (win_x_r + 1 - GRP_ID_X) : (win_x_r + GRP_ID_X);
    end
    
    // padding mask
    reg     pad_mask_r;
    always @ (posedge clk) begin
        pad_mask_r <= (win_x_r >= 0) && (win_x_r <= conf_lim_r) &&
                      (win_y_r >= 0) && (win_y_r <= conf_lim_d);
    end
    
    // shared data mux
    wire    [1 : 0] mux;
    assign  mux[0] = win_x_r[0];
    assign  mux[1] = win_y_r[0];
    
    // address
    reg     [4 : 0] addr
    
endmodule