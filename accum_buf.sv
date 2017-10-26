import GLOBAL_PARAM::bw;
import GLOBAL_PARAM::RES_W;

module accum_buf#(
    parameter   DEPTH   = 256,
    parameter   ADDR_W  = bw(DEPTH),    // please do not change this parameter
    parameter   BATCH   = 32
    )(
    input       clk,
    input       rst,
    
    input       switch,
    
    // accumulation port
    input   [BATCH  -1 : 0]                 accum_en,
    input   [BATCH  -1 : 0]                 accum_new,
    input   [ADDR_W -1 : 0]                 accum_addr,
    input   [BATCH  -1 : 0][RES_W   -1 : 0] accum_data,
    
    // load intermediate result port
    input   [ADDR_W -1 : 0]                 ld_wr_addr,
    input   [BATCH  -1 : 0][RES_W   -1 : 0] ld_wr_data,
    input                                   ld_wr_en,
    
    // store result port
    input   [ADDR_W -1 : 0]                 sv_rd_addr,
    output  [BATCH  -1 : 0][RES_W   -1 : 0] sv_rd_data
    );
    
    // address and enable signal delay to sync with ram read delay
    wire    [5  -1 : 0][ADDR_W  -1 : 0] accum_addr_d;
    wire    [5  -1 : 0][BATCH   -1 : 0] accum_en_d;
    wire    [4  -1 : 0][BATCH   -1 : 0] accum_new_d;
    
    Q#(.DW(ADDR_W), .L(5)) accum_addr_q (.*, .s(accum_addr), .d(accum_addr_d));
    RQ#(.DW(BATCH), .L(5)) accum_en_q   (.*, .s(accum_en  ), .d(accum_en_d  ));
    RQ#(.DW(BATCH), .L(4)) accum_new_q  (.*, .s(accum_new ), .d(accum_new_d ));
    
    reg     [BATCH  -1 : 0][RES_W   -1 : 0] accum_res_r;
    wire    [BATCH  -1 : 0][RES_W   -1 : 0] accum_rd_data;
    
    genvar i;
    generate
        for (i = 0; i < BATCH; i = i + 1) begin: ACC_ARRAY
            
            wire    [RES_W  -1 : 0] op;
            
            assign  op = (accum_addr_d[4] == accum_addr_d[3]) ? accum_res_r[i] : accum_rd_data[i];
            
            
            always @ (posedge clk) begin
                if (accum_en_d[3][i] && !accum_new_d[3][i]) begin
                    accum_res_r[i] <= accum_data[i] + op;
                end
                else begin
                    accum_res_r[i] <= accum_rd_data[i];
                end
            end
            
        
        end: ACC_ARRAY
    endgenerate
    
    dual_port_ping_pong_ram#(
        .DEPTH      (DEPTH          ),
        .WIDTH      (BATCH * RES_W  ),
        .RAM_TYPE   ("block"        )
    ) buffer (
        .clk    (clk    ),
        .rst    (rst    ),
    
        .switch (switch ),
    
        // port A
        .a_wr_addr  (accum_addr_d[4]    ),
        .a_wr_data  (accum_res_r        ),
        .a_wr_en    (accum_en_d[4] != 0 ),    
        .a_rd_addr  (accum_addr         ),
        .a_rd_data  (accum_rd_data      ),
    
        // port B
        .b_wr_addr  (ld_wr_addr ),
        .b_wr_data  (ld_wr_data ),
        .b_wr_en    (ld_wr_en   ),    
        .b_rd_addr  (sv_rd_addr ),
        .b_rd_data  (sv_rd_data )
    );
    
endmodule