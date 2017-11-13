import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::bw;

module ddr2dbuf#(
    parameter   BUF_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH),
    parameter   PE_NUM      = 32
    )(
    input   clk,
    input   rst,
    
    // configuration port
    input                   start,
    output                  done,
    input   [4      -1 : 0] conf_mode,
    input   [4      -1 : 0] conf_ch_num,
    input   [4      -1 : 0] conf_row_num, 
    input   [4      -1 : 0] conf_row_num, 
    input   [4      -1 : 0] conf_pix_num, 
    input   [4      -1 : 0] conf_pix_num, 
    input   [PE_NUM -1 : 0] conf_mask,
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr_data,
    input                   ddr_valid,
    
    // dbuf write port    
    output  [3:0][DATA_W*BATCH-1 : 0] dbuf_wr_data,
    output  [ADDR_W -1 : 0] dbuf_wr_addr,
    output  [PE_NUM -1 : 0] dbuf_wr_en
    );
    
//=============================================================================
// CONV mode
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
        else if (ddr_valid) begin
            ch_cnt_r <= (ch_cnt_r == conf_ch_num) ? 0 : ch_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        next_pix_r  <= (ch_cnt_r == conf_ch_num) && ddr_valid;
        ch_cnt_d    <= ch_cnt_r;
    end
    
    always @ (posedge clk) begin
        if (start) begin
            row_cnt_r <= 0;
            pix_cnt_r <= 0;
        end
        else if (next_pix_r) begin
            if (pix_cnt_r == conf_pix_num) begin
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
            conv_last_r <= next_pix_r && (pix_cnt_r == conf_pix_num) && (row_cnt_r == conf_row_num);
        end
    end
    
    always_comb begin
        conv_addr[ADDR_W-1 : 4] <= ch_cnt_d;
        conv_addr[3]            <= row_cnt_r[1];
        conv_addr[2 : 0]        <= pix_cnt_r[3 : 1]; 
    end
    
    assign conv_wr_mask = 1 << {row_cnt_r[0], pix_cnt_r[0]};
    
//=============================================================================
// FC mode
//=============================================================================
    reg     [ADDR_W -1 : 0] fc_addr_r;
    reg                     fc_last_r;
    
    always @ (posedge clk) begin
        if (start) begin
            fc_addr_r <= 0;
        end
        else if (ddr_valid) begin
            fc_addr_r <= fc_addr_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            fc_last_r <= 1'b0;
        end
        else begin
            fc_last_r <= ddr_valid && (fc_addr_r == conf_ch_num);
        end
    end
    
//=============================================================================
// Address and data mux
//=============================================================================

    reg     [DDR_W  -1 : 0] ddr_data_d;
    reg                     ddr_valid_d;
    
    reg            [bw(BUF_DEPTH)  -1 : 0] dbuf_wr_addr_r;
    reg     [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data_r;
    reg     [PE_NUM -1 : 0]                dbuf_wr_en_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            ddr_valid_d <= 0;
            ddr_data_d  <= '0;
        end
        else begin
            ddr_valid_d <= ddr_valid;
            ddr_data_d  <= ddr_data;
        end
    end
    
    always @ (posedge clk) begin
        if (mode[0]) begin
            dbuf_wr_data_r  <= ddr_data;
            dbuf_wr_addr_r  <= fc_addr_r;
            dbuf_wr_en_r    <= {PE_NUM{ddr_valid}} & conf_mask;
        end
        else begin
            dbuf_wr_data_r  <= ddr_data_d;
            dbuf_wr_addr_r  <= conv_addr;
            dbuf_wr_en_r    <= {(PE_NUM/4){conv_wr_mask}} & conf_mask;
        end
    end
    
    assign dbuf_wr_data = dbuf_wr_data_r;
    assign dbuf_wr_addr = dbuf_wr_addr_r;
    assign dbuf_wr_en   = dbuf_wr_en_r;
    
//=============================================================================
// done signal
//=============================================================================

    reg done_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            done_r <= 1'b1;
        end
        else if (start) begin
            done_r <= 1'b0;
        end
        else begin
            if (conf_mode[0]) begin
                if (fc_last_r) begin
                    done_r <= 1'b1;
                end
            end
            else begin
                if (conv_last_r) begin
                    done_r <= 1'b1;
                end
            end
        end
    end
    
    assign  done = done_r;
    
endmodule