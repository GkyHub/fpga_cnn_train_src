import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::BATCH;
import  GLOBAL_PARAM::bw;
import  GLOBAL_PARAM::RES_W;
import  GLOBAL_PARAM::DATA_W;

module ddr2pbuf#(
    parameter   BUF_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    // configuration port
    input           start,
    output          done,
    input   [1 : 0] conf_grp_sel,   // only for forward and backward
    input   [7 : 0] conf_trans_num,
    input   [2 : 0] conf_mode,
    input   [3 : 0] conf_ch_num,    // only for update
    input   [3 : 0] conf_pix_num,   // only for update
    input   [1 : 0] conf_row_num,   // only for update
    input           conf_depool,    // only for update
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr1_data,
    input                   ddr1_valid,
    output                  ddr1_ready,
    
    input   [DDR_W  -1 : 0] ddr2_data,
    input                   ddr2_valid,
    output                  ddr2_ready,
    
    // pbuf write port
    output         [ADDR_W         -1 : 0] pbuf_wr_addr,
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
    reg     [ADDR_W -1 : 0] update_addr;
    wire    [4      -1 : 0] update_wr_mask;
    reg             update_last_r;
    
    always @ (posedge clk) begin
        if (start) begin
            ch_cnt_r <= 0;
        end
        else if (ddr1_valid && ddr2_valid) begin
            ch_cnt_r <= (ch_cnt_r == ch_num_r) ? 0 : ch_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        next_pix_r  <= (ch_cnt_r == ch_num_r) && (ddr1_valid && ddr2_valid);
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
            update_last_r <= 1'b0;
        end
        else begin
            update_last_r <= next_pix_r && (pix_cnt_r == pix_num_r) && (row_cnt_r == row_num_r);
        end
    end
    
    always_comb begin
        update_addr[ADDR_W-1 : 4] <= ch_cnt_d;
        update_addr[3]            <= row_cnt_r[1];
        update_addr[2 : 0]        <= pix_cnt_r[3 : 1]; 
    end
    
//=============================================================================
// data and address selection
//=============================================================================

    reg     [BATCH  -1 : 0][DATA_W  -1 : 0] ddr1_data_d;
    reg     [BATCH  -1 : 0][DATA_W  -1 : 0] ddr2_data_d;
    reg                     ddr_valid_d;
    
    reg     [ADDR_W-1 : 0] pbuf_wr_addr_r;
    reg     [3 : 0][BATCH -1 : 0][DATA_W-1 : 0] pbuf_wr_data_r;
    reg     [3 : 0]                        pbuf_wr_en_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            ddr_valid_d <= 1'b0;
        end
        else begin
            ddr_valid_d <= (conf_mode[2:1] == 2'b10) ? (ddr1_valid && ddr2_valid) : ddr2_valid;
        end
    end
    
    always @ (posedge clk) begin
        ddr1_data_d <= ddr1_data;
        ddr2_data_d <= ddr2_data;
    end

    always @ (posedge clk) begin
        if (mode[2:1] == 2'b10) begin
            pbuf_wr_addr_r <= update_addr;
        end
        else begin
            pbuf_wr_addr_r <= param_addr;
        end
    end
    
    genvar i, j;
    generate
        for (j = 0; j < 4; j = j + 1) begin: UNIT
            for (i = 0; i < BATCH; i = i + 1) begin: ARRAY
                always @ (posedge clk) begin
                    if (mode[2:1] == 2'b10) begin
                        if (conf_depool) begin
                            pbuf_wr_data_r[j][i] <= ddr2_data_d[i][j] ? ddr1_data_d[j][i] : '0;
                        end
                        else begin
                            pbuf_wr_data_r[j][i] <= ddr2_data_d[i][j];
                        end
                    end
                    else begin
                        pbuf_wr_data_r[j][i] <= ddr1_data[DATA_W*i +: DATA_W];
                    end
                end
            end
            
            always @ (posedge clk) begin
                if (rst) begin
                    pbuf_wr_en_r[j] <= 1'b0;
                end
                else if (mode[2:1] == 2'b10) begin
                    if (conf_depool) begin
                        pbuf_wr_en_r <= ddr_valid_d;
                    end
                    else begin
                        pbuf_wr_en_r <= ddr_valid_d && {row_cnt_r[0], pix_cnt_r[0]} == j;
                    end
                end
                else begin
                    pbuf_wr_en_r <= (conf_grp_sel << j) && ddr2_valid;
                end
            end
            
        end
    endgenerate
    
    assign  pbuf_wr_addr    = pbuf_wr_addr_r;
    assign  pbuf_wr_data    = pbuf_wr_data_r;
    assign  pbuf_wr_en      = pbuf_wr_en_r;

//=============================================================================
// update bias
//=============================================================================
    wire    [RES_W  -1 : 0] channel_sum;

    adder_tree#(
        .DATA_W (DATA_W ),
        .DATA_N (BATCH  ),
        .RES_W  (RES_W  )
    ) bias_gradient_sum (
        .clk    (clk        ),
    
        .vec    (ddr1_data  ),
        .sum    (channel_sum)
    );
    
    
endmodule