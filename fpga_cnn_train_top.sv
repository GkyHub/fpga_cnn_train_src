import  GLOBAL_PARAM::*;
import  INS_CONST::*;

module fpga_cnn_train_top#(
    parameter   PE_NUM  = 32
    )(
    input   clk,
    input   rst,
    
    input                   ins_valid,
    output                  ins_ready,
    input   [INST_W -1 : 0] ins,
    
    input   [DDR_W      -1 : 0] ddr1_in_data,
    input                       ddr1_in_valid,
    output                      ddr1_in_ready,
    
    output  [DDR_ADDR_W -1 : 0] ddr1_in_addr,
    output  [BURST_W    -1 : 0] ddr1_in_size,
    output                      ddr1_in_addr_valid,
    input                       ddr1_in_addr_ready,
    
    input   [DDR_W      -1 : 0] ddr2_in_data,
    input                       ddr2_in_valid,
    output                      ddr2_in_ready,
    
    output  [DDR_ADDR_W -1 : 0] ddr2_in_addr,
    output  [BURST_W    -1 : 0] ddr2_in_size,
    output                      ddr2_in_addr_valid,
    input                       ddr2_in_addr_ready,
    
    input   [DDR_W      -1 : 0] ddr1_out_data,
    input                       ddr1_out_valid,
    output                      ddr1_out_ready,
                                     
    output  [DDR_ADDR_W -1 : 0] ddr1_out_addr,
    output  [BURST_W    -1 : 0] ddr1_out_size,
    output                      ddr1_out_addr_valid,
    input                       ddr1_out_addr_ready,
                                     
    input   [DDR_W      -1 : 0] ddr2_out_data,
    input                       ddr2_out_valid,
    output                      ddr2_out_ready,
                                     
    output  [DDR_ADDR_W -1 : 0] ddr2_out_addr,
    output  [BURST_W    -1 : 0] ddr2_out_size,
    output                      ddr2_out_addr_valid,
    input                       ddr2_out_addr_ready
    );
    
    localparam BUF_DEPTH = 256;
    localparam IDX_DEPTH = 256;
    localparam ADDR_W    = bw(BUF_DEPTH);
    
    wire    [4      -1 : 0] layer_type;
    wire    [8      -1 : 0] image_width;
    wire    [4      -1 : 0] in_ch_seg;
    
    wire                    ddr2pe_ins_valid;
    wire                    ddr2pe_ins_ready;
    wire    [INST_W -1 : 0] ddr2pe_ins;
    
    wire    [IDX_W*2        -1 : 0] idx_wr_data;
    wire    [bw(IDX_DEPTH)  -1 : 0] idx_wr_addr;
    wire    [PE_NUM         -1 : 0] idx_wr_en;

    wire           [ADDR_W         -1 : 0] dbuf_wr_addr;
    wire    [3 : 0][DATA_W * BATCH -1 : 0] dbuf_wr_data;
    wire    [PE_NUM -1 : 0]                dbuf_wr_en;

    wire    [ADDR_W         -1 : 0]        pbuf_wr_addr;
    wire    [3 : 0][DATA_W * BATCH -1 : 0] pbuf_wr_data;
    wire    [PE_NUM -1 : 0]                pbuf_wr_en;

    wire    [ADDR_W         -1 : 0] abuf_wr_addr;
    wire    [BATCH * DATA_W -1 : 0] abuf_wr_data;
    wire    [PE_NUM         -1 : 0] abuf_wr_data_en;
    wire    [BATCH * TAIL_W -1 : 0] abuf_wr_tail;
    wire    [PE_NUM         -1 : 0] abuf_wr_tail_en;
    
    wire                    bbuf_acc_en;
    wire                    bbuf_acc_new;
    wire    [ADDR_W -1 : 0] bbuf_acc_addr;
    wire    [RES_W  -1 : 0] bbuf_acc_data;
 
    wire    [ADDR_W -1 : 0] bbuf_wr_addr;
    wire    [DATA_W -1 : 0] bbuf_wr_data;
    wire                    bbuf_wr_data_en;
    wire    [TAIL_W -1 : 0] bbuf_wr_tail;
    wire                    bbuf_wr_tail_en;
    
    wire           [ADDR_W         -1 : 0] abuf_rd_addr;
    wire    [3 : 0][BATCH * RES_W  -1 : 0] abuf_rd_data;
    
    wire    [ADDR_W -1 : 0] bbuf_rd_addr;
    wire    [RES_W  -1 : 0] bbuf_rd_data;
    
    wire    [PE_NUM -1 : 0] switch_d;
    wire    [PE_NUM -1 : 0] switch_p;
    wire    [PE_NUM -1 : 0] switch_i;
    wire    [PE_NUM -1 : 0] switch_a;
    wire                    switch_b;

    wire    [PE_NUM -1 : 0] start;
    wire    [PE_NUM -1 : 0] done;
    wire    [3      -1 : 0] mode;
    wire    [8      -1 : 0] idx_cnt;  
    wire    [8      -1 : 0] trip_cnt; 
    wire                    is_new;
    wire    [4      -1 : 0] pad_code; 
    wire                    cut_y;

    wire    [bw(PE_NUM / 4) -1 : 0] rd_sel;
 
    ddr2pe#(
        .BUF_DEPTH  (BUF_DEPTH  ),
        .IDX_DEPTH  (IDX_DEPTH  ),
        .PE_NUM     (PE_NUM     )
    ) ddr2pe_inst (
        .clk    (clk    ),
        .rst    (rst    ),
    
        .layer_type     (layer_type         ),
        .image_width    (image_width        ),
        .in_ch_seg      (in_ch_seg          ),
    
        .ins_valid      (ddr2pe_ins_valid   ),
        .ins_ready      (ddr2pe_ins_ready   ),
        .ins            (ddr2pe_ins         ),
    
        .ddr1_data      (ddr1_in_data       ),
        .ddr1_valid     (ddr1_in_valid      ),
        .ddr1_ready     (ddr1_in_ready      ),
                                
        .ddr1_addr      (ddr1_in_addr       ),
        .ddr1_size      (ddr1_in_size       ),
        .ddr1_addr_valid(ddr1_in_addr_valid ),
        .ddr1_addr_ready(ddr1_in_addr_ready ),
                                
        .ddr2_data      (ddr2_in_data       ),
        .ddr2_valid     (ddr2_in_valid      ),
        .ddr2_ready     (ddr2_in_ready      ),
                                
        .ddr2_addr      (ddr2_in_addr       ),
        .ddr2_size      (ddr2_in_size       ),
        .ddr2_addr_valid(ddr2_in_addr_valid ),
        .ddr2_addr_ready(ddr2_in_addr_ready ),
    
        .idx_wr_data    (idx_wr_data        ),
        .idx_wr_addr    (idx_wr_addr        ),
        .idx_wr_en      (idx_wr_en          ),
    
        .dbuf_wr_addr   (dbuf_wr_addr       ),
        .dbuf_wr_data   (dbuf_wr_data       ),
        .dbuf_wr_en     (dbuf_wr_en         ),
    
        .pbuf_wr_addr   (pbuf_wr_addr       ),
        .pbuf_wr_data   (pbuf_wr_data       ),
        .pbuf_wr_en     (pbuf_wr_en         ),
    
        .bbuf_acc_en    (bbuf_acc_en        ),
        .bbuf_acc_new   (bbuf_acc_new       ),
        .bbuf_acc_addr  (bbuf_acc_addr      ),
        .bbuf_acc_data  (bbuf_acc_data      ),
    
        .abuf_wr_addr   (abuf_wr_addr       ),
        .abuf_wr_data   (abuf_wr_data       ),
        .abuf_wr_data_en(abuf_wr_data_en    ),
        .abuf_wr_tail   (abuf_wr_tail       ),
        .abuf_wr_tail_en(abuf_wr_tail_en    ),
    
        .bbuf_wr_addr   (bbuf_wr_addr       ),
        .bbuf_wr_data   (bbuf_wr_data       ),
        .bbuf_wr_data_en(bbuf_wr_data_en    ),
        .bbuf_wr_tail   (bbuf_wr_tail       ),
        .bbuf_wr_tail_en(bbuf_wr_tail_en    )
    );
    
    pe_array#(
        .BUF_DEPTH  (BUF_DEPTH  ),
        .IDX_DEPTH  (IDX_DEPTH  ),
        .PE_NUM     (PE_NUM     )
    ) pe_array_inst (
        .clk        (clk        ),
        .rst        (rst        ),
    
        .switch_d   (switch_d   ),
        .switch_p   (switch_p   ),
        .switch_i   (switch_i   ),
        .switch_a   (switch_a   ),
        .switch_b   (switch_b   ),
    
        .start      (start      ),
        .done       (done       ),
        .mode       (mode       ),
        .idx_cnt    (idx_cnt    ),  
        .trip_cnt   (trip_cnt   ), 
        .is_new     (is_new     ),
        .pad_code   (pad_code   ), 
        .cut_y      (cut_y      ),
    
        .rd_sel     (rd_sel     ),
    
        .idx_wr_data    (idx_wr_data        ),
        .idx_wr_addr    (idx_wr_addr        ),
        .idx_wr_en      (idx_wr_en          ),
    
        .dbuf_wr_addr   (dbuf_wr_addr       ),
        .dbuf_wr_data   (dbuf_wr_data       ),
        .dbuf_wr_en     (dbuf_wr_en         ),
    
        .pbuf_wr_addr   (pbuf_wr_addr       ),
        .pbuf_wr_data   (pbuf_wr_data       ),
        .pbuf_wr_en     (pbuf_wr_en         ),
    
        .bbuf_acc_en    (bbuf_acc_en        ),
        .bbuf_acc_new   (bbuf_acc_new       ),
        .bbuf_acc_addr  (bbuf_acc_addr      ),
        .bbuf_acc_data  (bbuf_acc_data      ),
    
        .abuf_wr_addr   (abuf_wr_addr       ),
        .abuf_wr_data   (abuf_wr_data       ),
        .abuf_wr_data_en(abuf_wr_data_en    ),
        .abuf_wr_tail   (abuf_wr_tail       ),
        .abuf_wr_tail_en(abuf_wr_tail_en    ),
        
        .abuf_rd_addr   (abuf_rd_addr       ),
        .abuf_rd_data   (abuf_rd_data       ),
    
        .bbuf_wr_addr   (bbuf_wr_addr       ),
        .bbuf_wr_data   (bbuf_wr_data       ),
        .bbuf_wr_data_en(bbuf_wr_data_en    ),
        .bbuf_wr_tail   (bbuf_wr_tail       ),
        .bbuf_wr_tail_en(bbuf_wr_tail_en    ),
        
        .bbuf_rd_addr   (bbuf_rd_addr       ),
        .bbuf_rd_data   (bbuf_rd_data       )
    );
    
    // only for test
    assign  ins_ready = ddr2pe_ins_ready;
    assign  ddr2pe_ins_valid = ins_valid;
    assign  ddr2pe_ins = ins;
    
    
endmodule