import GLOBAL_PARAM::DDR_ADDR_W;
import GLOBAL_PARAM::BURST_W;
import INS_CONST::*;

module ddr2pe_config(
    input           clk,
    input           rst,
        
    input   [3      -1 : 0] layer_type,
    input   [8      -1 : 0] image_width,
    
    input                   ins_valid,
    output                  ins_ready,
    input   [INST_W -1 : 0] ins,
    
    output                  ibuf_start,
    input                   ibuf_done,
    output  [4      -1 : 0] ibuf_conf_mode,
    output  [8      -1 : 0] ibuf_conf_idx_num,
    output  [PE_NUM -1 : 0] ibuf_conf_mask,
    
    output                  dbuf_start,
    input                   dbuf_done,
    output  [4      -1 : 0] dbuf_conf_mode,
    output  [4      -1 : 0] dbuf_conf_ch_num,
    output  [4      -1 : 0] dbuf_conf_row_num,
    output  [4      -1 : 0] dbuf_conf_pix_num,
    output  [PE_NUM -1 : 0] dbuf_conf_mask,
    
    output                  pbuf_start,
    input                   pbuf_done,
    output  [8      -1 : 0] pbuf_conf_trans_num,
    output  [4      -1 : 0] pbuf_conf_mode,     
    output  [4      -1 : 0] pbuf_conf_ch_num,   
    output  [4      -1 : 0] pbuf_conf_pix_num,  
    output  [2      -1 : 0] pbuf_conf_row_num,  
    output                  pbuf_conf_depool,
    output  [PE_NUM -1 : 0] pbuf_conf_mask,

    output                  abuf_start,
    input                   abuf_done,
    output  [2      -1 : 0] abuf_conf_trans_type,
    output  [8      -1 : 0] abuf_conf_trans_num,
    output  [PE_NUM -1 : 0] abuf_conf_mask,
    
    output                      ddr1_start,
    input                       ddr1_done,
    output  [DDR_ADDR_W -1 : 0] ddr1_st_addr,
    output  [BURST_W    -1 : 0] ddr1_burst,
    output  [DDR_ADDR_W -1 : 0] ddr1_step,
    output  [BURST_W    -1 : 0] ddr1_burst_num,
    
    output                      ddr2_start,
    input                       ddr2_done,
    output  [DDR_ADDR_W -1 : 0] ddr2_st_addr,
    output  [BURST_W    -1 : 0] ddr2_burst,
    output  [DDR_ADDR_W -1 : 0] ddr2_step,
    output  [BURST_W    -1 : 0] ddr2_burst_num
    );
    
    wire    [3 : 0] opcode = ins[61:58];
    wire    [5 : 0] buf_id = ins[57:52];
    wire    [7 : 0] size   = ins[39:32];
    
    reg                     ibuf_start_r;
    reg     [4      -1 : 0] ibuf_conf_mode_r;
    reg     [8      -1 : 0] ibuf_conf_idx_num_r;
    reg     [PE_NUM -1 : 0] ibuf_conf_mask_r;
    
    reg                     dbuf_start_r;
    reg     [4      -1 : 0] dbuf_conf_mode_r;
    reg     [4      -1 : 0] dbuf_conf_ch_num_r;
    reg     [4      -1 : 0] dbuf_conf_row_num_r;
    reg     [4      -1 : 0] dbuf_conf_pix_num_r;
    reg     [PE_NUM -1 : 0] dbuf_conf_mask_r;
    
    reg                     pbuf_start_r;
    reg     [8      -1 : 0] pbuf_conf_trans_num_r;
    reg     [4      -1 : 0] pbuf_conf_mode_r;     
    reg     [4      -1 : 0] pbuf_conf_ch_num_r;   
    reg     [4      -1 : 0] pbuf_conf_pix_num_r;  
    reg     [2      -1 : 0] pbuf_conf_row_num_r;  
    reg                     pbuf_conf_depool_r;
    reg     [PE_NUM -1 : 0] pbuf_conf_mask_r;

    reg                     abuf_start_r;
    reg     [2      -1 : 0] abuf_conf_trans_type_r;
    reg     [8      -1 : 0] abuf_conf_trans_num_r;
    reg     [PE_NUM -1 : 0] abuf_conf_mask_r;
    
    reg                         ddr1_start_r;
    reg     [DDR_ADDR_W -1 : 0] ddr1_st_addr_r;
    reg     [BURST_W    -1 : 0] ddr1_burst_r;
    reg     [DDR_ADDR_W -1 : 0] ddr1_step_r;
    reg     [BURST_W    -1 : 0] ddr1_burst_num_r;
    
    reg                         ddr2_start_r;
    reg     [DDR_ADDR_W -1 : 0] ddr2_st_addr_r;
    reg     [BURST_W    -1 : 0] ddr2_burst_r;
    reg     [DDR_ADDR_W -1 : 0] ddr2_step_r;
    reg     [BURST_W    -1 : 0] ddr2_burst_num_r;
    
    // i buffer configuration
    always @ (posedge clk) begin
        if (rst) begin
            ibuf_start_r        <= 1'b0;
            ibuf_conf_mode_r    <= 4'b0000;
            ibuf_conf_idx_num_r <= 0;
            ibuf_conf_mask_r    <= '0;
        end
        else if (valid && ready && opcode == RD_OP_I) begin
            ibuf_start_r        <= 1'b1;
            ibuf_conf_mode_r    <= layer_type;
            ibuf_conf_idx_num_r <= size;
            ibuf_conf_mask_r    <= layer_type[0] ? (1 << buf_id) : (15 << (buf_id << 2));
        end    
    end
    
    // d buffer configuration
    always @ (posedge clk) begin
        if (rst) begin
            dbuf_start_r        <= 1'b0;
            dbuf_conf_mode_r    <= 4'b0000;
            dbuf_conf_ch_num_r  <= 0;
            dbuf_conf_row_num_r <= 0;
            dbuf_conf_pix_num_r <= 0;
            dbuf_conf_mask_r    <= '0;
        end
        else if (valid && ready && (opcode == RD_OP_D || opcode == RD_OP_GD) begin
            dbuf_start_r        <= 1'b1;
            dbuf_conf_mode_r    <= 4'b0000;
            dbuf_conf_ch_num_r  <= 0;
            dbuf_conf_row_num_r <= 0;
            dbuf_conf_pix_num_r <= 0;
            dbuf_conf_mask_r    <= '0;
        end
    end
    
    
    
endmodule