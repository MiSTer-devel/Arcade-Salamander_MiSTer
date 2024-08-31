`timescale 10ns/10ns
module Salamander_cpu (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK9M_PCEN,
    input   wire            i_EMU_CLK9M_NCEN,
    input   wire            i_EMU_CLK6M_PCEN,
    input   wire            i_EMU_CLK6M_NCEN,

    input   wire            i_EMU_INITRST_n,
    input   wire            i_EMU_SOFTRST_n,

    output  wire    [14:0]  o_GFX_ADDR,
    input   wire    [15:0]  i_GFX_DO,
    output  wire    [15:0]  o_GFX_DI, 
    output  wire            o_GFX_RnW,
    output  wire            o_GFX_UDS_n,
    output  wire            o_GFX_LDS_n,

    output  reg             o_VZCS_n,
    output  reg             o_VCS1_n,
    output  reg             o_VCS2_n,
    output  reg             o_CHACS_n,
    output  reg             o_OBJRAM_n,
    
    output  wire            o_HFLIP,
    output  wire            o_VFLIP,

    input   wire            i_ABS_1H_n,
    input   wire            i_ABS_2H,

    input   wire            i_VBLANK_n,
    input   wire            i_FRAMEPARITY,

    input   wire            i_BLK,

    input   wire    [10:0]  i_CD,

    output  wire    [7:0]   o_SNDCODE,
    output  wire            o_SNDINT,

    input   wire    [7:0]   i_IN0, i_IN1, i_IN2, i_DIPSW1, i_DIPSW2,

    output  wire    [4:0]   o_VIDEO_R,
    output  wire    [4:0]   o_VIDEO_G,
    output  wire    [4:0]   o_VIDEO_B,

    output  wire    [16:0]  o_EMU_DATAROM_ADDR,
    input   wire    [15:0]  i_EMU_DATAROM_DATA,
    output  wire            o_EMU_DATAROM_RDRQ,

    output  wire    [15:0]  o_EMU_PROGROM_ADDR,
    input   wire    [15:0]  i_EMU_PROGROM_DATA,
    output  wire            o_EMU_PROGROM_RDRQ
);



///////////////////////////////////////////////////////////
//////  CLOCK AND RESET
////

wire            maincpu_pwrup = ~i_EMU_INITRST_n;
wire            maincpu_rst = ~i_EMU_INITRST_n | ~i_EMU_SOFTRST_n;
wire            mclk = i_EMU_MCLK;
wire            clk9m_pcen = i_EMU_CLK9M_PCEN;
wire            clk9m_ncen = i_EMU_CLK9M_NCEN;
wire            clk6m_pcen = i_EMU_CLK6M_PCEN;
wire            clk6m_ncen = i_EMU_CLK6M_NCEN;



///////////////////////////////////////////////////////////
//////  MAIN CPU
////

reg     [15:0]  maincpu_di;
wire    [15:0]  maincpu_do;
wire    [23:1]  maincpu_addr;
reg             maincpu_vpa_n;
reg             maincpu_dtack_n;
wire            maincpu_as_n, maincpu_r_nw, maincpu_lds_n, maincpu_uds_n;
wire    [23:0]  debug_maincpu_addr = {maincpu_addr, maincpu_uds_n};
wire    [2:0]   maincpu_ipl;

assign  o_GFX_ADDR = maincpu_addr[15:1];
assign  o_GFX_DI = maincpu_do;
assign  o_GFX_RnW = maincpu_r_nw;
assign  o_GFX_UDS_n = maincpu_uds_n;
assign  o_GFX_LDS_n = maincpu_lds_n;

fx68k u_maincpu (
    .clk                        (mclk                       ),
    .HALTn                      (1'b1                       ),
    .extReset                   (maincpu_rst                ),
    .pwrUp                      (maincpu_pwrup              ),
    .enPhi1                     (clk9m_pcen                 ),
    .enPhi2                     (clk9m_ncen                 ),

    .eRWn                       (maincpu_r_nw               ),
    .ASn                        (maincpu_as_n               ),
    .LDSn                       (maincpu_lds_n              ),
    .UDSn                       (maincpu_uds_n              ),
    .E                          (                           ),
    .VMAn                       (                           ),

    .iEdb                       (maincpu_di                 ), //data bus in
    .oEdb                       (maincpu_do                 ), //data bus out
    .eab                        (maincpu_addr               ), //23 downto 1

    .FC0                        (                           ),
    .FC1                        (                           ),
    .FC2                        (                           ),
    
    .BGn                        (                           ),
    .oRESETn                    (                           ),
    .oHALTEDn                   (                           ),

    .DTACKn                     (maincpu_dtack_n            ),
    .VPAn                       (maincpu_vpa_n              ),
    
    .BERRn                      (1'b1                       ),

    .BRn                        (1'b1                       ),
    .BGACKn                     (1'b1                       ),

    .IPL0n                      (maincpu_ipl[0]             ),
    .IPL1n                      (maincpu_ipl[1]             ),
    .IPL2n                      (maincpu_ipl[2]             )
);



///////////////////////////////////////////////////////////
//////  ADDRESS DECODER
////

//use A23 and /AS as G, decoder sees A[20:16], A[13], A22 and A21 are don't care
reg             progrom_rd, datarom_rd, workram_cs;
reg             palram_cs;
reg             syscfg_cs, io0_cs, io1_cs;
always @(*) begin
    progrom_rd  = 1'b0;
    datarom_rd  = 1'b0;
    workram_cs  = 1'b0;
    syscfg_cs   = 1'b0;
    io0_cs      = 1'b0;
    io1_cs      = 1'b0;
    
    palram_cs   = 1'b0;
    o_VZCS_n    = 1'b1;
    o_VCS1_n    = 1'b1;
    o_VCS2_n    = 1'b1;
    o_CHACS_n   = 1'b1;
    o_OBJRAM_n  = 1'b1;

    maincpu_vpa_n = 1'b1;

    if(!maincpu_as_n && !maincpu_addr[23]) begin
        progrom_rd  = maincpu_addr[20:17] == 4'b0_000;  //0x000000-0x01FFFF, 512k*2
        datarom_rd  = maincpu_addr[20:18] == 3'b0_01;   //0x040000-0x07FFFF, 1M*2
        workram_cs  = maincpu_addr[20:16] == 5'b0_1000; //0x080000-0x087FFF, 64k*4
        syscfg_cs   = maincpu_addr[20:16] == 5'b0_1010; //0x0A0000-0x0AFFFF
        io0_cs      = maincpu_addr[20:16] == 5'b0_1100 && maincpu_addr[13] == 1'b0; //0x0C0000-0x0C1FFF
        io1_cs      = maincpu_addr[20:16] == 5'b0_1100 && maincpu_addr[13] == 1'b1; //0x0C2000-0x0C3FFF

        palram_cs   =   maincpu_addr[20:16] == 5'b0_1001;  //0x090000-0x091FFF, 16k*2, byte only
        o_VZCS_n    = ~(maincpu_addr[20:16] == 5'b1_1001); //0x190000-0x190FFF, 16k*1, byte only
        o_VCS1_n    = ~(maincpu_addr[20:16] == 5'b1_0000 && maincpu_addr[13] == 1'b0); //0x100000-0x101FFF, 32k*2, Toshiba 32kbit TC5533
        o_VCS2_n    = ~(maincpu_addr[20:16] == 5'b1_0000 && maincpu_addr[13] == 1'b1); //0x102000-0x103FFF, 32k*1, byte only
        o_CHACS_n   = ~(maincpu_addr[20:16] == 5'b1_0010); //0x120000-0x12FFFF, 4416*8
        o_OBJRAM_n  = ~(maincpu_addr[20:16] == 5'b1_1000); //0x180000-0x180FFF, 16k*1, byte only
    end

    maincpu_vpa_n = maincpu_as_n | ~maincpu_addr[23];
end



///////////////////////////////////////////////////////////
//////  MAIN CPU DTACK
////

wire            dtack0_n = maincpu_uds_n & maincpu_lds_n;
reg             dtack1_n, dtack2_pre_n, dtack2_n;
always @(posedge mclk) begin
    if(dtack0_n) begin
        dtack1_n <= 1'b1;
        dtack2_pre_n <= 1'b1;
        dtack2_n <= 1'b1;
    end
    else begin 
        if(clk6m_pcen) begin
            if(!i_ABS_1H_n) dtack1_n <= dtack0_n;
            dtack2_pre_n <= dtack0_n;
        end

        if(clk6m_ncen) begin
            if({i_ABS_2H, i_ABS_1H_n} == 2'b01) dtack2_n <= dtack2_pre_n;
        end
    end
end

always @(*) begin
    case(maincpu_addr[20:19])
        2'd0: maincpu_dtack_n = dtack0_n; //0x000000-0x0FFFFF: ROM, RAM, outlatches
        2'd1: maincpu_dtack_n = dtack0_n;
        2'd2: maincpu_dtack_n = dtack2_n; //0x100000-0x17FFFF: TMRAM, COLORRAM, CHARRAM
        2'd3: maincpu_dtack_n = dtack1_n; //0x180000-0x1FFFFF: OBJRAM, SCROLLRAM
    endcase
end



///////////////////////////////////////////////////////////
//////  MAIN CPU IRQ
////

wire            iack_vblank_n, iack_fparity_n;
reg             vblank_z, vblank_zz, fparity_z, fparity_zz;
reg             irq_vblank_n, irq_fparity_n;
assign  maincpu_ipl[2] = 1'b1;
assign  maincpu_ipl[1] = irq_vblank_n;
assign  maincpu_ipl[0] = ~&{irq_vblank_n, ~irq_fparity_n};

always @(posedge mclk) begin
    vblank_z <= ~i_VBLANK_n;
    vblank_zz <= vblank_z;
    fparity_z <= i_FRAMEPARITY;
    fparity_zz <= fparity_z;

    if(maincpu_rst) begin
        irq_vblank_n <= 1'b1;
        irq_fparity_n <= 1'b1;
    end
    else begin
        if(!iack_vblank_n) irq_vblank_n <= 1'b1;
        else begin
            if({vblank_zz, vblank_z} == 2'b01) irq_vblank_n <= 1'b0;
        end
        if(!iack_fparity_n) irq_fparity_n <= 1'b1;
        else begin
            if({fparity_zz, fparity_z} == 2'b01) irq_fparity_n <= 1'b0;
        end
    end
end



///////////////////////////////////////////////////////////
//////  OUTLATCH(SYSTEM CONFIGURATION)
////

reg     [5:0]   syscfg[0:1];
always @(posedge mclk) begin
    if(maincpu_rst) begin
        syscfg[0] <= 6'h00;
        syscfg[1] <= 6'h00;
    end
    else begin if(syscfg_cs) begin
        if(!maincpu_uds_n) syscfg[0] <= maincpu_do[13:8];
        if(!maincpu_lds_n) syscfg[1] <= maincpu_do[5:0];
    end end
end

assign  iack_vblank_n = syscfg[1][0];
assign  iack_fparity_n = syscfg[1][1];
assign  o_VFLIP = syscfg[1][2];
assign  o_HFLIP = syscfg[1][3];
assign  o_SNDINT = syscfg[0][3];



///////////////////////////////////////////////////////////
//////  PROGRAM ROM
////

/*  
    MEMORY MAP(byte)
    0x00000-0x1FFFF: program ROM(512k*2)
    0x40000-0x7FFFF: graphic ROM(1M*2)
    0x80000-0x87FFF: main RAM(64k*4)
*/


wire    [15:0]  progrom_q; /*
Salamander_PROM #(.AW(16), .DW(8), .simhexfile("rom_18b.txt")) u_progrom_hi (
    .i_MCLK                     (i_EMU_MCLK               ),

    .i_PROG_ADDR                (                           ),
    .i_PROG_DIN                 (                           ),
    .i_PROG_CS                  (1'b1                       ),
    .i_PROG_WR                  (                           ),

    .i_ADDR                     (maincpu_addr[16:1]         ),
    .o_DOUT                     (progrom_q[15:8]            ),
    .i_RD                       (progrom_rd                 )
);
Salamander_PROM #(.AW(16), .DW(8), .simhexfile("rom_18c.txt")) u_progrom_lo (
    .i_MCLK                     (i_EMU_MCLK               ),

    .i_PROG_ADDR                (                           ),
    .i_PROG_DIN                 (                           ),
    .i_PROG_CS                  (1'b1                       ),
    .i_PROG_WR                  (                           ),

    .i_ADDR                     (maincpu_addr[16:1]         ),
    .o_DOUT                     (progrom_q[7:0]             ),
    .i_RD                       (progrom_rd                 )
); 
*/
assign  o_EMU_PROGROM_ADDR = maincpu_addr[16:1];
assign  progrom_q = i_EMU_PROGROM_DATA;
assign  o_EMU_PROGROM_RDRQ = progrom_rd;

wire    [15:0]  datarom_q; /*
Salamander_PROM #(.AW(17), .DW(8), .simhexfile("rom_17b.txt")) u_datarom_hi (
    .i_MCLK                     (i_EMU_MCLK               ),

    .i_PROG_ADDR                (                           ),
    .i_PROG_DIN                 (                           ),
    .i_PROG_CS                  (1'b1                       ),
    .i_PROG_WR                  (                           ),

    .i_ADDR                     (maincpu_addr[17:1]         ),
    .o_DOUT                     (datarom_q[15:8]            ),
    .i_RD                       (datarom_rd                 )
);
Salamander_PROM #(.AW(17), .DW(8), .simhexfile("rom_17c.txt")) u_datarom_lo (
    .i_MCLK                     (i_EMU_MCLK               ),

    .i_PROG_ADDR                (                           ),
    .i_PROG_DIN                 (                           ),
    .i_PROG_CS                  (1'b1                       ),
    .i_PROG_WR                  (                           ),

    .i_ADDR                     (maincpu_addr[17:1]         ),
    .o_DOUT                     (datarom_q[7:0]             ),
    .i_RD                       (datarom_rd                 )
);
*/
assign  o_EMU_DATAROM_ADDR = maincpu_addr[17:1];
assign  datarom_q = i_EMU_DATAROM_DATA;
assign  o_EMU_DATAROM_RDRQ = datarom_rd;

wire    [15:0]  workram_q;
Salamander_SRAM #(.AW(14), .DW(8), .simhexfile()) u_workram_hi (
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (maincpu_addr[14:1]         ),
    .i_DIN                      (maincpu_do[15:8]           ),
    .o_DOUT                     (workram_q[15:8]            ),
    .i_WR                       (workram_cs & ~maincpu_r_nw & ~maincpu_uds_n),
    .i_RD                       (workram_cs &  maincpu_r_nw & ~maincpu_uds_n)
);
Salamander_SRAM #(.AW(14), .DW(8), .simhexfile()) u_workram_lo (
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (maincpu_addr[14:1]         ),
    .i_DIN                      (maincpu_do[7:0]            ),
    .o_DOUT                     (workram_q[7:0]             ),
    .i_WR                       (workram_cs & ~maincpu_r_nw & ~maincpu_lds_n),
    .i_RD                       (workram_cs &  maincpu_r_nw & ~maincpu_lds_n)
);




///////////////////////////////////////////////////////////
//////  Palette RAM
////

//make palram wr signal
wire            palram_hi_cs = &{palram_cs, maincpu_addr[1] == 1'b0};
wire            palram_lo_cs = &{palram_cs, maincpu_addr[1] == 1'b1};

//make colorram address
wire    [10:0]  palram_addr = palram_cs ? maincpu_addr[12:2] : i_CD;

//declare COLORRAM
wire    [7:0]   palram_lo_q, palram_hi_q;
wire    [15:0]  palram_q = maincpu_addr[1] ? {8'hFF, palram_lo_q} : {8'hFF, palram_hi_q};

Salamander_SRAM #(.AW(11), .DW(8), .simhexfile()) u_palram_hi (
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (palram_addr                ),
    .i_DIN                      (maincpu_do[7:0]            ),
    .o_DOUT                     (palram_hi_q                ),
    .i_WR                       (palram_hi_cs & ~maincpu_r_nw),
    .i_RD                       (1'b1                       )
);

Salamander_SRAM #(.AW(11), .DW(8), .simhexfile()) u_palram_lo (
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (palram_addr                ),
    .i_DIN                      (maincpu_do[7:0]            ),
    .o_DOUT                     (palram_lo_q                ),
    .i_WR                       (palram_lo_cs & ~maincpu_r_nw),
    .i_RD                       (1'b1                       )
);

//rgb driver latch
reg     [14:0]  rgblatch;
always @(posedge mclk) if(clk6m_pcen) begin
    rgblatch <= {palram_hi_q[6:0], palram_lo_q};
end

assign  o_VIDEO_B = i_BLK ? rgblatch[14:10] : 5'd0;
assign  o_VIDEO_G = i_BLK ? rgblatch[9:5] : 5'd0;
assign  o_VIDEO_R = i_BLK ? rgblatch[4:0] : 5'd0;



///////////////////////////////////////////////////////////
////// SOUNDLATCH
////

reg     [7:0]   soundlatch = 8'h00;
assign  o_SNDCODE = soundlatch;
always @(posedge mclk) begin
    if(io0_cs && (maincpu_addr[2:1] == 2'd0) && !maincpu_lds_n) soundlatch <= maincpu_do[7:0];
end



///////////////////////////////////////////////////////////
//////  READ BUS MUX
////

/*
    io0_cs
    C0001   : soundlatch
    C0002-3 : DSW0(MAME); DIPSW1(PCB)
    C0004-5 : watchdog

    io1_cs
    C2000-1 : IN0(MAME); DIPSW3(PCB)[2:0], coin/start
    C2002-3 : IN1(MAME); DIPSW3(PCB)[3], p1
    C2004-5 : IN2(MAME); p2
    C2006-7 : DSW1(MAME); DIPSW2(PCB)
*/

wire            gfx_cs = ~&{o_VZCS_n, o_VCS1_n, o_VCS2_n, o_CHACS_n, o_OBJRAM_n};

always @(*) begin
    maincpu_di = 16'hFFFF;

         if(progrom_rd) maincpu_di = progrom_q;
    else if(datarom_rd) maincpu_di = datarom_q;
    else if(workram_cs) maincpu_di = workram_q;
    else if(palram_cs) maincpu_di = palram_q;
    else if(gfx_cs) maincpu_di = i_GFX_DO;
    else if(io0_cs && maincpu_addr[2:1] == 2'd1) maincpu_di = {8'hFF, i_DIPSW1}; 
    else if(io1_cs) begin
        case(maincpu_addr[2:1])
            2'd0: maincpu_di = {8'hFF, i_IN0};
            2'd1: maincpu_di = {8'hFF, i_IN1};
            2'd2: maincpu_di = {8'hFF, i_IN2};
            2'd3: maincpu_di = {8'hFF, i_DIPSW2};
        endcase
    end
end


endmodule
