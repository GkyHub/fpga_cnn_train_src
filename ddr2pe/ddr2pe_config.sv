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
    
    wire    [3 : 0] opcode  = ins[61:58];
    wire    [5 : 0] buf_id  = ins[57:52];
    wire    [7 : 0] size    = ins[39:32];
    wire    [3 : 0] pix_num = ins[43:40];
    wire    [3 : 0] row_num = ins[47:44];
    wire            depool  = ins[48];
    wire    [31: 0] st_addr = ins[31: 0];
    
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

//=============================================================================
// Configuration Logic
//=============================================================================
    
    // i buffer configuration
    always @ (posedge clk) begin
        if (rst) begin
            ibuf_start_r        <= 1'b0;
            ibuf_conf_mode_r    <= 4'b0000;
            ibuf_conf_idx_num_r <= 0;
            ibuf_conf_mask_r    <= '0;
        end
        else if (ins_valid && ins_ready && opcode == RD_OP_I) begin
            ibuf_start_r        <= 1'b1;
            ibuf_conf_mode_r    <= layer_type;
            ibuf_conf_idx_num_r <= size;
            ibuf_conf_mask_r    <= layer_type[0] ? (1 << buf_id) : (15 << (buf_id << 2));
        end 
        else begin
            ibuf_start_r        <= 1'b0;
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
        else if (ins_valid && ins_ready && (opcode == RD_OP_D || opcode == RD_OP_G) begin
            dbuf_start_r        <= 1'b1;
            dbuf_conf_mode_r    <= layer_type;
            dbuf_conf_ch_num_r  <= size;
            dbuf_conf_row_num_r <= row_num;
            dbuf_conf_pix_num_r <= pix_num;
            dbuf_conf_mask_r    <= '1;
        end
        else begin
            dbuf_start_r        <= 1'b0;
        end
    end
    
    // p buffer configuration
    always @ (posedge clk) begin
        if (rst) begin
            pbuf_start_r            <= 1'b0;
            pbuf_conf_trans_num_r   <= 0;
            pbuf_conf_mode_r        <= 4'b0000;  
            pbuf_conf_ch_num_r      <= 0;
            pbuf_conf_pix_num_r     <= 0;
            pbuf_conf_row_num_r     <= 0;
            pbuf_conf_depool_r      <= 0;
            pbuf_conf_mask_r        <= 0;
        end
        else if (ins_valid && ins_ready && 
            (((opcode == RD_OP_W)  && (layer_type[2:1] == 2'b10)) || 
             ((opcode == RD_OP_DW) && (layer_type[2:1] != 2'b10)))) begin
            pbuf_start_r            <= 1'b1;
            pbuf_conf_trans_num_r   <= size;
            pbuf_conf_mode_r        <= layer_type;  
            pbuf_conf_ch_num_r      <= size;
            pbuf_conf_pix_num_r     <= pix_num;
            pbuf_conf_row_num_r     <= row_num;
            pbuf_conf_depool_r      <= depool;
            pbuf_conf_mask_r        <= layer_type[0] ? (1 << buf_id) : (15 << (buf_id << 2));
        end
        else begin
            pbuf_start_r            <= 1'b0;
        end
    end
    
    // a buffer configuration
    always @ (posedge clk) begin
        if (rst) begin
            abuf_start_r            <= 1'b0;
            abuf_conf_trans_type_r  <= 4'b0000;
            abuf_conf_trans_num_r   <= 0;
            abuf_conf_mask_r        <= '0;
        end
        else if (ins_valid && ins_ready && layer_type[2:1] == 2'b10 &&
            ((opcode == RD_OP_DW) || (opcode == RD_OP_DB) ||
             (opcode == RD_OP_TW) || (opcode == RD_OP_TB)) begin
            abuf_start_r            <= 1'b1;
            abuf_conf_trans_type_r  <= layer_type;
            abuf_conf_trans_num_r   <= size;
            abuf_conf_mask_r        <= layer_type[0] ? (1 << buf_id) : (15 << (buf_id << 2));        
        end
        else begin
            abuf_start_r            <= 1'b0;
        end
    end
    
    // TODO: configuration position
    always @ (posedge clk) begin
        if (rst) begin
            ddr1_start_r    <= 1'b0;
            ddr1_st_addr_r  <= 0;
            ddr1_burst_r    <= 0;
            ddr1_step_r     <= 0;  
            ddr1_burst_num_r<= 0;  
        end
        else if (ins_valid && ins_ready) begin
            ddr1_start_r    <= 1'b0;
            ddr1_st_addr_r  <= st_addr;
            ddr1_burst_r    <= (pix_num << 5);
            ddr1_step_r     <= image_width;  
            ddr1_burst_num_r<= 0;  
        end
        else begin
            ddr1_start_r    <= 1'b0;
        end
    end
    
    // TODO: configuration position
    always @ (posedge clk) begin
        if (rst) begin
            ddr2_start_r    <= 1'b0;
            ddr2_st_addr_r  <= 0;
            ddr2_burst_r    <= 0;
            ddr2_step_r     <= 0;  
            ddr2_burst_num_r<= 0;  
        end
        else if (ins_valid && ins_ready) begin
            ddr2_start_r    <= 1'b0;
            ddr2_st_addr_r  <= st_addr;
            ddr2_burst_r    <= (pix_num << 5);
            ddr2_step_r     <= image_width;  
            ddr2_burst_num_r<= 0;  
        end
        else begin
            ddr2_start_r    <= 1'b0;
        end
    end
    
    assign  ibuf_start          = ibuf_start_r;
    assign  ibuf_conf_mode      = ibuf_conf_mode_r;
    assign  ibuf_conf_idx_num   = ibuf_conf_idx_num_r;
    assign  ibuf_conf_mask      = ibuf_conf_mask_r;

    assign  dbuf_start          = dbuf_start_r;
    assign  dbuf_conf_mode      = dbuf_conf_mode_r;
    assign  dbuf_conf_ch_num    = dbuf_conf_ch_num_r;
    assign  dbuf_conf_row_num   = dbuf_conf_row_num_r;
    assign  dbuf_conf_pix_num   = dbuf_conf_pix_num_r;
    assign  dbuf_conf_mask      = dbuf_conf_mask_r;

    assign  pbuf_start          = pbuf_start_r;
    assign  pbuf_conf_trans_num = pbuf_conf_trans_num_r;
    assign  pbuf_conf_mode      = pbuf_conf_mode_r;     
    assign  pbuf_conf_ch_num    = pbuf_conf_ch_num_r;   
    assign  pbuf_conf_pix_num   = pbuf_conf_pix_num_r;  
    assign  pbuf_conf_row_num   = pbuf_conf_row_num_r;  
    assign  pbuf_conf_depool    = pbuf_conf_depool_r;
    assign  pbuf_conf_mask      = pbuf_conf_mask_r;

    assign  abuf_start          = abuf_start_r;
    assign  abuf_conf_trans_type= abuf_conf_trans_type_r;
    assign  abuf_conf_trans_num = abuf_conf_trans_num_r;
    assign  abuf_conf_mask      = abuf_conf_mask_r;
    
    assign  ddr1_start          = ddr1_start_r;
    assign  ddr1_st_addr        = ddr1_st_addr_r;
    assign  ddr1_burst          = ddr1_burst_r;
    assign  ddr1_step           = ddr1_step_r;
    assign  ddr1_burst_num      = ddr1_burst_num_r;

    assign  ddr2_start          = ddr2_start_r;
    assign  ddr2_st_addr        = ddr2_st_addr_r;
    assign  ddr2_burst          = ddr2_burst_r;
    assign  ddr2_step           = ddr2_step_r;
    assign  ddr2_burst_num      = ddr2_burst_num_r;

//=============================================================================
// Status Logic
//=============================================================================
    
    
endmodule