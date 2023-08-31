`timescale 10ns/10ns
module Salamander_video_tb;

reg             MCLK = 1'b0; //18.432MHz
reg             CLK18MCEN_n = 1'b0;

wire            CLK9MPCEN;
wire            CLK9MNCEN;
wire            CLK6MPCEN;
wire            CLK6MNCEN;
wire            VBLANK;
wire            VSYNC;
wire            CSYNC;
wire    [10:0]  CD;

Salamander_video main
(
    .i_EMU_MCLK                     (MCLK                   ),

    .i_EMU_CLK18MNCEN_n             (1'b0                   ),
    .o_EMU_CLK9MPCEN_n              (CLK9MPCEN              ),
    .o_EMU_CLK9MNCEN_n              (CLK9MNCEN              ),
    .o_EMU_CLK6MPCEN_n              (CLK6MPCEN              ),
    .o_EMU_CLK6MNCEN_n              (CLK6MNCEN              ),

    .i_CPU_ADDR                     (15'd0                  ),
    .i_CPU_DIN                      (16'hFFFF               ),
    .o_CPU_DOUT                     (                       ),
    .i_CPU_RW                       (1'b1                   ),
    .i_CPU_UDS_n                    (1'b1                   ),
    .i_CPU_LDS_n                    (1'b1                   ),

    .i_VZCS_n                       (1'b1                   ),
    .i_VCS1_n                       (1'b1                   ),
    .i_VCS2_n                       (1'b1                   ),
    .i_CHACS_n                      (1'b1                   ),
    .i_OBJRAM_n                     (1'b1                   ),

    .i_HFLIP                        (1'b0                   ),
    .i_VFLIP                        (1'b0                   ),

    .o_VBLANK_n                     (VBLANK                 ),
    .o_VSYNC_n                      (VSYNC                  ),
    .o_SYNC_n                       (CSYNC                  ),
    .o_CD                           (CD                     )
);

always #1 MCLK = ~MCLK;


endmodule