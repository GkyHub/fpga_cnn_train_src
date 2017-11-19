module pe_config#(
    parameter   PE_NUM  = 32
    )(
    input   clk,
    input   rst,
    
    input   [INST_W -1 : 0] ins,
    output                  ins_ready,
    input                   ins_valid,
    
    
    )