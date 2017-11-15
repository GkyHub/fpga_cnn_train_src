package INS_CONST;
    
    localparam INST_W       = 64;
    
    // configuration instruction
    // [63:62] instruction type: 2'b11
    // [61:58] layer type
    // [57:56] null
    // [55:52] input channel segment
    // [51:48] output channel segment
    // [47:40] input image width (for data arrangment in ddr)
    // [39:32] output image width (for data arrangment in ddr)
    // [31: 0] null
    
    // layer type
    // [3 : 3] null
    // [2 : 1] phase
    // [0 : 0] type
    localparam LT_F_CONV    = 4'b0000;
    localparam LT_F_FC      = 4'b0001;
    localparam LT_B_CONV    = 4'b0010;
    localparam LT_B_FC      = 4'b0011;
    localparam LT_U_CONV    = 4'b0100;
    localparam LT_U_FC      = 4'b0101;
    
    // load instruction opcode
    // [63:62] instruction type: 2'b00
    // [61:58] opcode
    // [57:52] buf_id
    // [51:40] null
    // [39:32] size
    // [31: 0] ddr address
    localparam RD_OP_D      = 4'b0000;  // neuron
    localparam RD_OP_G      = 4'b0001;  // neuron gradient
    localparam RD_OP_DW     = 4'b0100;  // weights MSB
    localparam RD_OP_DB     = 4'b0101;  // bias MSB
    localparam RD_OP_TW     = 4'b0110;  // weights LSB
    localparam RD_OP_TB     = 4'b0111;  // bias LSB
    localparam RD_OP_I      = 4'b1000;  // index
    
    // save instruction opcode
    localparam WR_OP_D      = 4'b0000;
    localparam WR_OP_W      = 4'b0010;
    localparam WR_OP_B      = 4'b0011;
    localparam WR_OP_TW     = 4'b0100;
    localparam WR_OP_TB     = 4'b0101;
    
endpackage