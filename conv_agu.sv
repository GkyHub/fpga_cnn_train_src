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
// Calculate index buffer address
//=============================================================================
    reg     [ADDR_W -1 : 0] idx_rd_addr_r;

    always @ (posedge clk) begin
        if (start) begin
            idx_rd_addr_r <= 0;
        end
        else if (next_channel_r) begin
            idx_rd_addr_r <= idx_rd_addr_r + 1;
        end        
    end
    
    assign  idx_rd_addr = idx_rd_addr_r;
    
//=============================================================================
// Calculate data buffer address
//=============================================================================

    wire    [IDX_W  -1 : 0] idx_x, idx_y;
    assign  {idx_y, idx_x} = idx;
    
    reg     [2 : 0] ker_x_d0_r, ker_y_d0_r;
    reg     [2 : 0] ker_x_d1_r, ker_y_d1_r;
    reg     [3 : 0] pix_cnt_d_r;
    
    always @ (posedge clk) begin
        ker_x_d0_r <= ker_x_r;
        ker_x_d1_r <= ker_x_d0_r;
        ker_y_d0_r <= ker_y_r;
        ker_y_d1_r <= ker_y_d0_r;
        pix_cnt_d_r<= pix_cnt_r;
    end
    
    signed reg  [3 : 0] win_y_r
    signed reg  [5 : 0] win_x_r;
    signed reg  [3 : 0] pe_y_r;
    signed reg  [5 : 0] pe_x_r;
    
    always @ (posedge clk) begin
        win_y_r <= ker_y_d1_r - (conf_pad_u ? 1 : 0);
        win_x_r <= ker_x_d1_r - (conf_pad_l ? 1 : 0) + (pix_cnt_d_r << 1);
    end
    
    always @ (posedge clk) begin
        pe_y_r <= win_y_r[0] ? (win_y_r + 1 - GRP_ID_Y) : (win_y_r + GRP_ID_Y);
        pe_x_r <= win_x_r[0] ? (win_x_r + 1 - GRP_ID_X) : (win_x_r + GRP_ID_X);
    end
    
    // padding mask
    reg     pad_mask_r, dbuf_mask_r;
    always @ (posedge clk) begin
        pad_mask_r <= (win_x_r >= 0) && (win_x_r <= conf_lim_r) &&
                      (win_y_r >= 0) && (win_y_r <= conf_lim_d);
        dbuf_mask_r<= pad_mask_r;
    end
    assign  dbuf_mask = dbuf_mask_r;
    
    // shared data mux
    wire    [1 : 0] mux;
    assign  mux[0] = win_x_r[0];
    assign  mux[1] = win_y_r[0];
    
    Pipe#(.DW(2), .L(2)) mux_pipe (.clk, .s(mux), .d(dbuf_mux));
    
    // address
    reg     [4 -1 : 0] dbuf_addr_r;
    always @ (posedge clk) begin
        // y coordinate
        dbuf_addr_r[3 : 3] <= pe_y_r[1];
        // x coordinate
        dbuf_addr_r[2 : 0] <= pe_x_r[3 : 1];
    end    
    assign  dbuf_addr = {idx_x, dbuf_addr_r};    
    
//=============================================================================
// Calculate parameter buffer address
//============================================================================= 
    
    reg     [ADDR_W -1 : 0] pbuf_addr_conv_r;
    reg     [ADDR_W -1 : 0] pbuf_addr_uconv_r;
    wire    start_d;
    wire    next_channel_d;
    wire    next_pix_d;
    
    Pipe#(.DW(1), .L(4)) start_pipe (.clk, .s(start), .d(start_d));
    Pipe#(.DW(1), .L(3)) np_pipe    (.clk, .s(next_pix_r), .d(next_pix_d));    
    Pipe#(.DW(1), .L(2)) nc_pipe    (.clk, .s(next_channel_r), .d(next_channel_d));
    
    // address
    always @ (posedge clk) begin
        if (start_d) begin
            pbuf_addr_conv_r <= 0;
        end
        else if (next_pix_d && !next_channel_d) begin
                pbuf_addr_conv_r <= pbuf_addr_conv_r - 8;
            end
            else begin
                pbuf_addr_conv_r <= pbuf_addr_conv_r + 1;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (start_d) begin
            pbuf_addr_uconv_r <= 0;
        end
        else if (next_pix_d) begin
            if (next_channel_d) begin
                pbuf_addr_uconv_r[3 : 0] <= 0;
                pbuf_addr_uconv_r[ADDR_W-1 : 4] <= pbuf_addr_uconv_r[ADDR_W-1 : 4] + 1;
            end
            else begin
                pbuf_addr_uconv_r <= pbuf_addr_uconv_r + 1;
            end
        end
    end
    
    // select from 2 modes
    reg     [ADDR_W     -1 : 0] pbuf_addr_r;
    reg     [bw(BATCH)  -1 : 0] pbuf_sel_r;
    
    always @ (posedge clk) begin
        if (~mode[1]) begin // CONV mode
            pbuf_addr_r <= {{(bw(BATCH)){1'b0}}, pbuf_addr_conv_r[ADDR_W-1 : bw(BATCH)]};
            pbuf_sel_r  <= pbuf_addr_r[bw(BATCH) -1 : 0];
        end
        else begin
            pbuf_addr_r <= pbuf_addr_uconv_r;
            pbuf_sel_r  <= 0;
        end
    end
    
    assign  pbuf_addr   = pbuf_addr_r;
    assign  pbuf_sel    = pbuf_sel_r;
   
   
endmodule