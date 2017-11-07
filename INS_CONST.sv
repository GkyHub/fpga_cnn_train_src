package INS_CONST;
    
    // layer type
    // [2 : 1][   0]
    // [phase][type]
    localparam LT_F_CONV    = 3'b000;
    localparam LT_F_FC      = 3'b001;
    localparam LT_B_CONV    = 3'b010;
    localparam LT_B_FC      = 3'b011;
    localparam LT_U_CONV    = 3'b100;
    localparam LT_U_FC      = 3'b101;
    
    // load instruction opcode
    localparam RD_OP_D      = 4'b0000;
    localparam RD_OP_P      = 4'b0001;
    localparam RD_OP_GD     = 4'b0010;
    localparam RD_OP_GW     = 4'b0100;
    localparam RD_OP_GB     = 4'b0101;
    localparam RD_OP_TW     = 4'b0110;
    localparam RD_OP_TB     = 4'b0111;
    
    // save instruction opcode
    localparam WR_OP_D      = 4'b0000;
    localparam WR_OP_W      = 4'b0010;
    localparam WR_OP_B      = 4'b0011;
    localparam WR_OP_TW     = 4'b0100;
    localparam WR_OP_TB     = 4'b0101;
    
endpackage