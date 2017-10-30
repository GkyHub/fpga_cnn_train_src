import GLB_PARAM::*;

module test_pe;

    localparam   GRP_ID_X    = 0;
    localparam   GRP_ID_Y    = 0;
    localparam   BUF_DEPTH   = 256;
    localparam   IDX_DEPTH   = 256;
    
    reg     clk, rst;
    
    always #5 clk <= ~clk;
    
    initial begin
        rst <= 1'b1;
        #100
        rst <= 1'b0;
    end
    
    reg                 start;
    wire                done;
    reg     [2  -1 : 0] mode;
    reg     [8  -1 : 0] idx_cnt;  
    reg     [8  -1 : 0] trip_cnt; 
    reg                 is_new;
    reg     [4  -1 : 0] pad_code; 
    reg                 cut_y;

    pe#(
        .GRP_ID_X   (GRP_ID_X   ),
        .GRP_ID_Y   (GRP_ID_Y   ),
        .BUF_DEPTH  (BUF_DEPTH  ),
        .IDX_DEPTH  (IDX_DEPTH  )
    ) pe_inst (
        .clk,
        .rst,
    
        .switch_i(1'b0),
        .switch_d(1'b0),
        .switch_p(1'b0),
        .switch_a(1'b0),
    
        .start      (start      ),
        .done       (done       ),
        .mode       (mode       ),
        .idx_cnt    (idx_cnt    ),  
        .trip_cnt   (trip_cnt   ), 
        .is_new     (is_new     ),
        .pad_code   (pad_code   ), 
        .cut_y      (cut_y      ),
    
        .share_data_in  (0      ),
        .share_data_out (),
    
        .idx_wr_data    (),
        .idx_wr_addr    (),
        .idx_wr_en      (),
    
        .dbuf_wr_addr   (),
        .dbuf_wr_data   (),
        .dbuf_wr_en     (),
    
        .pbuf_wr_addr   (),
        .pbuf_wr_data   (),
        .pbuf_wr_en     (),
    
        .abuf_wr_addr   (),
        .abuf_wr_data   (),
        .abuf_wr_en     (),    
        .abuf_rd_addr   (),
        .abuf_rd_data   ()
    );
    
    initial begin
        start <= 0;
        wait(~rst);
        @(posedge clk);
        start   <= 1'b1;
        mode    <= 2'b00;
        idx_cnt <= 15;
        trip_cnt<= 3;
        is_new  <= 1'b1;
        pad_code<= 4'b0000;
        cut_y   <= 1'b0;
    end

endmodule