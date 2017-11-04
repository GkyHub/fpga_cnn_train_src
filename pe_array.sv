import  GLOBAL_PARAM::DATA_W;
import  GLOBAL_PARAM::BATCH;
import  GLOBAL_PARAM::RES_W;
import  GLOBAL_PARAM::IDX_W;
import  GLOBAL_PARAM::bw;

module pe_array#(
    parameter   PE_NUM      = 32,
    parameter   BUF_DEPTH   = 256,
    parameter   IDX_DEPTH   = 256
    )(
    input   clk,
    input   rst,
    
    // PE control interface
    input   [PE_NUM -1 : 0] switch_d,   // switch the ping pong buffer data
    input   [PE_NUM -1 : 0] switch_p,   // switch the ping pong buffer param
    input   [PE_NUM -1 : 0] switch_i,   // switch the ping pong buffer idx
    input   [PE_NUM -1 : 0] switch_a,   // switch the ping pong buffer accum
    
    input   [PE_NUM -1 : 0] start,
    output  [PE_NUM -1 : 0] done,
    input   [3      -1 : 0] mode,
    input   [8      -1 : 0] idx_cnt,  
    input   [8      -1 : 0] trip_cnt, 
    input                   is_new,
    input   [4      -1 : 0] pad_code, 
    input                   cut_y,
    
    input   [PE_NUM / 4     -1 : 0] wr_sel,
    input   [bw(PE_NUM / 4) -1 : 0] rd_sel,
    
    input   [IDX_W*2        -1 : 0] idx_wr_data,
    input   [bw(IDX_DEPTH)  -1 : 0] idx_wr_addr,
    input   [4              -1 : 0] idx_wr_en,
    
    input          [bw(BUF_DEPTH)  -1 : 0] dbuf_wr_addr,
    input   [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data,
    input   [3 : 0]                        dbuf_wr_en,
    
    input   [3 : 0][bw(BUF_DEPTH)  -1 : 0] pbuf_wr_addr,
    input   [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    input   [3 : 0]                        pbuf_wr_en,
    
    input   [3 : 0][bw(BUF_DEPTH)  -1 : 0] abuf_wr_addr,
    input   [3 : 0][BATCH * RES_W  -1 : 0] abuf_wr_data,
    input   [3 : 0]                        abuf_wr_en,    
    input          [bw(BUF_DEPTH)  -1 : 0] abuf_rd_addr,
    output  [3 : 0][BATCH * RES_W  -1 : 0] abuf_rd_data
    );
    
    localparam GRP_NUM = PE_NUM / 4;
    
    wire    [GRP_NUM - 1 : 0][3 : 0][BATCH * RES_W - 1 : 0] grp_abuf_rd_data;
    reg     [3 : 0][BATCH * RES_W - 1 : 0] abuf_rd_data_r;
    
    always @ (posedge clk) begin
        abuf_rd_data_r <= grp_abuf_rd_data[rd_sel];
    end
    
    assign  abuf_rd_data = abuf_rd_data_r;
    
    genvar i, j;
    generate
        for (i = 0; i < GRP_NUM; i = i + 1) begin: GROUP
            wire    [1 : 0][1 : 0][DATA_W*BATCH -1 : 0] share_data;
        
            for (j = 0; j < 4; j = j + 1) begin: UNIT
                localparam x = j % 2;
                localparam y = j / 2;
            
                pe#(
                    .GRP_ID_X   (x          ),
                    .GRP_ID_Y   (y          ),
                    .BUF_DEPTH  (BUF_DEPTH  ),
                    .IDX_DEPTH  (IDX_DEPTH  )
                ) pe_inst (
                    .clk        (clk                    ),
                    .rst        (rst                    ),
                
                    .switch_i   (switch_i[i*4+j]  ),
                    .switch_d   (switch_d[i*4+j]  ),
                    .switch_p   (switch_p[i*4+j]  ),
                    .switch_a   (switch_a[i*4+j]  ),
                
                    .start      (start[i*4+j]     ),
                    .done       (done[i*4+j]      ),
                    .mode       (mode                   ),
                    .idx_cnt    (idx_cnt                ),  
                    .trip_cnt   (trip_cnt               ), 
                    .is_new     (is_new                 ),
                    .pad_code   (pad_code               ), 
                    .cut_y      (cut_y                  ),
                    
                    .share_data_in  ({share_data[1-y][1-x],
                                      share_data[1-y][x  ],
                                      share_data[y  ][1-x]} ),
                    .share_data_out (share_data[y][x]       ),
                
                    .idx_wr_data    (idx_wr_data                ),
                    .idx_wr_addr    (idx_wr_addr                ),
                    .idx_wr_en      (idx_wr_en[j] && wr_sel[i]  ),
                
                    .dbuf_wr_addr   (dbuf_wr_addr               ),
                    .dbuf_wr_data   (dbuf_wr_data[j]            ),
                    .dbuf_wr_en     (dbuf_wr_en[j] && wr_sel[i] ),
                
                    .pbuf_wr_addr   (pbuf_wr_addr[j]            ),
                    .pbuf_wr_data   (pbuf_wr_data[j]            ),
                    .pbuf_wr_en     (pbuf_wr_en[j] && wr_sel[i] ),
                
                    .abuf_wr_addr   (abuf_wr_addr[j]            ),
                    .abuf_wr_data   (abuf_wr_data[j]            ),
                    .abuf_wr_en     (abuf_wr_en[j] && wr_sel[i] ),    
                    .abuf_rd_addr   (abuf_rd_addr               ),
                    .abuf_rd_data   (grp_abuf_rd_data[i][j]     )
                );
            end
        end
    endgenerate

    
    
endmodule