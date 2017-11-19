import  INS_CONST::INST_W;
import  GLOBAL_PARAM::*;

module pe2ddr#(
    parameter   BUF_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    input   [4      -1 : 0] layer_type,
    input                   pooling,
    input                   relu,
    
    input   [INST_W -1 : 0] ins,
    output                  ins_ready,
    input                   ins_valid,
    
    output  [bw(PE_NUM / 4) -1 : 0] rd_sel,
    
    output  [ADDR_W         -1 : 0] abuf_rd_addr,
    input   [3 : 0][BATCH * RES_W  -1 : 0] abuf_rd_data,
    
    input   [ADDR_W -1 : 0] bbuf_rd_addr,
    output  [RES_W  -1 : 0] bbuf_rd_data,
    
    output  [DDR_W      -1 : 0] ddr1_data,
    output                      ddr1_valid,
    input                       ddr1_ready,
                                    
    output  [DDR_ADDR_W -1 : 0] ddr1_addr,
    output  [BURST_W    -1 : 0] ddr1_size,
    output                      ddr1_addr_valid,
    input                       ddr1_addr_ready,
                                    
    output  [DDR_W      -1 : 0] ddr2_data,
    output                      ddr2_valid,
    input                       ddr2_ready,
                                    
    output  [DDR_ADDR_W -1 : 0] ddr2_addr,
    output  [BURST_W    -1 : 0] ddr2_size,
    output                      ddr2_addr_valid,
    input                       ddr2_addr_ready
    );

//=============================================================================
// datapath
//=============================================================================
    
    
//=============================================================================
// DDR addr generators
//=============================================================================
    
    wire                        ddr1_start;
    wire                        ddr1_done;
    wire    [DDR_ADDR_W -1 : 0] ddr1_st_addr;
    wire    [BURST_W    -1 : 0] ddr1_burst;
    wire    [DDR_ADDR_W -1 : 0] ddr1_step;
    wire    [BURST_W    -1 : 0] ddr1_burst_num;
    
    wire                        ddr2_start;
    wire                        ddr2_done;
    wire    [DDR_ADDR_W -1 : 0] ddr2_st_addr;
    wire    [BURST_W    -1 : 0] ddr2_burst;
    wire    [DDR_ADDR_W -1 : 0] ddr2_step;
    wire    [BURST_W    -1 : 0] ddr2_burst_num;
    
    ddr_addr_gen#(
        .DDR_ADDR_W (DDR_ADDR_W ),
        .BURST_W    (BURST_W    )
    ) ddr1_addr_gen_inst (
        .clk            (clk            ),
        .rst            (rst            ),
        
        .start          (ddr1_start     ),
        .done           (ddr1_done      ),
        .st_addr        (ddr1_st_addr   ),
        .burst          (ddr1_burst     ),
        .step           (ddr1_step      ),
        .burst_num      (ddr1_burst_num ),
    
        .ddr_addr       (ddr1_addr      ),
        .ddr_size       (ddr1_size      ),
        .ddr_addr_valid (ddr1_addr_valid),
        .ddr_addr_ready (ddr1_addr_ready)
    );
    
    ddr_addr_gen#(
        .DDR_ADDR_W (DDR_ADDR_W ),
        .BURST_W    (BURST_W    )
    ) ddr2_addr_gen_inst (
        .clk            (clk            ),
        .rst            (rst            ),
        
        .start          (ddr2_start     ),
        .done           (ddr2_done      ),
        .st_addr        (ddr2_st_addr   ),
        .burst          (ddr2_burst     ),
        .step           (ddr2_step      ),
        .burst_num      (ddr2_burst_num ),
    
        .ddr_addr       (ddr2_addr      ),
        .ddr_size       (ddr2_size      ),
        .ddr_addr_valid (ddr2_addr_valid),
        .ddr_addr_ready (ddr2_addr_ready)
    );
    
    
endmodule