import  GLOBAL_PARAM::DATA_W;
import  GLOBAL_PARAM::BATCH;
import  GLOBAL_PARAM::RES_W;
import  GLOBAL_PARAM::IDX_W;
import  GLOBAL_PARAM::bw;

module pe_array#(
    parameter   PE_NUM      = 32,
    parameter   BUF_DEPTH   = 256,
    parameter   IDX_DEPTH   = 256,
    parameter   ADDR_W      = bw(BUF_DEPTH)
    )(
    input   clk,
    input   rst,
    
    // PE control interface
    input   [PE_NUM -1 : 0] switch_d,   // switch the ping pong buffer data
    input   [PE_NUM -1 : 0] switch_p,   // switch the ping pong buffer param
    input   [PE_NUM -1 : 0] switch_i,   // switch the ping pong buffer idx
    input   [PE_NUM -1 : 0] switch_a,   // switch the ping pong buffer accum
    input                   switch_b,
    
    input   [PE_NUM -1 : 0] start,
    output  [PE_NUM -1 : 0] done,
    input   [3      -1 : 0] mode,
    input   [8      -1 : 0] idx_cnt,  
    input   [8      -1 : 0] trip_cnt, 
    input                   is_new,
    input   [4      -1 : 0] pad_code, 
    input                   cut_y,
    
    input   [bw(PE_NUM / 4) -1 : 0] rd_sel,
    
    input   [IDX_W*2        -1 : 0] idx_wr_data,
    input   [bw(IDX_DEPTH)  -1 : 0] idx_wr_addr,
    input   [PE_NUM         -1 : 0] idx_wr_en,
    
    input          [ADDR_W         -1 : 0] dbuf_wr_addr,
    input   [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data,
    input   [PE_NUM -1 : 0]                dbuf_wr_en,
    
    input   [3 : 0][ADDR_W         -1 : 0] pbuf_wr_addr,
    input   [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    input   [PE_NUM -1 : 0]                pbuf_wr_en,
    
    input   [3 : 0][ADDR_W         -1 : 0] abuf_wr_addr,
    input   [3 : 0][BATCH * DATA_W -1 : 0] abuf_wr_data,
    input   [PE_NUM -1 : 0]                abuf_wr_data_en,
    input   [3 : 0][BATCH * TAIL_W -1 : 0] abuf_wr_tail,
    input   [PE_NUM -1 : 0]                abuf_wr_tail_en,     
    input          [ADDR_W         -1 : 0] abuf_rd_addr,
    output  [3 : 0][BATCH * RES_W  -1 : 0] abuf_rd_data,
    
    input                   bbuf_acc_en,
    input                   bbuf_acc_new,
    input   [ADDR_W -1 : 0] bbuf_acc_addr,
    input   [RES_W  -1 : 0] bbuf_acc_data,
    
    input   [ADDR_W -1 : 0] bbuf_wr_addr,
    input   [DATA_W -1 : 0] bbuf_wr_data,
    input                   bbuf_wr_data_en,
    input   [TAIL_W -1 : 0] bbuf_wr_tail,
    input                   bbuf_wr_tail_en,     
    input   [ADDR_W -1 : 0] bbuf_rd_addr,
    output  [RES_W  -1 : 0] bbuf_rd_data
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
                    .idx_wr_en      (idx_wr_en[i*4+j]           ),
                
                    .dbuf_wr_addr   (dbuf_wr_addr               ),
                    .dbuf_wr_data   (dbuf_wr_data[j]            ),
                    .dbuf_wr_en     (dbuf_wr_en[i*4+j]          ),
                
                    .pbuf_wr_addr   (pbuf_wr_addr[j]            ),
                    .pbuf_wr_data   (pbuf_wr_data[j]            ),
                    .pbuf_wr_en     (pbuf_wr_en[i*4+j]          ),
                
                    .abuf_wr_addr   (abuf_wr_addr[j]            ),
                    .abuf_wr_data   (abuf_wr_data[j]            ),
                    .abuf_wr_data_en(abuf_wr_data_en[i*4+j]     ),
                    .abuf_wr_tail   (abuf_wr_tail[j]            ),
                    .abuf_wr_tail_en(abuf_wr_tail_en[i*4+j]     ),
                    .abuf_rd_addr   (abuf_rd_addr               ),
                    .abuf_rd_data   (grp_abuf_rd_data[i][j]     )
                );
            end
        end
    endgenerate

    accum_buf#(
        .DEPTH      (BUF_DEPTH      ),
        .BATCH      (1              ),
        .RAM_TYPE   ("distributed"  )
    ) bias_buf (
        .clk        (clk            ),
        .rst        (rst            ),
        
        .switch     (switch_b       ),
    
        .accum_en   (bbuf_acc_en    ),
        .accum_new  (bbuf_acc_new   ),
        .accum_addr (bbuf_acc_addr  ),
        .accum_data (bbuf_acc_data  ),
    
        .wr_addr    (bbuf_wr_addr   ),
        .wr_data    (bbuf_wr_data   ),
        .wr_data_en (bbuf_wr_data_en),
        .wr_tail    (bbuf_wr_tail   ),
        .wr_tail_en (bbuf_wr_tail_en),

        .rd_addr    (bbuf_rd_addr   ),
        .rd_data    (bbuf_rd_data   )
    );
    
endmodule