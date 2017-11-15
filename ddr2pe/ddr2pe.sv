import GLOBAL_PARAM::DDR_W;
import GLOBAL_PARAM::DATA_W;
import GLOBAL_PARAM::BATCH;
import GLOBAL_PARAM::DDR_ADDR_W;
import GLOBAL_PARAM::BURST_W;
import GLOBAL_PARAM::bw;

module ddr2pe#(
    parameter   BUF_DEPTH   = 256,
    parameter   IDX_DEPTH   = 256,
    parameter   PE_NUM      = 32
    )(
    input   clk,
    input   rst,
    
    input   [DDR_W      -1 : 0] ddr1_data,
    input                       ddr1_valid,
    output                      ddr1_ready,
    
    output  [DDR_ADDR_W -1 : 0] ddr1_addr,
    output  [BURST_W    -1 : 0] ddr1_size,
    output                      ddr1_addr_valid,
    input                       ddr1_addr_ready
    
    input   [DDR_W      -1 : 0] ddr2_data,
    input                       ddr2_valid,
    output                      ddr2_ready,
    
    output  [DDR_ADDR_W -1 : 0] ddr2_addr,
    output  [BURST_W    -1 : 0] ddr2_size,
    output                      ddr2_addr_valid,
    input                       ddr2_addr_ready
    
    output  [PE_NUM / 4     -1 : 0] wr_sel,
    
    output  [IDX_W*2        -1 : 0] idx_wr_data,
    output  [bw(IDX_DEPTH)  -1 : 0] idx_wr_addr,
    output  [PE_NUM         -1 : 0] idx_wr_en,
    
    output         [bw(BUF_DEPTH)  -1 : 0] dbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data,
    output  [PE_NUM -1 : 0]                dbuf_wr_en,
    
    output  [3 : 0][bw(BUF_DEPTH)  -1 : 0] pbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    output  [PE_NUM -1 : 0]                pbuf_wr_en,
    
    output                  bbuf_accum_en,
    output                  bbuf_accum_new,
    output  [ADDR_W -1 : 0] bbuf_accum_addr,
    output  [RES_W  -1 : 0] bbuf_accum_data,
    
    // accum and bias buf port
    output  [ADDR_W         -1 : 0] abuf_wr_addr,
    output  [BATCH * DATA_W -1 : 0] abuf_wr_data,
    output  [PE_NUM         -1 : 0] abuf_wr_data_en,
    output  [BATCH * TAIL_W -1 : 0] abuf_wr_tail,
    output  [PE_NUM         -1 : 0] abuf_wr_tail_en,
    
    output  [ADDR_W -1 : 0] bbuf_wr_addr,
    output  [DATA_W -1 : 0] bbuf_wr_data,
    output                  bbuf_wr_data_en,
    output  [TAIL_W -1 : 0] bbuf_wr_tail,
    output                  bbuf_wr_tail_en
    );
    
    wire                    ibuf_start;
    wire                    ibuf_done;
    wire    [4      -1 : 0] ibuf_conf_mode;
    wire    [8      -1 : 0] ibuf_conf_idx_num;
    wire    [PE_NUM -1 : 0] ibuf_conf_mask;
    
    wire                    dbuf_start;
    wire                    dbuf_done;
    wire    [4      -1 : 0] dbuf_conf_mode;
    wire    [4      -1 : 0] dbuf_conf_ch_num;
    wire    [4      -1 : 0] dbuf_conf_row_num;
    wire    [4      -1 : 0] dbuf_conf_pix_num;
    wire    [PE_NUM -1 : 0] dbuf_conf_mask;
    wire                    dbuf_conf_depool;
    
    wire                    pbuf_start;
    wire                    pbuf_done;
    wire    [8      -1 : 0] pbuf_conf_trans_num;
    wire    [4      -1 : 0] pbuf_conf_mode;     
    wire    [4      -1 : 0] pbuf_conf_ch_num;   
    wire    [4      -1 : 0] pbuf_conf_pix_num;  
    wire    [2      -1 : 0] pbuf_conf_row_num;  
    wire                    pbuf_conf_depool;
    wire    [PE_NUM -1 : 0] pbuf_conf_mask;

    wire                    abuf_start;
    wire                    abuf_done;
    wire    [2      -1 : 0] abuf_conf_trans_type;
    wire    [8      -1 : 0] abuf_conf_trans_num;
    wire    [PE_NUM -1 : 0] abuf_conf_mask;
    
    wire            ibuf_ddr2_ready;
    wire            pbuf_ddr1_ready;
    wire            pbuf_ddr2_ready;
    wire            abuf_ddr2_ready;
    
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
    
    ddr2ibuf#(
        .IDX_DEPTH  (IDX_DEPTH  )
    ) ddr2ibuf_inst (
        .clk            (clk                ),
        .rst            (rst                ),
    
        .start          (ibuf_start         ),
        .done           (ibuf_done          ),
        .conf_mode      (ibuf_conf_mode     ),
        .conf_idx_num   (ibuf_conf_idx_num  ),
        .conf_mask      (ibuf_conf_mask     ),
    
        .ddr_data       (ddr2_data          ),
        .ddr_valid      (ddr2_valid         ),
        .ddr_ready      (ibuf_ddr2_ready    ),
    
        .idx_wr_data    (idx_wr_data        ),
        .idx_wr_addr    (idx_wr_addr        ),
        .idx_wr_en      (idx_wr_en          )
    );
    
    ddr2dbuf#(
        .BUF_DEPTH  (BUF_DEPTH  )
    ) ddr2dbuf_inst (
        .clk            (clk                ),
        .rst            (rst                ),

        .start          (dbuf_start         ),
        .done           (dbuf_done          ),
        .conf_mode      (dbuf_conf_mode     ),
        .conf_ch_num    (dbuf_conf_ch_num   ),
        .conf_row_num   (dbuf_conf_row_num  ),
        .conf_pix_num   (dbuf_conf_pix_num  ),
        .conf_mask      (dbuf_conf_mask     ),
        .conf_depool    (dbuf_conf_depool   ),
    
        .ddr_data       (ddr1_data          ),
        .ddr_valid      (ddr1_valid         ),
        
        .dbuf_wr_addr   (dbuf_wr_addr       ),
        .dbuf_wr_data   (dbuf_wr_data       ),
        .dbuf_wr_en     (dbuf_wr_en         )
    );
    
    ddr2pbuf#(
        .BUF_DEPTH  (BUF_DEPTH  ),
    ) ddr2pbuf_inst (
        .clk            (clk                ),
        .rst            (rst                ),
    
        .start          (pbuf_start         ),
        .done           (pbuf_done          ),
        .conf_trans_num (pbuf_conf_trans_num),
        .conf_mode      (pbuf_conf_mode     ),
        .conf_ch_num    (pbuf_conf_ch_num   ),
        .conf_pix_num   (pbuf_conf_pix_num  ),
        .conf_row_num   (pbuf_conf_row_num  ),
        .conf_depool    (pbuf_conf_depool   ),
        .conf_mask      (pbuf_conf_mask     ),
    
        .ddr1_data      (ddr1_data          ),
        .ddr1_valid     (ddr1_valid         ),
        .ddr1_ready     (pbuf_ddr1_ready    ),
        
        .ddr2_data      (ddr2_data          ),
        .ddr2_valid     (ddr2_valid         ),
        .ddr2_ready     (pbuf_ddr2_ready    ),
        
        .pbuf_wr_addr   (pbuf_wr_addr       ),
        .pbuf_wr_data   (pbuf_wr_data       ),
        .pbuf_wr_en     (pbuf_wr_en         ),
    
        .bbuf_accum_en  (bbuf_accum_en      ),
        .bbuf_accum_new (bbuf_accum_new     ),
        .bbuf_accum_addr(bbuf_accum_addr    ),
        .bbuf_accum_data(bbuf_accum_data    )
    );
    
    ddr2abuf#(
        .BUF_DEPTH  (BUF_DEPTH  ),
        .PE_NUM     (PE_NUM     )
    ) ddr2abuf_inst (
        .clk            (clk                    ),
        .rst            (rst                    ),
    
        .start          (abuf_start             ),
        .done           (abuf_done              ),
        .conf_trans_type(abuf_conf_trans_type   ),
        .conf_trans_num (abuf_conf_trans_num    ),
    
        // ddr data stream port
        .ddr_data       (ddr2_data              ),
        .ddr_valid      (ddr2_valid             ),
        .ddr_ready      (abuf_ddr2_ready        ),
    
        // accum and bias buf port
        .abuf_wr_addr   (abuf_wr_addr           ),
        .abuf_wr_data   (abuf_wr_data           ),
        .abuf_wr_data_en(abuf_wr_data_en        ),
        .abuf_wr_tail   (abuf_wr_tail           ),
        .abuf_wr_tail_en(abuf_wr_tail_en        ),
    
        .bbuf_wr_addr   (bbuf_wr_addr           ),
        .bbuf_wr_data   (bbuf_wr_data           ),
        .bbuf_wr_data_en(bbuf_wr_data_en        ),
        .bbuf_wr_tail   (bbuf_wr_tail           ),
        .bbuf_wr_tail_en(bbuf_wr_tail_en        )
    );
    
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