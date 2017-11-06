import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::BATCH;
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
    input   [7 : 0] conf_trans_num,
    input   [2 : 0] conf_mode,
    input   [3 : 0] conf_ch_num,    // only for update
    input   [3 : 0] conf_pix_num,   // only for update
    input   [1 : 0] conf_row_num,   // only for update
    input           conf_depool,    // only for update
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr1_data,
    input                   ddr1_valid,
    
    input   [DDR_W  -1 : 0] ddr2_data,
    input                   ddr2_valid,
    
    // pbuf write port
    output  [3 : 0][ADDR_W         -1 : 0] pbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    output  [3 : 0]                        pbuf_wr_en,
    
    // bbuf accumulation port
    input                   bbuf_accum_en,
    input                   bbuf_accum_new,
    input   [ADDR_W -1 : 0] bbuf_accum_addr,
    input   [RES_W  -1 : 0] bbuf_accum_data,
    );

//=============================================================================
// forward and backward mode
//============================================================================= 
    
    reg     [8      -1 : 0] param_cnt_r;
    wire    [ADDR_W -1 : 0] param_addr;
    wire                    param_wr_en;
    reg     param_last_r;
        
    always @ (posedge clk) begin
        if (start) begin
            param_cnt_r <= 0;
        end
        else if (ddr2_valid) begin
            param_cnt_r <= param_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            param_last_r <= 1'b1;
        end
        else if (start) begin
            param_last_r <= 1'b0;
        end
        else if (param_cnt_r == conf_param_num && ddr2_valid) begin
            param_last_r <= 1'b1;
        end
        else begin
            param_last_r <= 1'b0;
        end
    end
    
    assign  param_addr = param_cnt_r;
    assign  param_wr_en= ddr2_valid;

//=============================================================================
// update mode
//=============================================================================

    reg     [3 : 0] row_cnt_r;
    reg     [3 : 0] pix_cnt_r;
    reg     [3 : 0] ch_cnt_r;
    reg     [3 : 0] ch_cnt_d;
    reg             next_pix_r;
    reg     [ADDR_W -1 : 0] conv_addr;
    wire    [4      -1 : 0] conv_wr_mask;
    reg             conv_last_r;
    
    always @ (posedge clk) begin
        if (start) begin
            ch_cnt_r <= 0;
        end
        else if (ddr1_valid && ddr2_valid) begin
            ch_cnt_r <= (ch_cnt_r == ch_num_r) ? 0 : ch_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        next_pix_r  <= (ch_cnt_r == ch_num_r) && ddr1_valid && ddr2_valid;
        ch_cnt_d    <= ch_cnt_r;
    end
    
    always @ (posedge clk) begin
        if (start) begin
            row_cnt_r <= 0;
            pix_cnt_r <= 0;
        end
        else if (next_pix_r) begin
            if (pix_cnt_r == pix_num_r) begin
                pix_cnt_r <= 0;
                row_cnt_r <= row_cnt_r + 1;
            end
            else begin
                pix_cnt_r <= pix_cnt_r + 1;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            conv_last_r <= 1'b0;
        end
        else begin
            conv_last_r <= next_pix_r && (pix_cnt_r == pix_num_r) && (row_cnt_r == row_num_r);
        end
    end
    
    always_comb begin
        conv_addr[ADDR_W-1 : 4] <= ch_cnt_d;
        conv_addr[3]            <= row_cnt_r[1];
        conv_addr[2 : 0]        <= pix_cnt_r[3 : 1]; 
    end
    
    assign conv_wr_mask = 1 << {row_cnt_r[0], pix_cnt_r[0]};
    
endmodule