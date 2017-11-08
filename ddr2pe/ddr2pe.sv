import GLOBAL_PARAM::DDR_W;
import GLOBAL_PARAM::DATA_W;
import GLOBAL_PARAM::BATCH;
import GLOBAL_PARAM::bw;

module ddr2pe#(
    parameter   BUF_DEPTH   = 256,
    parameter   IDX_DEPTH   = 256
    )(
    input   clk,
    input   rst,
    
    input   [DDR_W  -1 : 0] ddr1_data,
    input                   ddr1_valid,
    output                  ddr1_ready,
    
    input   [DDR_W  -1 : 0] ddr2_data,
    input                   ddr2_valid,
    output                  ddr2_ready,
    
    output  [PE_NUM / 4     -1 : 0] wr_sel,
    
    output  [IDX_W*2        -1 : 0] idx_wr_data,
    output  [bw(IDX_DEPTH)  -1 : 0] idx_wr_addr,
    output  [4              -1 : 0] idx_wr_en,
    
    output         [bw(BUF_DEPTH)  -1 : 0] dbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data,
    output  [3 : 0]                        dbuf_wr_en,
    
    output  [3 : 0][bw(BUF_DEPTH)  -1 : 0] pbuf_wr_addr,
    output  [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data,
    output  [3 : 0]                        pbuf_wr_en,
    
    input                   bbuf_accum_en,
    input                   bbuf_accum_new,
    input   [ADDR_W -1 : 0] bbuf_accum_addr,
    input   [RES_W  -1 : 0] bbuf_accum_data,
    );
    
    ddr2ibuf#(
        .IDX_DEPTH  (IDX_DEPTH  )
    ) ddr2ibuf_inst (
        .clk            (clk        ),
        .rst            (rst        ),
    
        .start          (),
        .done           (),
        .conf_mode      (),
        .conf_idx_num   (),
    
        .ddr_data       (ddr2_data  ),
        .ddr_valid      (ddr2_valid ),
        .ddr_ready      (),
    
        .idx_wr_data    (idx_wr_data),
        .idx_wr_addr    (idx_wr_addr),
        .idx_wr_en      (idx_wr_en  )
    );
    
    ddr2dbuf#(
        .BUF_DEPTH  (BUF_DEPTH  )
    ) ddr2dbuf_inst (
        .clk            (clk            ),
        .rst            (rst            ),

        .start          (),
        .done           (),
        .conf_mode      (),
        .conf_ch_num    (),
        .conf_row_num   (),
        .conf_pix_num   (),
    
        .ddr_data       (ddr1_data      ),
        .ddr_valid      (ddr1_valid     ),
    
        .dbuf_wr_addr   (dbuf_wr_addr   ),
        .dbuf_wr_data   (dbuf_wr_data   ),
        .dbuf_wr_en     (dbuf_wr_en     )
    );
    
    ddr2pbuf#(
        .BUF_DEPTH  (BUF_DEPTH  ),
    ) ddr2pe_inst (
        .clk    (clk    ),
        .rst    (rst    ),
    
        .start          (),
        .done           (),
        .conf_grp_sel   (),
        .conf_trans_num (),
        .conf_mode      (),
        .conf_ch_num    (),
        .conf_pix_num   (),
        .conf_row_num   (),
        .conf_depool    (),
    
        .ddr1_data      (ddr1_data      ),
        .ddr1_valid     (ddr1_valid     ),
        .ddr1_ready     (ddr1_ready     ),
    
        .ddr2_data      (ddr2_data      ),
        .ddr2_valid     (ddr2_valid     ),
        .ddr2_ready     (ddr2_ready     ),
    
        .pbuf_wr_addr   (pbuf_wr_addr   ),
        .pbuf_wr_data   (pbuf_wr_data   ),
        .pbuf_wr_en     (pbuf_wr_en     ),

        .bbuf_accum_en  (bbuf_accum_en  ),
        .bbuf_accum_new (bbuf_accum_new ),
        .bbuf_accum_addr(bbuf_accum_addr),
        .bbuf_accum_data(bbuf_accum_data),
    );
    
endmodule