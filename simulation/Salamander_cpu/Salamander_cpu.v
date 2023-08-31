module Salamander_cpu
(
    //
    //  FLAT CABLE
    //

    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK18MNCEN_n,

    input   wire            i_EMU_CLK9MPCEN_n, //REF_CLK9M
    input   wire            i_EMU_CLK9MNCEN_n,
    input   wire            i_EMU_CLK6MPCEN_n, //REF_CLK6M
    input   wire            i_EMU_CLK6MNCEN_n,

    output  wire            i_MRST_n,

    output  wire    [14:0]  o_CPU_ADDR,
    input   wire    [15:0]  i_CPU_DIN,
    output  wire    [15:0]  o_CPU_DOUT,
    output  wire            o_CPU_RW,
    output  wire            o_CPU_UDS_n,
    output  wire            o_CPU_LDS_n,

    output  wire            o_VZCS_n,
    output  wire            o_VCS1_n,
    output  wire            o_VCS2_n,
    output  wire            o_CHACS_n,
    output  wire            o_OBJRAM_n,

    output  wire            o_HFLIP,
    output  wire            o_VFLIP,

    input   wire            i_VBLANK_n,

    input   wire            i_VSYNC_n,
    input   wire            i_SYNC_n,

    input   wire            i_BLK,
    input   wire    [10:0]  i_CD,


    //
    // CARD EDGE IO
    //

    output  wire    [4:0]   o_EMU_VIDEO_R,
    output  wire    [4:0]   o_EMU_VIDEO_G,
    output  wire    [4:0]   o_EMU_VIDEO_B
);


//for simulation
wire            colorram_n;
assign  colorram_n = 1'b1;
assign  o_CPU_ADDR = 16'd0;
assign  o_CPU_DOUT = 16'hFFFF;
assign  o_CPU_RW = 1'b1;
assign  o_CPU_UDS_n = 1'b1;
assign  o_CPU_LDS_n = 1'b1;
assign  o_VZCS_n = 1'b1;
assign  o_VCS1_n = 1'b1;
assign  o_VCS2_n = 1'b1;
assign  o_CHACS_n = 1'b1;
assign  o_OBJRAM_n = 1'b1;
assign  o_HFLIP = 1'b1;
assign  o_VFLIP = 1'b1;











//make colorram address
wire    [10:0]  colorram_addr;
assign  colorram_addr = (colorram_n == 1'b0) ? o_CPU_ADDR : i_CD; //cpu addr

//make colorram wr signal
wire            colorram_wr = |{colorram_n, o_CPU_RW, o_CPU_LDS_n};

//declare COLORRAM
wire    [15:0]  colorram_dout;
SRAM2k8_color_high COLORRAM_HIGH
(
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (colorram_addr              ),
    .i_DIN                      (o_CPU_DOUT[15:8]           ),
    .o_DOUT                     (colorram_dout[15:8]        ),
    .i_WR_n                     (colorram_wr                ),
    .i_RD_n                     (1'b0                       )
);

SRAM2k8_color_low COLORRAM_LOW
(
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (colorram_addr              ),
    .i_DIN                      (o_CPU_DOUT[7:0]            ),
    .o_DOUT                     (colorram_dout[7:0]         ),
    .i_WR_n                     (colorram_wr                ),
    .i_RD_n                     (1'b0                       )
);

//rgb driver latch
reg     [14:0]  rgblatch;
assign  {o_EMU_VIDEO_B, o_EMU_VIDEO_G, o_EMU_VIDEO_R} = rgblatch & {15{i_BLK}}; //LS09 drivers
always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        rgblatch <= colorram_dout[14:0];
    end
end




endmodule