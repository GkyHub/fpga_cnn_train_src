import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::bw;

module ddr2ibuf#(
    parameter   IDX_DEPTH   = 256,
    parameter   ADDR_W      = bw(IDX_DEPTH)
    )(
    input   clk,
    input   rst,
    
    // configuration port
    input           start,
    output          done,
    input   [2 : 0] mode,
    input   [7 : 0] idx_num,
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr_data,
    input                   ddr_valid,
    output                  ddr_ready,
    
    // pbuf write port
    output  [IDX_W*2-1 : 0] idx_wr_data,
    output  [ADDR_W -1 : 0] idx_wr_addr,
    output  [4      -1 : 0] idx_wr_en
    );
    
    localparam IDX_BATCH = DDR_W / IDX_W / 2;
    
    reg     [8  -1 : 0] idx_num_r;
    reg     [3  -1 : 0] mode_r;
    
    always @ (posedge clk) begin
        if (rst) begin
            idx_num_r <= 0;
            mode_r    <= 3'b000;
        end
        else if (start) begin
            idx_num_r <= idx_num;
            mode_r    <= mode;
        end
    end
    
    reg     [ADDR_W -1 : 0] idx_wr_addr_r;
    reg     [ADDR_W -1 : 0] idx_cnt_r;
    reg     [6      -1 : 0] batch_cnt_r;
    wire    [IDX_BATCH-1 : 0][IDX_W*2-1 : 0] ddr_data_arr;
    reg     ddr_ready_r;
    reg     [IDX_W*2-1 : 0] idx_wr_data_r;
    reg     idx_wr_en_r;
    
    always @ (posedge clk) begin
        if (start) begin
            batch_cnt_r <= 0;
        end
        else if (ddr_valid) begin
            batch_cnt_r <= (batch_cnt_r == IDX_BATCH-1) ? 0 : (batch_cnt_r + 1);
        end
    end
    
    always @ (posedge clk) begin
        if (start) begin
            idx_cnt_r <= 0;
        end
        else if (ddr_valid) begin
            idx_cnt_r <= idx_cnt_r + 1;
        end
    end
    
    // ready signal: ready when read a whole batch or the index are read done.
    always @ (posedge clk) begin
        if (rst) begin
            ddr_ready_r <= 1'b0;
        end
        else begin
            ddr_ready_r <= (batch_cnt_r == IDX_BATCH - 2) || (idx_cnt_r == idx_num_r);
        end
    end
    
    // data selection
    assign  ddr_data_arr = ddr_data;
    
    always @ (posedge clk) begin
        idx_wr_data = ddr_data_arr[batch_cnt_r];
    end
    
    // address
    always @ (posedge clk) begin
        idx_wr_addr_r <= idx_cnt_r;
    end
    
    // write enable
    always @ (posedge clk) begin
        if (rst) begin
            idx_wr_en_r <= 1'b0;
        end
        else begin
            idx_wr_en_r <= ddr_valid && (idx_cnt_r <= idx_num_r);
        end
    end
    
endmodule