import  GLOBAL_PARAM::BATCH;
import  GLOBAL_PARAM::DATA_W;
import  GLOBAL_PARAM::TAIL_W;
import  GLOBAL_PARAM::bw;

module ddr2abuf#(
    parameter   BUF_DEPTH,
    parameter   ADDR_W  = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    input           start,
    output          done,
    input   [1 : 0] conf_trans_type,
    input   [7 : 0] conf_trans_num,
    
    // ddr data stream port
    input   [DDR_W  -1 : 0] ddr_data,
    input                   ddr_valid,
    output                  ddr_ready,
    
    // accum and bias buf port
    input   [3 : 0][ADDR_W         -1 : 0] abuf_wr_addr,
    input   [3 : 0][BATCH * DATA_W -1 : 0] abuf_wr_data,
    input   [3 : 0]                        abuf_wr_data_en,
    input   [3 : 0][BATCH * TAIL_W -1 : 0] abuf_wr_tail,
    input   [3 : 0]                        abuf_wr_tail_en,
    
    input   [ADDR_W -1 : 0] bbuf_wr_addr,
    input   [DATA_W -1 : 0] bbuf_wr_data,
    input                   bbuf_wr_data_en,
    input   [TAIL_W -1 : 0] bbuf_wr_tail,
    input                   bbuf_wr_tail_en,
    );
    
    localparam TD_RATE = TAIL_W / DATA_W;
    
    reg     [ADDR_W -1 : 0] abuf_addr_r;
    reg     [3      -1 : 0] abuf_pack_cnt_r;
    
    wire    [TD_RATE-1:0][BATCH-1:0][DATA_W-1:0] abuf_tail_buf;
    
    always @ (posedge clk) begin
        if (start && ~conf_mode[0]) begin
            abuf_addr_r     <= 0;
            abuf_pack_cnt_r <= 0; 
        end
        else if (ddr_valid) begin
            abuf_addr_r     <= abuf_addr_r + 1;
            abuf_pack_cnt_r <= (abuf_pack_cnt_r == TD_RATE - 1) ? 
        end
    end
    
endmodule