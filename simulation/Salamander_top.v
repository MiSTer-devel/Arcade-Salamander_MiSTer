module Salamander_top
(
    input   wire            i_EMU_MCLK
);

wire    [15:0]      debug_video;
assign  debug_video[15] = 1'b0;
wire    [8:0]       hcounter;
wire    [8:0]       vcounter;

//
// FLAT CABLE SIGNAL
//

wire            CLK9MPCEN;
wire            CLK9MNCEN;
wire            CLK6MPCEN;
wire            CLK6MNCEN;

wire            CPU_ADDR;
wire            CPU_DIN;
wire            CPU_DOUT;
wire            CPU_RW;
wire            CPU_UDS_n;
wire            CPU_LDS_n;

wire            VZCS_n;


wire            VBLANK;
wire            VSYNC;
wire            CSYNC;
wire            BLK;
wire    [10:0]  CD;




Salamander_cpu cpu_main
(
    .i_EMU_MCLK                     (i_EMU_MCLK             ),

    .i_EMU_CLK18MNCEN_n             (1'b0                   ),
    .i_EMU_CLK9MPCEN_n              (CLK9MPCEN              ),
    .i_EMU_CLK9MNCEN_n              (CLK9MNCEN              ),
    .i_EMU_CLK6MPCEN_n              (CLK6MPCEN              ),
    .i_EMU_CLK6MNCEN_n              (CLK6MNCEN              ),

    .o_CPU_ADDR                     (                       ),
    .i_CPU_DIN                      (                       ),
    .o_CPU_DOUT                     (                       ),
    .o_CPU_RW                       (                       ),
    .o_CPU_UDS_n                    (                       ),
    .o_CPU_LDS_n                    (                       ),

    .o_VZCS_n                       (                       ),
    .o_VCS1_n                       (                       ),
    .o_VCS2_n                       (                       ),
    .o_CHACS_n                      (                       ),
    .o_OBJRAM_n                     (                       ),

    .o_HFLIP                        (                       ),
    .o_VFLIP                        (                       ),

    .i_VBLANK_n                     (VBLANK                 ),
    .i_VSYNC_n                      (VSYNC                  ),
    .i_SYNC_n                       (SYNC                   ),
    .i_BLK                          (BLK                    ),
    .i_CD                           (CD                     ),

    .o_EMU_VIDEO_R                  (debug_video[4:0]       ),
    .o_EMU_VIDEO_G                  (debug_video[9:5]       ),
    .o_EMU_VIDEO_B                  (debug_video[14:10]     )
);


Salamander_video video_main
(
    .i_EMU_MCLK                     (i_EMU_MCLK             ),

    .i_EMU_CLK18MNCEN_n             (1'b0                   ),
    .o_EMU_CLK9MPCEN_n              (CLK9MPCEN              ),
    .o_EMU_CLK9MNCEN_n              (CLK9MNCEN              ),
    .o_EMU_CLK6MPCEN_n              (CLK6MPCEN              ),
    .o_EMU_CLK6MNCEN_n              (CLK6MNCEN              ),

    .i_MRST_n                       (1'b1                   ),

    .i_CPU_ADDR                     (15'd0                  ),
    .o_CPU_DIN                      (                       ),
    .i_CPU_DOUT                     (16'hFFFF               ),
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
    .o_SYNC_n                       (SYNC                   ),
    .o_BLK                          (BLK                    ),
    .o_CD                           (CD                     ),

    .__REF_HCOUNTER                 (hcounter               ),
    .__REF_VCOUNTER                 (vcounter               )
);


Salamander_screensim main
(
    .i_EMU_MCLK                     (i_EMU_MCLK             ),
    .i_EMU_CLK6MPCEN_n              (CLK6MPCEN              ),
    .i_HCOUNTER                     (hcounter               ),
    .i_VCOUNTER                     (vcounter               ),
    .i_VIDEODATA                    (debug_video            )
);



endmodule