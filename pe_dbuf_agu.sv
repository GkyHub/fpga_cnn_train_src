import GLOBAL_PARAM::IDX_W;

module pe_dbuf_agu(
    input   clk,
    input   rst,
    
    // configuration port
    input           start,
    input   [1 : 0] mode,
    
    input   [IDX_W  -1 : 0] idx,
    
    // output address port
    output  [ADDR_W -1 : 0] addr
    );
    
//=============================================================================
// feed forward convolution logic
//=============================================================================
    
    loop#(
        .DATA_W (4      ),
        .MODE   ("comb" )
    ) row_cnt (
        .clk    (clk    ),
        .rst    (rst    ),
    
        .lim    (3      ),  // counter will count from 0 to lim iteratively
    
        .trig   (working),  // counter work when trig asserts
        .cnt,
        .last    
    );
    
    loop#(
        .DATA_W (4      ),
        .MODE   ("block")
    ) col_cnt (
        .clk    (clk    ),
        .rst    (rst    ),
    
        .lim,    // counter will count from 0 to lim iteratively
    
        .trig,   // counter work when trig asserts
        .cnt,
        .last    
    );
    
endmodule