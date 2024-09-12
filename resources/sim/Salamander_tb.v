`timescale 10ns/10ns
module Salamander_tb;

reg             CLK72M = 1'b0;
always #1 CLK72M = ~CLK72M;

reg             MRST = 1'b1;
initial #1200 MRST <= 1'b0;

reg             pll_locked = 1'b0;
initial #3500 pll_locked <= 1'b1;

wire            master_reset = MRST | ~pll_locked;


//ioctl
wire    [15:0]  ioctl_index;
wire            ioctl_download;
wire    [26:0]  ioctl_addr;
wire    [7:0]   ioctl_data;
wire            ioctl_wr;
wire            ioctl_wait;

//SDRAM
wire    [15:0]  SDRAM_DQ;
wire    [12:0]  SDRAM_A;
wire            SDRAM_DQML;
wire            SDRAM_DQMH;
wire    [1:0]   SDRAM_BA;
wire            SDRAM_nWE;
wire            SDRAM_nCAS;
wire            SDRAM_nRAS;
wire            SDRAM_nCS;
wire            SDRAM_CKE;

Salamander_ioctl_test ioctl_test (
    .i_HPSIO_CLK                (CLK72M                     ),
    .i_RST                      (MRST                       ),

    .o_IOCTL_INDEX              (ioctl_index                ),
    .o_IOCTL_DOWNLOAD           (ioctl_download             ),
    .o_IOCTL_ADDR               (ioctl_addr                 ),
    .o_IOCTL_DATA               (ioctl_data                 ),
    .o_IOCTL_WR                 (ioctl_wr                   ),
    .i_IOCTL_WAIT               (ioctl_wait                 )
);

mt48lc16m16a2 sdram_main (
    .Dq                         (SDRAM_DQ                   ),
    .Addr                       (SDRAM_A                    ),
    .Ba                         (SDRAM_BA                   ),
    .Clk                        (CLK72M                     ),
    .Cke                        (SDRAM_CKE                  ),
    .Cs_n                       (SDRAM_nCS                  ),
    .Ras_n                      (SDRAM_nRAS                 ),
    .Cas_n                      (SDRAM_nCAS                 ),
    .We_n                       (SDRAM_nWE                  ),
    .Dqm                        ({SDRAM_DQMH, SDRAM_DQML}   ),

    .downloading                (                           ),
    .VS                         (                           ),
    .frame_cnt                  (                           )
);



///////////////////////////////////////////////////////////
//////  GAME BOARD
////

wire            rom_download_done;
assign  rom_download_done = 1'b1;
wire            core_reset = master_reset;
wire            cpu_soft_reset = master_reset | ~rom_download_done;

assign  debug = rom_download_done;

Salamander_emu u_gameboard_main (
    .i_EMU_MCLK                 (CLK72M                     ),
    .i_EMU_INITRST              (core_reset                 ),
    .i_EMU_SOFTRST              (cpu_soft_reset             ),

    .o_HBLANK                   (                           ),
    .o_VBLANK                   (                           ),
    .o_HSYNC                    (                           ),
    .o_VSYNC                    (                           ),
    .o_VIDEO_CEN                (                           ),
    .o_VIDEO_DEN                (                           ),

    .o_VIDEO_R                  (                           ),
    .o_VIDEO_G                  (                           ),
    .o_VIDEO_B                  (                           ),

    .o_SOUND                    (                           ),

    .i_JOYSTICK0                (                           ),
    .i_JOYSTICK1                (                           ),

    //mister ioctl
    .ioctl_index                (ioctl_index                ),
    .ioctl_download             (ioctl_download             ),
    .ioctl_addr                 (ioctl_addr                 ),
    .ioctl_data                 (ioctl_data                 ),
    .ioctl_wr                   (ioctl_wr                   ), 
    .ioctl_wait                 (ioctl_wait                 ),

    //mister sdram
    .sdram_dq                   (SDRAM_DQ                   ),
    .sdram_a                    (SDRAM_A                    ),
    .sdram_dqml                 (SDRAM_DQML                 ),
    .sdram_dqmh                 (SDRAM_DQMH                 ),
    .sdram_ba                   (SDRAM_BA                   ),
    .sdram_nwe                  (SDRAM_nWE                  ),
    .sdram_ncas                 (SDRAM_nCAS                 ),
    .sdram_nras                 (SDRAM_nRAS                 ),
    .sdram_ncs                  (SDRAM_nCS                  ),
    .sdram_cke                  (SDRAM_CKE                  ),

    .debug                      (                           )
);





integer i, j;
reg     [7:0]   m68k[0:2**21-1];
reg     [7:0]   scrram[0:2**11-1];
reg     [7:0]   objram[0:2**11-1];
reg     [3:0]   charram_px0[0:2**14-1];
reg     [3:0]   charram_px1[0:2**14-1];
reg     [3:0]   charram_px2[0:2**14-1];
reg     [3:0]   charram_px3[0:2**14-1];
reg     [3:0]   charram_px4[0:2**14-1];
reg     [3:0]   charram_px5[0:2**14-1];
reg     [3:0]   charram_px6[0:2**14-1];
reg     [3:0]   charram_px7[0:2**14-1];
reg     [7:0]   vram1_hi[0:2**12-1];
reg     [7:0]   vram1_lo[0:2**12-1];
reg     [7:0]   vram2[0:2**12-1];
reg     [7:0]   palram_hi[0:2**11-1];
reg     [7:0]   palram_lo[0:2**11-1];

initial begin
    $readmemh("./initfiles/m68k.txt", m68k);

    //0x190000-0x190FFF
    for(i=1; i<32'h1000; i=i+2) begin
        scrram[i>>1] = m68k[21'h190000 + i];
    end

    //0x180000-0x180FFF
    for(i=1; i<32'h1000; i=i+2) begin
        objram[i>>1] = m68k[21'h180000 + i];
    end

    //0x120000-0x12FFFF
    for(i=0; i<32'h10000; i=i+1) begin
        if(i%4 == 0) begin
            charram_px0[i>>2] = m68k[21'h120000 + i][7:4];
            charram_px1[i>>2] = m68k[21'h120000 + i][3:0];
        end
        else if(i%4 == 1) begin
            charram_px2[i>>2] = m68k[21'h120000 + i][7:4];
            charram_px3[i>>2] = m68k[21'h120000 + i][3:0];
        end
        else if(i%4 == 2) begin
            charram_px4[i>>2] = m68k[21'h120000 + i][7:4];
            charram_px5[i>>2] = m68k[21'h120000 + i][3:0];
        end
        else if(i%4 == 3) begin
            charram_px6[i>>2] = m68k[21'h120000 + i][7:4];
            charram_px7[i>>2] = m68k[21'h120000 + i][3:0];
        end
    end

    //0x100000-0x101FFF
    for(i=0; i<32'h2000; i=i+1) begin
        if(i%2 == 0) vram1_hi[i>>1] = m68k[21'h100000 + i];
        else if(i%2 == 1) vram1_lo[i>>1] = m68k[21'h100000 + i];
    end

    //0x102000-0x103FFF
    for(i=1; i<32'h2000; i=i+2) begin
        vram2[i>>1] = m68k[21'h102000 + i];
    end

    //0x090000-0x091FFF
    for(i=1; i<32'h2000; i=i+2) begin
        if((i>>1)%2 == 0) palram_hi[i>>2] = m68k[21'h090000 + i];
        else if((i>>1)%2 == 1) palram_lo[i>>2] = m68k[21'h090000 + i];
    end

    $writememh("./initfiles/scrram.txt", scrram);
    $writememh("./initfiles/objram.txt", objram);
    $writememh("./initfiles/charram_px0.txt", charram_px0);
    $writememh("./initfiles/charram_px1.txt", charram_px1);
    $writememh("./initfiles/charram_px2.txt", charram_px2);
    $writememh("./initfiles/charram_px3.txt", charram_px3);
    $writememh("./initfiles/charram_px4.txt", charram_px4);
    $writememh("./initfiles/charram_px5.txt", charram_px5);
    $writememh("./initfiles/charram_px6.txt", charram_px6);
    $writememh("./initfiles/charram_px7.txt", charram_px7);
    $writememh("./initfiles/vram1_hi.txt", vram1_hi);
    $writememh("./initfiles/vram1_lo.txt", vram1_lo);
    $writememh("./initfiles/vram2.txt", vram2);
    $writememh("./initfiles/palram_hi.txt", palram_hi);
    $writememh("./initfiles/palram_lo.txt", palram_lo);
end


endmodule