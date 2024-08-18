module GX400_video (
    input   wire            i_EMU_MCLK,

    input   wire            i_EMU_CLK18M_NCEN,
    input   wire            i_EMU_CLK6M_PCEN, //REF_CLK6M
    input   wire            i_EMU_CLK6M_NCEN,

    input   wire            i_MRST_n,

    input   wire    [14:0]  i_GFX_ADDR,
    output  reg     [15:0]  o_GFX_DO,
    input   wire    [15:0]  i_GFX_DI,
    input   wire            i_GFX_RnW,
    input   wire            i_GFX_UDS_n,
    input   wire            i_GFX_LDS_n,

    input   wire            i_VZCS_n,
    input   wire            i_VCS1_n,
    input   wire            i_VCS2_n,
    input   wire            i_CHACS_n,
    input   wire            i_OBJRAM_n,

    input   wire            i_HFLIP,
    input   wire            i_VFLIP,

    output  wire            o_HBLANK_n,
    output  wire            o_VBLANK_n,
    output  wire            o_HSYNC_n,
    output  wire            o_VSYNC_n,

    output  wire            o_ABS_1H_n,
    output  wire            o_ABS_2H,
    output  wire            o_FRAMEPARITY,

    output  wire            o_BLK,

    output  wire    [10:0]  o_CD,

    output  wire    [8:0]   o_DEBUG_HCNTR, //for pixel capture purpose
    output  wire    [8:0]   o_DEBUG_VCNTR
);



///////////////////////////////////////////////////////////
//////  CLOCK AND RESET
////

wire            mclk = i_EMU_MCLK;
wire            clk18m_ncen = i_EMU_CLK18M_NCEN;
wire            clk6m_pcen = i_EMU_CLK6M_PCEN;
wire            clk6m_ncen = i_EMU_CLK6M_NCEN;



///////////////////////////////////////////////////////////
//////  timinggen
////

wire            HBLANK_n;
wire            VBLANK_n;
assign          o_VBLANK_n = VBLANK_n;
assign          o_HBLANK_n = HBLANK_n;
wire            VBLANKH_n;
wire            VCLK;
wire            CSYNC_n;

//hcounter
wire            ABS_256H,   
                ABS_128H,   ABS_64H,    ABS_32H,    ABS_16H,
                ABS_8H,     ABS_4H,     ABS_2H,     ABS_1H;

wire            FLIP_128H,  FLIP_64H,   FLIP_32H,   FLIP_16H,
                FLIP_8H,    FLIP_4H,    FLIP_2H,    FLIP_1H;

//vcounter
wire            ABS_128V,   ABS_64V,    ABS_32V,    ABS_16V,
                ABS_8V,     ABS_4V,     ABS_2V,     ABS_1V;

wire            FLIP_128V,  FLIP_64V,   FLIP_32V,   FLIP_16V,
                FLIP_8V,    FLIP_4V,    FLIP_2V,    FLIP_1V;

//misc
wire            ABS_n256H = ~ABS_256H;
wire            ABS_n1H = ~ABS_1H;
wire            ABS_128HA = (ABS_256H & ABS_128H) | (ABS_n256H & ABS_32H);

wire            FLIP_n256H  = ABS_n256H ^ i_HFLIP;

wire            DMA_n = ~&{ABS_128V, ABS_64V, ABS_32V, ~ABS_16V}; //vcounter 480-495

//to CPU
assign  o_ABS_1H_n = ABS_n1H;
assign  o_ABS_2H = ABS_2H;


K005292 u_K005292 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_MRST_n                   (i_MRST_n                   ),

    .i_HFLIP                    (i_HFLIP                    ),
    .i_VFLIP                    (i_VFLIP                    ),

    .o_HBLANK_n                 (HBLANK_n                   ),
    .o_VBLANK_n                 (VBLANK_n                   ),
    .o_VBLANKH_n                (VBLANKH_n                  ),  //VBLANK**

    .o_ABS_256H                 (ABS_256H                   ),
    .o_ABS_128H                 (ABS_128H                   ),
    .o_ABS_64H                  (ABS_64H                    ),
    .o_ABS_32H                  (ABS_32H                    ),
    .o_ABS_16H                  (ABS_16H                    ),
    .o_ABS_8H                   (ABS_8H                     ),
    .o_ABS_4H                   (ABS_4H                     ),
    .o_ABS_2H                   (ABS_2H                     ),
    .o_ABS_1H                   (ABS_1H                     ),

    .o_ABS_128V                 (ABS_128V                   ),
    .o_ABS_64V                  (ABS_64V                    ),
    .o_ABS_32V                  (ABS_32V                    ),
    .o_ABS_16V                  (ABS_16V                    ),
    .o_ABS_8V                   (ABS_8V                     ),
    .o_ABS_4V                   (ABS_4V                     ),
    .o_ABS_2V                   (ABS_2V                     ),
    .o_ABS_1V                   (ABS_1V                     ),

    .o_FLIP_128H                (FLIP_128H                  ),
    .o_FLIP_64H                 (FLIP_64H                   ),
    .o_FLIP_32H                 (FLIP_32H                   ),
    .o_FLIP_16H                 (FLIP_16H                   ),
    .o_FLIP_8H                  (FLIP_8H                    ),
    .o_FLIP_4H                  (FLIP_4H                    ),
    .o_FLIP_2H                  (FLIP_2H                    ),
    .o_FLIP_1H                  (FLIP_1H                    ),

    .o_FLIP_128V                (FLIP_128V                  ),
    .o_FLIP_64V                 (FLIP_64V                   ),
    .o_FLIP_32V                 (FLIP_32V                   ),
    .o_FLIP_16V                 (FLIP_16V                   ),
    .o_FLIP_8V                  (FLIP_8V                    ),
    .o_FLIP_4V                  (FLIP_4V                    ),
    .o_FLIP_2V                  (FLIP_2V                    ),
    .o_FLIP_1V                  (FLIP_1V                    ),

    .o_VCLK                     (VCLK                       ),

    .o_FRAMEPARITY              (o_FRAMEPARITY              ), //256V
    
    .o_VSYNC_n                  (o_VSYNC_n                  ),
    .o_HSYNC_n                  (o_HSYNC_n                  ),

    .o_DEBUG_HCNTR              (o_DEBUG_HCNTR              ),
    .o_DEBUG_VCNTR              (o_DEBUG_VCNTR              )
);

wire            ORINC;
reg     [7:0]   OBJ;
wire            objcntr_tick = ORINC | (&{OBJ[7:4]});

always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if(ABS_1H == 1'b0) begin //posedge of 1H
            if(DMA_n == 1'b0) begin
                OBJ <= 8'd0;
            end
            else begin
                if(objcntr_tick == 1'b0) begin
                    OBJ <= OBJ + 8'd1;
                end
            end
        end        
    end
end




//
//  MEMORY TIMING GENERATOR SECTION
//

/*
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
            ---(511)---|----(0)----|----(1)----|----(2)----|
    
    TIME1   ___________________|¯¯¯|___________________|¯¯¯|
    TIME2   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|
    CHAMPX  ¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯
    VRTIME  ¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯
    OBJCLRWE¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯
    
    BUFWE   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯
    BUFRAS  ___________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|____
    dl-ras  ____________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|___
*/

//timing singals

wire            TIME1; //SCROLLRAM/OBJRAM read latch enable(active high)
wire            TIME2; //SCROLLRAM/OBJRAM data write enable(active low)
wire            VRTIME; //Video Read TIME
wire            CHAMPX; //CHAracter MultiPleXer
wire            OBJCLRWE; //OBJect CLeaR Write Enable

reg             CLK6M;
always @(posedge mclk) begin
    if(clk6m_ncen) CLK6M <= 1'b0;
    else if(clk6m_pcen) CLK6M <= 1'b1;
end

reg             TIMING_F; //1HF
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        TIMING_F <= ABS_1H;
    end
end

reg     [3:0]   TIMING_SR;
always @(posedge mclk) begin
    if(clk18m_ncen) begin
        TIMING_SR[3] <= TIMING_F;
        TIMING_SR[2:0] <= TIMING_SR[3:1];
    end
end

assign  TIME1 = ~(~TIMING_F | CLK6M);
assign  TIME2 = ~(TIMING_F & TIMING_SR[2]);
assign  VRTIME = ~(TIMING_F & ~TIMING_SR[3]);
assign  CHAMPX = TIMING_SR[2] | TIMING_SR[1];
wire    CHAMPX1 = CHAMPX;
assign  OBJCLRWE = TIMING_SR[2] | ~TIMING_SR[1];

//DRAM delay
reg             CHAMPX2;
always @(posedge mclk) begin
    if(clk18m_ncen) begin
        CHAMPX2 <= CHAMPX;
    end
end


//
//  VIDEO TIMING GENERATOR SECTION
//

//timing singals
wire            OBJWR;  //switches mux between active display+buffer clear/sprite engine write
wire            OBJCLR; //fix mux output to 0 while clearing the buffer by writing 0s

reg             TIMING_A;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if({ABS_8H, ABS_4H, ABS_2H, ABS_1H} == 4'd15) begin //posedge of 16H
            TIMING_A <= ~(HBLANK_n & VBLANKH_n);
        end        
    end
end

reg             TIMING_B;
always @(posedge mclk) begin
    if(clk6m_pcen) begin //negedge cen
        if(ABS_1H == 1'b1) begin //every ODD pixel
            TIMING_B <= TIMING_A;
        end        
    end
end

reg             TIMING_C;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if({ABS_2H, ABS_1H} == 2'd3) begin //posedge of 4H
            TIMING_C <= TIMING_A;
        end        
    end
end

reg             TIMING_D;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        TIMING_D <= TIMING_C;   
    end
end

reg             TIMING_E;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        TIMING_E <= ~TIMING_D & VBLANK_n;
    end
end

assign  OBJWR = TIMING_B;
assign  OBJCLR = ~TIMING_B;
assign  o_BLK = TIMING_E;








///////////////////////////////////////////////////////////
//////  tilemapgen
////

//
//  scrollram section
//

/*
    FETCHES HSCROLL(1 PIXEL ROW) VALUE WHEN VCLK = 1

    MCLK                0 1 2 3 4 5 0 1 2 3 4 5
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|___|¯¯¯|___|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
            ----(7)----|----(0)----|----(1)----|----(2)----|----(3)----|
                             >SRAM DOUT  >SRAM DOUT  >SRAM DOUT  >SRAM DOUT      access speed >150ns
    
    TIME1   ___________________|¯¯¯|___________________|¯¯¯|____________
    TIME2   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯
    VCLK    ___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    ADDR               |-------(TM-A LO)-------|-------(TM-A HI)-------|
    DEVICE             |---(CPU)---|---(GFX)---|---(CPU)---|---(GFX)---|
                                   |  TM-A LO  |           |  TM-A HI  |


    FETCHES VSCROLL(8 PIXEL COLUMN) VALUE WHEN VCLK = 0
        (TM-A for 4H = 0, TM-B for 4H = 1)

                                            1 1                     1 1                     1 1                     1 1
                        0 1 2 3 4 5 6 7 8 9 0 1 0 1 2 3 4 5 6 7 8 9 0 1 0 1 2 3 4 5 6 7 8 9 0 1 0 1 2 3 4 5 6 7 8 9 0 1
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
            ----(7)----|----(0)----|----(1)----|----(2)----|----(3)----|----(4)----|----(5)----|----(6)----|----(7)----|

    TIME1   ___________________|¯¯¯|___________________|¯¯¯|___________________|¯¯¯|___________________|¯¯¯|____________
    TIME2   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯
    VCLK    ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
                                                                        
    SCRLATCH¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|
    SCRADDR --(TM-A)---|--------------------(TM-B)---------------------|--------------------(TM-A)---------------------|
    DEVICE  ---(GFX)---|---(CPU)---|---(GFX)---|---(CPU)---|---(GFX)---|---(CPU)---|---(GFX)---|---(CPU)---|---(GFX)---|

    VRAMADDR--(TM-B)---|--------------------(TM-A)---------------------|--------------------(TM-B)---------------------|
                       t0                                              t1                                              t2                     

    0. HSCROLL values for TM-A and TM-B are latched when VCLK = 1

    t0
    1. MUX provides TM-A VSCROLL address when 4H = 0 & VCLK = 0
    2. tilemap generator latches TM-A VSCROLL value at posedge of ~(1H & 2H)
    3. Then TM-A VSCROLL value will be valid during next 4px-cycle
    4. In this next 4px-cycle, tilemap generator provides previously latched(at VCLK = 0) TM-A HSCROLL value

    t1
    1. Again, tilemap generator latches TM-A VSCROLL value at posedge of ~(1H & 2H) since MUX provided TM-B VSCROLL address
    2. Then TM-B VSCROLL value will be valid during next 4px-cycle
    3. In this next 4px-cycle, tilemap generator provides previously latched(at VCLK = 0) TM-B HSCROLL value
*/

//make scrollram address
wire    [10:0]  scrollval_addr;
assign  scrollval_addr =    (~VCLK == 1'b0) ? 
                                {1'b0, ABS_4H, ABS_2H, FLIP_128V, FLIP_64V,  FLIP_32V,  FLIP_16V,  FLIP_8V,  FLIP_4V,  FLIP_2V, FLIP_1V} : //HORIZONTAL SCROLL
                                {1'b1,   1'b1,   1'b1,      1'b1,   ABS_4H,FLIP_n256H, FLIP_128H, FLIP_64H, FLIP_32H, FLIP_16H, FLIP_8H};  //VERTICAL SCROLL

wire    [10:0]  scrollram_addr;
assign  scrollram_addr =    (~ABS_1H == 1'b0) ?
                                scrollval_addr :
                                i_GFX_ADDR[10:0];

//make scrollram wr signal
wire            scrollram_wr = (i_VZCS_n | i_GFX_RnW | i_GFX_LDS_n | TIME2);

//declare SCROLLRAM
wire    [7:0]   scrollram_dout;
GX400_video_sram #(.aw( 11 ), .dw(  8 ), .simhexfile()) u_scrollram_lo (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (scrollram_addr             ),
    .i_DIN                      (i_GFX_DI[7:0]            ),
    .o_DOUT                     (scrollram_dout             ),
    .i_WR_n                     (scrollram_wr               ),
    .i_RD_n                     (1'b0                       )
);

//declare CPU side latch
wire    [7:0]   scrollram_readlatch_q;
GX400_video_asynclatch u_scrollram_cpulatch (
    .i_MCLK                     (mclk                       ),
    .i_D                        (scrollram_dout             ),
    .o_Q                        (scrollram_readlatch_q      ),
    .i_LE                       (TIME1                      )
);



wire    [11:0]  vram_addr;
wire    [2:0]   line_addr;

wire            SHIFTA1;
wire            SHIFTA2;
wire            SHIFTB;

//declare tilemapgen core: requires clock
K005291 u_K005291 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_HFLIP                    (i_HFLIP                    ),
    .i_VFLIP                    (i_VFLIP                    ),

    .i_ABS_n256H                (ABS_n256H                  ),
    .i_ABS_128HA                (ABS_128HA                  ),
    .i_ABS_64H                  (ABS_64H                    ),
    .i_ABS_32H                  (ABS_32H                    ),
    .i_ABS_16H                  (ABS_16H                    ),
    .i_ABS_8H                   (ABS_8H                     ),
    .i_ABS_4H                   (ABS_4H                     ),
    .i_ABS_2H                   (ABS_2H                     ),
    .i_ABS_1H                   (ABS_1H                     ),

    .i_ABS_128V                 (ABS_128V                   ),
    .i_ABS_64V                  (ABS_64V                    ),
    .i_ABS_32V                  (ABS_32V                    ),
    .i_ABS_16V                  (ABS_16V                    ),
    .i_ABS_8V                   (ABS_8V                     ),
    .i_ABS_4V                   (ABS_4V                     ),
    .i_ABS_2V                   (ABS_2V                     ),
    .i_ABS_1V                   (ABS_1V                     ),
    
    .i_VCLK                     (VCLK                       ),

    .i_CPU_ADDR                 (i_GFX_ADDR[11:0]           ),
    .i_GFXDATA                  (scrollram_dout             ),

    .o_TILELINEADDR             (line_addr                  ),

    .o_VRAMADDR                 (vram_addr                  ),

    .o_SHIFTA1                  (SHIFTA1                    ),
    .o_SHIFTA2                  (SHIFTA2                    ),
    .o_SHIFTB                   (SHIFTB                     )
);



//
//  VRAM1+2 section
//

/*
    MCLK                           
                        0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 0 1 2 3 4 5 
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
    PIXEL   ----(7)----|----(0)----|----(1)----|----(2)----|----(3)----|----(4)----|----(5)----|----(6)----|----(7)----|
    /DTACK  ¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

                                   >SRAM CPU DIN           >SRAM GFX DOUT          >SRAM CPU DOUT          >SRAM GFX DOUT    100ns access speed
    VRTIME  ¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯     enable
    DEVICE             |---------(CPU)---------|---------(GFX)---------|---------(CPU)---------|---------(GFX)---------|
                                   |(RD VALID)-|                                   |(RD VALID)-|                             ext. gates allow RD during pixel 0 and 1 cycles
                             |WRVAL|                                         |WRVAL|                                         ext. gates allow WR during pixel 0 cycle
                       |                 VRAM ADDR TM-A                |                 VRAM ADDR TM-B                |

                                                                       >VRAM ADDR TM-A latched at /2H
                                                                                                                       >CHARRAM TM-A line data latched
*/

//make vram wr signal
wire            vram1h_wr = (i_VCS1_n | i_GFX_RnW | i_GFX_UDS_n | ABS_1H | ABS_2H); //pixel 0 and 4
wire            vram1l_wr = (i_VCS1_n | i_GFX_RnW | i_GFX_LDS_n | ABS_1H | ABS_2H);
wire            vram2l_wr = (i_VCS2_n | i_GFX_RnW | i_GFX_LDS_n | ABS_1H | ABS_2H);

//declare vram1
wire    [15:0]  vram1_dout;
GX400_video_sram #(.aw( 12 ), .dw(  8 ), .simhexfile()) u_vram1_hi (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (vram_addr                  ),
    .i_DIN                      (i_GFX_DI[15:8]           ),
    .o_DOUT                     (vram1_dout[15:8]           ),
    .i_WR_n                     (vram1h_wr                  ),
    .i_RD_n                     (VRTIME                     )
);

GX400_video_sram #(.aw( 12 ), .dw(  8 ), .simhexfile()) u_vram1_lo (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (vram_addr                  ),
    .i_DIN                      (i_GFX_DI[7:0]            ),
    .o_DOUT                     (vram1_dout[7:0]            ),
    .i_WR_n                     (vram1l_wr                  ),
    .i_RD_n                     (VRTIME                     )
);

//declare vram2
wire    [7:0]   vram2_dout;
GX400_video_sram #(.aw( 12 ), .dw(  8 ), .simhexfile()) u_vram2_lo (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (vram_addr                  ),
    .i_DIN                      (i_GFX_DI[7:0]            ),
    .o_DOUT                     (vram2_dout                 ),
    .i_WR_n                     (vram2l_wr                  ),
    .i_RD_n                     (VRTIME                     )
);


//
//  VRAM1 tile code DFF
//

reg     [10:0]  tile_code;
reg             VVFF;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if({ABS_4H, ABS_2H, ABS_1H} == 3'd3 || {ABS_4H, ABS_2H, ABS_1H} == 3'd7) begin //posedge of /2H
            tile_code <= vram1_dout[10:0];
            VVFF <= vram1_dout[11];
        end
    end
end


//
//  VRAM1+2 properties
//

wire            VHFF = vram2_dout[7];
wire    [6:0]   VC = vram2_dout[6:0];
wire    [3:0]   PR = vram1_dout[15:12];


//
//  tile address
//

wire    [7:0]   VCA;
wire    [13:0]  __REF_VCA_ORIGINAL = {tile_code, line_addr ^ {3{VVFF}}};
assign  VCA =   (CHAMPX2 == 1'b0) ?
                    {tile_code[4:0], line_addr[2:0] ^ {3{VVFF}}} : {1'b1, tile_code[10:5], 1'b1}; //RAS : CAS






///////////////////////////////////////////////////////////
//////  objengine
////

//
//  OBJRAM SECTION
//

//make objram address
wire    [10:0]  objram_addr;
assign  objram_addr =   (~ABS_n1H == 1'b0) ?
                            i_GFX_ADDR[10:0] :
                            {ABS_8V, ABS_4V, ABS_2V, ABS_1V, ABS_128H, ABS_64H, ABS_32H, ABS_16H, ABS_8H, ABS_4H, ABS_2H};

//make objram wr signal
wire            objram_wr = |{i_OBJRAM_n, i_GFX_RnW, i_GFX_LDS_n, TIME2}; //LS32*4

//declare OBJRAM
wire    [7:0]   objram_dout;
GX400_video_sram #(.aw( 11 ), .dw(  8 ), .simhexfile()) u_objram_lo (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (objram_addr                ),
    .i_DIN                      (i_GFX_DI[7:0]            ),
    .o_DOUT                     (objram_dout                ),
    .i_WR_n                     (objram_wr                  ),
    .i_RD_n                     (1'b0                       )
);

//declare CPU side latch
wire    [7:0]   objram_readlatch_q;
GX400_video_asynclatch u_objram_cpulatch (
    .i_MCLK                     (mclk                       ),
    .i_D                        (objram_dout                ),
    .o_Q                        (objram_readlatch_q         ),
    .i_LE                       (TIME1                      )
);


//
//  SPRITE DMA SECTION
//

reg     [7:0]   obj_priority;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if({ABS_8H, ABS_4H, ABS_2H, ABS_1H} == 4'd1) begin //posedge of /px1 of every 16 pixels
           obj_priority <= objram_dout;
        end
    end
end

reg     [7:0]   obj_attr;
always @(posedge mclk) begin
    if(clk6m_pcen) begin
        if(ABS_1H == 1'b1) begin //posedge of /px1 
           obj_attr <= objram_dout;
        end
    end
end

//make objtable address
wire    [2:0]   ORA;
wire    [10:0]  objtable_addr;
assign  objtable_addr = (DMA_n == 1'b0) ? 
                            {obj_priority, ABS_8H, ABS_4H, ABS_2H} :
                            {OBJ, ORA};


//make objtable_wr
wire            objtable_wr = ~(ABS_1H & ~DMA_n);

//declare objtable ram
wire    [7:0]   objtable_dout;
GX400_video_sram #(.aw( 11 ), .dw(  8 )) u_objtable (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (objtable_addr              ),
    .i_DIN                      (obj_attr                   ),
    .o_DOUT                     (objtable_dout              ),
    .i_WR_n                     (objtable_wr                ),
    .i_RD_n                     (1'b0                       )
);


wire    [7:0]   OCA;
wire            CHAOV;
reg             OBJHL;

wire    [7:0]   FA, FB;
wire            XA7, XB7;
wire            OBJBUF_CAS;

wire            WRTIME2;
wire            COLORLATCH_n;
wire            XPOS_D0;
wire            PIXELLATCH_WAIT_n;
wire            LATCH_A_D2;
wire    [2:0]   PIXELSEL;


//declare objengine core
K005295 #(.ENABLE_DOUBLE_HEIGHT_MODE(0)) u_K005295 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_DMA_n                    (DMA_n                      ),
    .i_VBLANKH_n                (VBLANKH_n                  ),
    .i_VBLANK_n                 (VBLANK_n                   ),
    .i_HBLANK_n                 (HBLANK_n                   ),
    .i_ABS_4H                   (ABS_4H                     ),
    .i_ABS_2H                   (ABS_2H                     ),
    .i_ABS_1H                   (ABS_1H                     ),
    .i_CHAMPX                   (CHAMPX2                    ),
    .i_OBJWR                    (OBJWR                      ),

    .i_FLIP                     (i_HFLIP                    ),

    .i_OBJDATA                  (objtable_dout              ),
    .o_ORA                      (ORA                        ),

    .o_CAS                      (OBJBUF_CAS                 ),

    .o_FA                       (FA                         ),
    .o_FB                       (FB                         ),

    .o_XA7                      (XA7                        ),
    .o_XB7                      (XB7                        ),

    .i_OBJHL                    (OBJHL                      ),
    .o_CHAOV                    (CHAOV                      ),
    .o_ORINC                    (ORINC                      ),
    
    .o_WRTIME2                  (WRTIME2                    ),
    .o_COLORLATCH_n             (COLORLATCH_n               ),
    .o_XPOS_D0                  (XPOS_D0                    ),
    .o_PIXELLATCH_WAIT_n        (PIXELLATCH_WAIT_n          ),
    .o_LATCH_A_D2               (LATCH_A_D2                 ),
    .o_PIXELSEL                 (PIXELSEL                   ),

    .o_OCA                      (OCA                        )
);



///////////////////////////////////////////////////////////
//////  CHARRAM
////

/*
    MCLK                                    1 1
                        0 1 2 3 4 5 6 7 8 9 0 1 
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
    PIXEL   ----(3)----|----(4)----|----(5)----|----(6)----|----(7)----|----(0)----|----(1)----|----(2)----|----(3)----|
    /DTACK  ¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

                               >row >column            >row >column
    CHAMPX2 ¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    /RAS    ___________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|________________     15ns delayed
    /CAS    ________________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|___________     85ns delayed

                                     >DRAM CPU/REFRESH       >DRAM GFX DOUT          >DRAM CPU/REFRESH       >DRAM GFX DOU   DRAM async access speed 150ns
                                                                                                                             Automatically refreshes ROW ADDRESS during CPU/HV counter access cycle                                                                                                           
    DEVICE             |---------(CPU)---------|---------(GFX)---------|---------(CPU)---------|---------(GFX)---------|
    LATCHED CPU WR ¯¯¯¯¯¯¯¯¯¯¯¯|_______________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
                                     |(WR VALID)-|                                   |(WR VALID)-|                                
                                     |(RD VALID)-|                                   |(RD VALID)-|
                       |                CHARRAM ADDR TM-A              |                CHARRAM ADDR TM-B              |

                                                                       >CHARRAM TM-A data latched by tilemapsr
                                                                                                                       >CHARRAM data TM-B latched by tilemapsr
*/

//LS153*4 MUX
wire    [7:0]   refresh_addr = {ABS_16V, ABS_8V, ABS_4V, ABS_2V, ABS_1V, ABS_128H, ABS_64H, ABS_32H};
wire    [7:0]   cpu_addr;
assign  cpu_addr =  (i_CHACS_n == 1'b1) ?
                        refresh_addr :
                        (CHAMPX2 == 1'b0) ?
                            i_GFX_ADDR[8:1] : {1'b1, i_GFX_ADDR[14:9], 1'b1}; //RAS(A9-A2) : CAS(1, A15-A10, 1)

//LS157*2 11A/B MUX
wire    [7:0]   gfx_addr;
assign  gfx_addr = (CHAOV == 1'b0) ? OCA : VCA;

//LS157*2 10A/B MUX
wire    [7:0]   charram_addr;
assign  charram_addr =  (~ABS_2H == 1'b0) ? gfx_addr : cpu_addr;


//
//  DRAM modules
//

//RAS/CAS
wire            charram_ras_n = ~CHAMPX;
reg             charram_cas_n = 1'b1; //54.25ns delayed RAS, same as CHAMPX2
always @(posedge mclk) if(clk18m_ncen) begin
    charram_cas_n <= charram_ras_n;
end

//WR/RD
reg             charramu_en; //upper
reg             charraml_en; //upper
always @(posedge mclk) if(clk6m_ncen) begin //negedge of 6M, every even pixel
    if(ABS_1H == 1'b0) begin //posedge of every even pixel
        charramu_en <= i_GFX_UDS_n | i_CHACS_n;
        charraml_en <= i_GFX_LDS_n | i_CHACS_n;
    end
end

wire            charcs1_n = i_CHACS_n | ABS_2H | i_GFX_ADDR[0];
wire            charcs2_n = i_CHACS_n | ABS_2H | ~i_GFX_ADDR[0];
wire            charram1_rw = charcs1_n | i_GFX_RnW; //R=1 W=0
wire            charram2_rw = charcs2_n | i_GFX_RnW;

wire            charram1_rd = ~charram1_rw; //disables output when reading
wire            charram2_rd = ~charram2_rw; //disables output when reading
wire            charram1u_wr = charramu_en | charram1_rw;
wire            charram1l_wr = charraml_en | charram1_rw;
wire            charram2u_wr = charramu_en | charram2_rw;
wire            charram2l_wr = charraml_en | charram2_rw;


//declare charram
wire      [15:0]  charram1_dout; //A1=0
wire      [15:0]  charram2_dout; //A1=1

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px0 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[15:12]            ),
    .o_DOUT                     (charram1_dout[15:12]       ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram1u_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px1 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[11:8]             ),
    .o_DOUT                     (charram1_dout[11:8]        ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram1u_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px2 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[7:4]              ),
    .o_DOUT                     (charram1_dout[7:4]         ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram1l_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px3 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[3:0]              ),
    .o_DOUT                     (charram1_dout[3:0]         ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram1l_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px4 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[15:12]            ),
    .o_DOUT                     (charram2_dout[15:12]       ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram2u_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px5 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[11:8]             ),
    .o_DOUT                     (charram2_dout[11:8]        ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram2u_wr               ),
    .i_RD_n                     (1'b0                       )
);
GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px6 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[7:4]              ),
    .o_DOUT                     (charram2_dout[7:4]         ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram2l_wr               ),
    .i_RD_n                     (1'b0                       )
);

GX400_video_dram #(.dw( 4 ), .aw( 8 ), .rw( 8 ), .cw( 6 ), .ctop( 6 ), .cbot( 1 ), .simhexfile(), .init(0)) u_chrram_px7 (
    .i_MCLK                     (mclk                       ),
    .i_ADDR                     (charram_addr               ),
    .i_DIN                      (i_GFX_DI[3:0]              ),
    .o_DOUT                     (charram2_dout[3:0]         ),
    .i_RAS_n                    (charram_ras_n              ),
    .i_CAS_n                    (charram_cas_n              ),
    .i_WR_n                     (charram2l_wr               ),
    .i_RD_n                     (1'b0                       )
);



///////////////////////////////////////////////////////////
//////  tilemapsr
////

//
//  timing signal generation
//

wire            A_FLIP;
wire            B_FLIP;

wire            AFF = i_HFLIP ^ A_FLIP;
wire            BFF = i_HFLIP ^ B_FLIP;

wire    [1:0]   A_MODE = {(~SHIFTA1 | ~AFF), (~SHIFTA1 | AFF)};
wire    [1:0]   B_MODE = {(~SHIFTB | ~BFF), (~SHIFTB | BFF)};


wire    [3:0]   A_PIXEL;
wire    [3:0]   B_PIXEL;
wire            A_TRN_n;
wire            B_TRN_n;

K005290 u_K005290 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_GFXDATA                  ({charram1_dout, charram2_dout}),
                            
    .i_ABS_n4H                  (~ABS_4H                    ),
    .i_ABS_2H                   (ABS_2H                     ),
                            
    .i_AFF                      (AFF                        ),
    .i_BFF                      (BFF                        ),
                            
    .i_A_MODE                   (A_MODE                     ),
    .i_B_MODE                   (B_MODE                     ),
                            
    .o_A_PIXEL                  (A_PIXEL                    ),
    .o_B_PIXEL                  (B_PIXEL                    ),
                            
    .o_A_TRN_n                  (A_TRN_n                    ),
    .o_B_TRN_n                  (B_TRN_n                    )
);    







///////////////////////////////////////////////////////////
//////  objlinelatch
////

wire            TILELINELATCH_n = ~(ABS_1H & ABS_2H);
wire    [7:0]   DA;
wire    [7:0]   DB;


K005294 u_K005294 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_GFXDATA                  ({charram1_dout, charram2_dout}),
    .i_OC                       (objtable_dout[4:1]         ),

    .i_TILELINELATCH_n          (TILELINELATCH_n            ),

    .o_DA                       (DA                         ),
    .o_DB                       (DB                         ),

    .i_WRTIME2                  (WRTIME2                    ),
    .i_COLORLATCH_n             (COLORLATCH_n               ),
    .i_XPOS_D0                  (XPOS_D0                    ),
    .i_PIXELLATCH_WAIT_n        (PIXELLATCH_WAIT_n          ),
    .i_LATCH_A_D2               (LATCH_A_D2                 ),
    .i_PIXELSEL                 (PIXELSEL                   )
);






///////////////////////////////////////////////////////////
//////  FRAME BUFFER
////


reg             FBTIMING_A;
always @(posedge mclk) if(clk6m_pcen) begin
    FBTIMING_A <= WRTIME2;
end

reg             FBTIMING_B;
always @(posedge mclk) if(clk6m_ncen) begin //negative edge of CLK6M
    FBTIMING_B <= FBTIMING_A;
end

wire            wrtime2_buf_ras_n = FBTIMING_A & ~FBTIMING_B; 
wire            objbuf_ras_n = (OBJWR == 1'b0) ? ~CHAMPX : wrtime2_buf_ras_n;



reg             FBTIMING_C;
always @(posedge mclk) if(clk6m_pcen) begin //positive edge of CLK6M
    FBTIMING_C <= FBTIMING_A;
end

wire            wrtime2_buf_we_n = CLK6M | ~FBTIMING_C;
wire            objbuf_we_n = (OBJWR == 1'b0) ? OBJCLRWE : wrtime2_buf_we_n;



reg             objbuf_ras_dly_n;
always @(posedge mclk) if(clk18m_ncen) begin
    OBJHL <= ~objbuf_ras_n;
    objbuf_ras_dly_n <= objbuf_ras_n;
end


wire            evenbuf_overwrite_disable = ~(~XA7 & |{DA[3:0]});
wire    [7:0]   evenbuf_dout;
wire    [7:0]   evenbuf_din =   (OBJCLR == 1'b1) ? 8'h00 :
                                        (evenbuf_overwrite_disable == 1'b0) ? DA : evenbuf_dout;

wire            oddbuf_overwrite_disable = ~(~XB7 & |{DB[3:0]});
wire    [7:0]   oddbuf_dout;
wire    [7:0]   oddbuf_din =    (OBJCLR == 1'b1) ? 8'h00 :
                                        (oddbuf_overwrite_disable == 1'b0) ? DB : oddbuf_dout;
                                    

//EVEN
GX400_video_dram #(.dw( 8 ), .aw( 8 )) u_evenbuf (
    .i_MCLK (i_EMU_MCLK), .i_ADDR (FA),
    .i_DIN (evenbuf_din), .o_DOUT (evenbuf_dout), 
    .i_RAS_n (objbuf_ras_n), .i_CAS_n (~OBJBUF_CAS), .i_WR_n (objbuf_we_n), .i_RD_n (1'b0) 
);


//ODD
GX400_video_dram #(.dw( 8 ), .aw( 8 )) u_oddbuf (
    .i_MCLK (i_EMU_MCLK), .i_ADDR (FB),
    .i_DIN (oddbuf_din), .o_DOUT (oddbuf_dout), 
    .i_RAS_n (objbuf_ras_n), .i_CAS_n (~OBJBUF_CAS), .i_WR_n (objbuf_we_n), .i_RD_n (1'b0)
);



///////////////////////////////////////////////////////////
//////  prihandler
////

wire            SHIFTA1_CLKD = SHIFTA1;
wire            SHIFTA2_CLKD = SHIFTA2;
wire            SHIFTB_CLKD = SHIFTB;

wire            ABS_n6n7H = ~(ABS_4H & ABS_2H);
wire            ABS_n2n3H = ~(~ABS_4H & ABS_2H);

K005293 u_K005293 (
    .i_EMU_MCLK                 (mclk                       ),
    .i_EMU_CLK6MPCEN_n          (~clk6m_pcen                ),

    .i_HFLIP                    (i_HFLIP                    ),

    .i_SHIFTA1                  (SHIFTA1_CLKD               ),
    .i_SHIFTA2                  (SHIFTA2_CLKD               ),
    .i_SHIFTB                   (SHIFTB_CLKD                ),

    .i_ABS_n1H                  (ABS_n1H                    ),
    .i_ABS_n6n7H                (ABS_n6n7H                  ),
    .i_ABS_n2n3H                (ABS_n2n3H                  ),

    .i_A_PIXEL                  (A_PIXEL                    ),
    .i_B_PIXEL                  (B_PIXEL                    ),
    .i_OBJBUF_DATA              ({oddbuf_dout, evenbuf_dout}),

    .i_A_TRN_n                  (A_TRN_n                    ),
    .i_B_TRN_n                  (B_TRN_n                    ),

    .i_VHFF                     (VHFF                       ),
    .i_VC                       (VC                         ),
    .i_PR                       (PR                         ),

    .o_A_FLIP                   (A_FLIP                     ),
    .o_B_FLIP                   (B_FLIP                     ),

    .o_CD                       (o_CD                       )
);






///////////////////////////////////////////////////////////
//////  DATA OUTPUT MUX
////

always @(*) begin
    case({i_VZCS_n, i_VCS1_n, i_VCS2_n, charcs1_n, charcs2_n, i_OBJRAM_n})
        6'b011111: o_GFX_DO <= {8'hFF, scrollram_readlatch_q};
        6'b101111: o_GFX_DO <= vram1_dout;
        6'b110111: o_GFX_DO <= {8'hFF, vram2_dout};
        6'b111011: o_GFX_DO <= charram1_dout;
        6'b111101: o_GFX_DO <= charram2_dout;
        6'b111110: o_GFX_DO <= {8'hFF, objram_readlatch_q};
        default: o_GFX_DO <= 16'hFFFF; //pull up
    endcase
end

endmodule



module GX400_video_asynclatch (
    input   wire            i_MCLK,
    input   wire    [7:0]   i_D,
    output  wire    [7:0]   o_Q,
    input   wire            i_LE
);

reg     [7:0]   REGISTER;
always @(posedge i_MCLK) begin
    if(i_LE) REGISTER <= i_D;
end

assign  o_Q = i_LE ? i_D : REGISTER;

endmodule