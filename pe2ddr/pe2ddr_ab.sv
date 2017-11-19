import  GLOBAL_PARAM::DDR_W;
import  GLOBAL_PARAM::RES_W;
import  GLOBAL_PARAM::DATA_W;

module pe2ddr_ab#(
    parameter   BUF_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    input           start,
    output          done,
    input   [3 : 0] conf_layer_type,
    input   [1 : 0] conf_trans_type,
    input   [7 : 0] conf_trans_num,
    input   [1 : 0] conf_grp_sel,
    
    output  [ADDR_W         -1 : 0] abuf_rd_addr,
    input   [3 : 0][BATCH * RES_W  -1 : 0] abuf_rd_data,
    output  abuf_rd_en,
    
    output  [ADDR_W -1 : 0] bbuf_rd_addr,
    input   [RES_W  -1 : 0] bbuf_rd_data,
    output                  bbuf_rd_en,
    
    output  [DDR_W      -1 : 0] ddr2_data,
    output                      ddr2_valid,
    input                       ddr2_ready
    );
    
    localparam TD_RATE = TAIL_W / DATA_W;
    
    assign  abuf_rd_en = ddr2_ready;
    assign  bbuf_rd_en = ddr2_ready;
    
//=============================================================================
// abuf_rd_addr
//=============================================================================
    
    reg     [ADDR_W -1 : 0] abuf_addr_r;
    reg     [ADDR_W -1 : 0] abuf_data_addr_r;
    reg     [ADDR_W -1 : 0] abuf_tail_addr_r;
    reg     [3      -1 : 0] abuf_pack_cnt_r;
    
    reg     abuf_rd_valid_r;
    
    always @ (posedge clk) begin
        if (start) begin
            abuf_data_addr_r <= 0;
        end
        else if (ddr2_ready) begin
            abuf_data_addr_r <= abuf_data_addr_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (start) begin
            abuf_tail_addr_r<= 0;
            abuf_pack_cnt_r <= 0; 
        end
        else if (ddr2_ready) begin
            abuf_tail_addr_r<= (abuf_pack_cnt_r == TD_RATE - 1) ? abuf_tail_addr_r + 1 : abuf_tail_addr_r;
            abuf_pack_cnt_r <= (abuf_pack_cnt_r == TD_RATE - 1) ? 0 : abuf_pack_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (ddr2_ready) begin
            if (conf_trans_type[0]) begin
                abuf_addr_r <= abuf_data_addr_r;
            end
            else begin
                abuf_addr_r <= abuf_tail_addr_r;
            end
        end
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            abuf_rd_valid_r <= 1'b0;
        end
        else begin
        
        end
    end
    
//=============================================================================
// bbuf_rd_addr
//=============================================================================
    
    localparam  TPACK_SIZE = DDR_W / TAIL_W;
    localparam  DPACK_SIZE = DDR_W / DATA_W;
    
    reg     [6      -1 : 0] bbuf_tail_cnt_r;
    reg     [6      -1 : 0] bbuf_data_cnt_r;
    reg     [ADDR_W -1 : 0] bbuf_addr_r; 
    
    always @ (posedge clk) begin
        if (start) begin
            bbuf_tail_cnt_r <= 0;
        end
        else if (ddr2_ready) begin
            bbuf_tail_cnt_r <= (bbuf_tail_cnt_r == TPACK_SIZE - 1) ? 0 : bbuf_tail_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (start) begin
            bbuf_data_cnt_r <= 0;
        end
        else if (ddr2_ready) begin
            bbuf_data_cnt_r <= (bbuf_data_cnt_r == DPACK_SIZE - 1) ? 0 : bbuf_data_cnt_r + 1;
        end
    end
    
    always @ (posedge clk) begin
        if (start) begin
            bbuf_addr_r<= 0;
        end
        else if (ddr2_ready) begin
            bbuf_addr_r<= (bbuf_addr_r == conf_trans_size) ? bbuf_addr_r : (bbuf_addr_r + 1);
        end
    end
    
    assign  bbuf_rd_addr = bbuf_addr_r;

//=============================================================================
// data mux
//=============================================================================
    
    wire    [BATCH -1 : 0][RES_W -1 : 0] abuf_res_arr;
    
    genvar i;
    generate
        for (i = 0; i < BATCH; i = i + 1) begin: UNIT
        
            signed wire [3 : 0][RES_W  -1 : 0] unit_res = abuf_rd_data[3 : 0][i];
            
            signed reg  [1 : 0][RES_W  -1 : 0] sum_r;
            signed reg  [RES_W  -1 : 0] res_r;
            
            always @ (posedge clk) begin
                if (ddr2_ready) begin
                    if (!conf_layer_type[0]) begin
                        sum_r[0] <= unit_res[0] + unit_res[1];
                        sum_r[1] <= unit_res[2] + unit_res[3];
                        res_r    <= sum_r[0] + sum_r[1];
                    end
                    else begin
                        sum_r[0] <= unit_res[conf_grp_sel];
                        res_r    <= sum_r[0];
                    end
                end
            end
            
            assign  abuf_res_arr[i] = res_r;
        end
    endgenerate
    
    wire    [6      -1 : 0] bbuf_tail_cnt_d;
    wire    [6      -1 : 0] bbuf_data_cnt_d;
    
    wire    [DATA_W -1 : 0] bbuf_data;
    wire    [TAIL_W -1 : 0] bbuf_tail;
    
    reg     [TPACK_SIZE-1 : 0][TAIL_W -1 : 0] bbuf_tail_arr_r;
    reg     [DPACK_SIZE-1 : 0][DATA_W -1 : 0] bbuf_data_arr_r;
    
    assign  {bbuf_data, bbuf_tail} = bbuf_rd_data;
    
    PipeEn#(.DW(6), .L(4)) bbuf_tail_cnt_pipe (.clk(clk), .clk_en(ddr2_ready),
        .s(bbuf_tail_cnt_r), .d(bbuf_tail_cnt_d));
        
    PipeEn#(.DW(6), .L(4)) bbuf_data_cnt_pipe (.clk(clk), .clk_en(ddr2_ready),
        .s(bbuf_data_cnt_r), .d(bbuf_data_cnt_d));
        
    
    always @ (posedge clk) begin
        if (ddr2_ready) begin
            bbuf_tail_arr_r[bbuf_tail_cnt_d] <= bbuf_tail;
            bbuf_data_arr_r[bbuf_data_cnt_d] <= bbuf_data;
        end
    end
    
    reg     [DDR_W  -1 : 0] ddr2_data_r;
    assign  ddr2_data = ddr2_data_r;
    
    always @ (posedge clk) begin
        if (ddr2_ready) begin
            case(conf_trans_type)
            2'b00: ddr2_data_r <= abuf_res_arr;
            2'b01: ddr2_data_r <= abuf_res_arr;
            2'b10: ddr2_data_r <= bbuf_data_arr_r;
            2'b11: ddr2_data_r <= bbuf_tail_arr_r;
            endcase
        end
    end
    
endmodule