import  INS_CONST::*;
import  GLOBAL_PARAM::*;

module pe2ddr_config#(
    parameter   PE_NUM  = 32,
    
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
    
    
    
endmodule