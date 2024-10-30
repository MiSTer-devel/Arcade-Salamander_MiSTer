module Salamander_emu (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_SCLK,
    input   wire            i_EMU_INITRST,
    input   wire            i_EMU_SOFTRST,

    //video syncs
    output  wire            o_HBLANK,
    output  wire            o_VBLANK,
    output  wire            o_HSYNC,
    output  wire            o_VSYNC,
    output  wire            o_VIDEO_CEN, //video clock enable
    output  wire            o_VIDEO_DEN, //video data enable

    output  wire    [4:0]   o_VIDEO_R,
    output  wire    [4:0]   o_VIDEO_G,
    output  wire    [4:0]   o_VIDEO_B,

    output  wire signed      [15:0]  o_SND_L,
    output  wire signed      [15:0]  o_SND_R,

    input   wire    [15:0]  i_JOYSTICK0,
    input   wire    [15:0]  i_JOYSTICK1,

    //mister ioctl
    input   wire    [15:0]  ioctl_index,
    input   wire            ioctl_download,
    input   wire    [26:0]  ioctl_addr,
    input   wire    [7:0]   ioctl_data,
    input   wire            ioctl_wr, 
    output  wire            ioctl_wait,

    //mister sdram
    inout   wire    [15:0]  sdram_dq,
    output  wire    [12:0]  sdram_a,
    output  wire            sdram_dqml,
    output  wire            sdram_dqmh,
    output  wire    [1:0]   sdram_ba,
    output  wire            sdram_nwe,
    output  wire            sdram_ncas,
    output  wire            sdram_nras,
    output  wire            sdram_ncs,
    output  wire            sdram_cke,

    output  wire            debug
);



///////////////////////////////////////////////////////////
//////  ROM DISTRUBUTOR
////

//start addr    length        comp num     mame rom     parts num     location     description
//0x0000_0000   0x0002_0000   17b          587-c03      TC531000      BANK0        graphic data(lo, mask=10)
//0x0002_0000   0x0002_0000   17c          587-c06      TC531000      BANK0        graphic data(hi, mask=01)
//0x0004_0000   0x0002_0000   10a          587-c01      TC531000      BANK1        PCM samples
//0x0006_0000   0x0001_0000   18b          587-d02      27C512        BANK0        game program(lo, mask=10)
//0x0007_0000   0x0001_0000   18c          587-d05      27C512        BANK0        game program(hi, mask=01)
//0x0008_0000   0x0000_8000   11j          587-d09      27C256        BRAM         sound program
//0x0008_8000   0x0000_4000   8g           587-d08      27C128        BRAM         VLM5030 commands  
//0x0008_C000          <-----------------ROM END----------------->

//dipsw bank
reg     [7:0]   DIPSW1 = 8'hFF;
reg     [7:0]   DIPSW2 = 8'h42;
reg     [4:0]   DIPSW3 = 5'h1F; //use bit[4] internally




///////////////////////////////////////////////////////////
//////  SDRAM/BRAM DOWNLOADER INTERFACE
////

//download complete
reg             rom_download_done = 1'b0;

//enables
reg             prog_sdram_en = 1'b0;
reg             prog_bram_en = 1'b0;

//sdram control
wire            sdram_init;
reg             prog_sdram_wr_busy = 1'b0;
wire            prog_sdram_ack;
//assign          ioctl_wait = sdram_init | prog_sdram_wr_busy;
assign          ioctl_wait = 1'b0;

reg     [1:0]   prog_sdram_bank_sel;
reg     [21:0]  prog_sdram_addr;
reg     [1:0]   prog_sdram_mask;
reg     [15:0]  prog_sdram_din_buf;

//bram control
reg     [15:0]  prog_bram_addr;
reg     [7:0]   prog_bram_din_buf;
reg             prog_bram_wr;
reg     [1:0]   prog_bram_csreg;

wire            prog_bram_vlmrom_cs = prog_bram_csreg[1];
wire            prog_bram_sndrom_cs = prog_bram_csreg[0];
assign          debug = rom_download_done;

//state machine
always @(posedge i_EMU_MCLK) begin
    if((i_EMU_INITRST | rom_download_done) == 1'b1) begin
        if(i_EMU_INITRST) rom_download_done <= 1'b0;

        //enables
        prog_sdram_en <= 1'b0;
        prog_bram_en <= 1'b0;
        
        //sdram
        prog_sdram_addr <= 22'h3F_FFFF;
        prog_sdram_wr_busy <= 1'b0;
        prog_sdram_bank_sel <= 2'd0;
        prog_sdram_mask <= 2'b00;
        prog_sdram_din_buf <= 16'hFFFF;

        //bram
        prog_bram_din_buf <= 8'hFF;
        prog_bram_addr <= 16'hFFFF;
        prog_bram_wr <= 1'b0;
        prog_bram_csreg <= 2'b00;

        if(ioctl_index == 16'd254) begin //DIP SWITCH
            if(ioctl_wr == 1'b1) begin
                     if(ioctl_addr[2:0] == 3'd0) DIPSW1 <= ioctl_data;
                else if(ioctl_addr[2:0] == 3'd1) DIPSW2 <= ioctl_data;
                else if(ioctl_addr[2:0] == 3'd2) DIPSW3 <= ioctl_data[4:0];
            end
        end
    end
    else begin
        //  ROM DATA UPLOAD
        if(ioctl_index == 16'd0) begin //ROM DATA
            //  BLOCK RAM REGION
            if(ioctl_addr[19] == 1'b1) begin
                prog_sdram_en <= 1'b0;
                prog_bram_en <= 1'b1;

                if(ioctl_wr == 1'b1) begin
                    prog_bram_din_buf <= ioctl_data;
                    prog_bram_addr <= ioctl_addr[15:0];
                    prog_bram_wr <= 1'b1;

                    if(ioctl_addr[15] == 1'b0) prog_bram_csreg <= 2'b01;
                    else prog_bram_csreg <= 2'b10;
                end
                else begin
                    prog_bram_wr <= 1'b0;
                end
            end

            //  SDRAM REGION
            else begin
                prog_sdram_en <= 1'b1;
                prog_bram_en <= 1'b0;
                
                if(prog_sdram_wr_busy == 1'b0) begin
                    if(ioctl_wr == 1'b1) begin
                        prog_sdram_wr_busy <= 1'b1;

                        if(ioctl_addr[19:16] < 4'h4) begin
                            prog_sdram_bank_sel <= 2'd0;
                            prog_sdram_addr <= {5'b00_000, ioctl_addr[16:0]}; //BANK0 0x00_0000-0x01_FFFF
                            prog_sdram_din_buf <= {ioctl_data, ioctl_data};
                            if(ioctl_addr[17] == 1'b0) prog_sdram_mask <= 2'b01; //hi(68k big endian)
                            else prog_sdram_mask <= 2'b10; //lo
                        end
                        else if(ioctl_addr[19:16] == 4'h4 || ioctl_addr[19:16] == 4'h5) begin
                            prog_sdram_bank_sel <= 2'd1;
                            prog_sdram_addr <= {6'b00_0000, ioctl_addr[16:1]}; 
                            prog_sdram_din_buf <= {ioctl_data, ioctl_data};
                            if(ioctl_addr[0] == 1'b0) prog_sdram_mask <= 2'b10; //lo(small endian)
                            else prog_sdram_mask <= 2'b01;
                        end
                        else if(ioctl_addr[19:16] == 4'h6 || ioctl_addr[19:16] == 4'h7) begin
                            prog_sdram_bank_sel <= 2'd0;
                            prog_sdram_addr <= {6'b00_0010, ioctl_addr[15:0]}; //BANK0 0x02_0000-0x02_FFFF
                            prog_sdram_din_buf <= {ioctl_data, ioctl_data};
                            if(ioctl_addr[16] == 1'b0) prog_sdram_mask <= 2'b01; //hi(68k big endian)
                            else prog_sdram_mask <= 2'b10; //lo
                        end
                    end
                end
                else begin
                    if(prog_sdram_ack == 1'b1) begin  
                        prog_sdram_wr_busy <= 1'b0;
                    end
                end
            end
        end

        else if(ioctl_index == 16'd254) begin //DIP SWITCH
            prog_sdram_en <= 1'b0;
            prog_bram_en <= 1'b0;
            rom_download_done <= 1'b1;
        end
    end
end




///////////////////////////////////////////////////////////
//////  SDRAM CONTROLLER
////

wire    [21:0]  ba0_addr;
wire    [21:0]  ba1_addr;
wire    [21:0]  ba2_addr;
wire    [3:0]   rd;           
wire    [3:0]   ack;
wire    [3:0]   dst;
wire    [3:0]   rdy;
wire    [15:0]  data_read;

reg     [8:0]   rfsh_cntr;
wire            rfsh = rfsh_cntr == 9'd384;
always @(posedge i_EMU_MCLK) begin
    if(i_EMU_INITRST) begin
        rfsh_cntr <= 9'd0;
    end
    else begin if(o_VIDEO_CEN) begin
        if(rfsh_cntr < 9'd384) rfsh_cntr <= rfsh_cntr + 9'd1;
        else rfsh_cntr <= 9'd0;
    end end
end

jtframe_sdram64 #(.HF(0)) sdram_controller (
    .rst                        (i_EMU_INITRST              ),
    .clk                        (i_EMU_MCLK                 ),
    .init                       (sdram_init                 ),

    .ba0_addr                   (ba0_addr                   ),
    .ba1_addr                   (ba1_addr                   ),
    .ba2_addr                   (22'h00_0000                ),
    .ba3_addr                   (22'h00_0000                ),
    .rd                         ({2'b00, rd[1:0]}           ),
    .wr                         (4'b0000                    ),
    .din                        (prog_sdram_din_buf         ),
    .din_m                      (2'b00                      ),

    .prog_en                    (prog_sdram_en              ),
    .prog_addr                  (prog_sdram_addr            ),
    .prog_rd                    (1'b0                       ),
    .prog_wr                    (prog_sdram_wr_busy         ),
    .prog_din                   (prog_sdram_din_buf         ),
    .prog_din_m                 (prog_sdram_mask            ),
    .prog_ba                    (prog_sdram_bank_sel        ),
    .prog_dst                   (                           ),
    .prog_dok                   (                           ),
    .prog_rdy                   (                           ),
    .prog_ack                   (prog_sdram_ack             ),

    .rfsh                       (rfsh                       ),

    .ack                        (ack                        ),
    .dst                        (dst                        ),
    .dok                        (                           ),
    .rdy                        (rdy                        ),
    .dout                       (data_read                  ),

    .sdram_dq                   (sdram_dq                   ),
    .sdram_a                    (sdram_a                    ),
    .sdram_dqml                 (sdram_dqml                 ),
    .sdram_dqmh                 (sdram_dqmh                 ),
    .sdram_ba                   (sdram_ba                   ),
    .sdram_nwe                  (sdram_nwe                  ),
    .sdram_ncas                 (sdram_ncas                 ),
    .sdram_nras                 (sdram_nras                 ),
    .sdram_ncs                  (sdram_ncs                  ),
    .sdram_cke                  (sdram_cke                  )
);



///////////////////////////////////////////////////////////
//////  ROM SLOTS
////

wire    [15:0]  progrom_addr;
wire    [15:0]  progrom_q;
wire            progrom_rdrq;

wire    [16:0]  datarom_addr;
wire    [15:0]  datarom_q;
wire            datarom_rdrq;

jtframe_rom_2slots #(
    // Slot 0: Data ROM
    .SLOT0_AW                   (17                         ),
    .SLOT0_DW                   (16                         ),
    .SLOT0_OFFSET               (22'h00_0000                ),

    // Slot 1: Program ROM
    .SLOT1_AW                   (16                         ),
    .SLOT1_DW                   (16                         ),
    .SLOT1_OFFSET               (22'h02_0000                )
) bank0 (
    .rst                        (~rom_download_done         ),
    .clk                        (i_EMU_MCLK                 ),

    .slot0_cs                   (datarom_rdrq               ),
    .slot1_cs                   (progrom_rdrq               ),

    .slot0_ok                   (                           ),
    .slot1_ok                   (                           ),

    .slot0_addr                 (datarom_addr               ),
    .slot1_addr                 (progrom_addr               ),

    .slot0_dout                 (datarom_q                  ),
    .slot1_dout                 (progrom_q                  ),

    .sdram_addr                 (ba0_addr                   ),
    .sdram_req                  (rd[0]                      ),
    .sdram_ack                  (ack[0]                     ),
    .data_dst                   (dst[0]                     ),
    .data_rdy                   (rdy[0]                     ),
    .data_read                  (data_read                  )
);


wire    [16:0]  pcmrom_addr;
wire    [15:0]  pcmrom_q;
wire            pcmrom_rdrq;

jtframe_rom_2slots #(
    // Slot 0: PCM ROM
    .SLOT0_AW                   (16                         ),
    .SLOT0_DW                   (16                         ),
    .SLOT0_OFFSET               (22'h00_0000                ),

    // Slot 1: reserved
    .SLOT1_AW                   (16                         ),
    .SLOT1_DW                   (16                         ),
    .SLOT1_OFFSET               (22'h01_0000                )
) bank1 (
    .rst                        (~rom_download_done         ),
    .clk                        (i_EMU_MCLK                 ),

    .slot0_cs                   (pcmrom_rdrq                ),
    .slot1_cs                   (1'b0                       ),

    .slot0_ok                   (                           ),
    .slot1_ok                   (                           ),

    .slot0_addr                 (pcmrom_addr[16:1]          ),
    .slot1_addr                 (16'h0                      ),

    .slot0_dout                 (pcmrom_q                   ),
    .slot1_dout                 (                           ),

    .sdram_addr                 (ba1_addr                   ),
    .sdram_req                  (rd[1]                      ),
    .sdram_ack                  (ack[1]                     ),
    .data_dst                   (dst[1]                     ),
    .data_rdy                   (rdy[1]                     ),
    .data_read                  (data_read                  )
);



///////////////////////////////////////////////////////////
//////  INPUT MAPPER
////

/*
    1: SW OFF
    0: SW ON

    DIPSW1
        76543210
            ||||
            ^^^^-- Coinage          /1111=1C1P 1110=1C2P 1101=1C3P 1100=1C4P 
                                    /1011=1C5P 1010=1C6P 1001=1C7P 1000=2C1P    
                                    /0111=2C3P 0110=2C5P 0101=3C1P 0100=3C2P
                                    /0011=3C4P 0010=4C1P 0001=4C3P 0000=Disabled(?)
          
    DIPSW2
        76543210
        ||||||||
        ||||||^^-- Lives            /11=2 10=3 01=5 00=7
        |||||^---- Coin slots       /1=1 0=2
        |||^^----- Max credits      /11=1 10=3 01=5 00=9
        |^^------- Difficulty       /11=easy 10=normal 01=hard 00=hardest
        ^--------- Demo sound       /1=off 0=on

    DIPSW3
           43210
           ||| |
           ||| ^-- Flip             /1=normal 0=flip
           ||^---- Test mode        /1=normal 0=service
           |^----- Cabinet          /1=upright 0=cocktail
           ^------ Input counts     /1=2-button 0=3-button
*/

/*
    <buttons default="Select,R,L,A,B,X" names="Service,Coin,Start,Shoot,Missile,Power-up"></buttons>

    MiSTer joystick(SNES)
    bit   
    0   right
    1   left
    2   down
    3   up
    4   service(SELECT)
    5   coin(R)
    6   start(L)
    7   shoot(A)
    8   missile(B)
    9   power-up(X)

    salamander
    btn1 - shoot
    btn2 - missile

    lifefrcej
    btn1 - power-up
    btn2 - shoot
    btn3 - missile
*/

wire    [7:0]   IN0, IN1, IN2;

//System control
assign          IN0[0]  = i_JOYSTICK0[5]; //p1 coin
assign          IN0[1]  = i_JOYSTICK1[5]; //p2 coin
assign          IN0[2]  = i_JOYSTICK0[4]; //service
assign          IN0[3]  = i_JOYSTICK0[6]; //p1 start
assign          IN0[4]  = i_JOYSTICK1[6]; //p2 start
assign          IN0[5]  = DIPSW3[0];
assign          IN0[6]  = DIPSW3[1];
assign          IN0[7]  = DIPSW3[2];

//Player 1 control
assign          IN1[0]  = i_JOYSTICK0[1];
assign          IN1[1]  = i_JOYSTICK0[0];
assign          IN1[2]  = i_JOYSTICK0[3];
assign          IN1[3]  = i_JOYSTICK0[2];
assign          IN1[4]  = DIPSW3[4] ? i_JOYSTICK0[7] : i_JOYSTICK0[9]; //btn 1
assign          IN1[5]  = DIPSW3[4] ? i_JOYSTICK0[8] : i_JOYSTICK0[7]; //btn 2
assign          IN1[6]  = DIPSW3[4] ? 1'b0           : i_JOYSTICK0[8]; //btn 3
assign          IN1[7]  = DIPSW3[3];

//Player 2 control
assign          IN2[0]  = i_JOYSTICK1[1];
assign          IN2[1]  = i_JOYSTICK1[0];
assign          IN2[2]  = i_JOYSTICK1[3];
assign          IN2[3]  = i_JOYSTICK1[2];
assign          IN2[4]  = DIPSW3[4] ? i_JOYSTICK1[7] : i_JOYSTICK1[9]; //btn 1
assign          IN2[5]  = DIPSW3[4] ? i_JOYSTICK1[8] : i_JOYSTICK1[7]; //btn 2
assign          IN2[6]  = DIPSW3[4] ? 1'b0           : i_JOYSTICK1[8]; //btn 3
assign          IN2[7]  = 1'b0;



///////////////////////////////////////////////////////////
//////  GAME BOARD
////

Salamander_top gameboard_top (
    .i_EMU_CLK72M               (i_EMU_MCLK                 ),
    .i_EMU_CLK57M               (i_EMU_SCLK                 ),
    .i_EMU_INITRST_n            (~i_EMU_INITRST             ),
    .i_EMU_SOFTRST_n            (~i_EMU_SOFTRST & rom_download_done),

    .o_HBLANK                   (o_HBLANK                   ),
    .o_VBLANK                   (o_VBLANK                   ),
    .o_HSYNC                    (o_HSYNC                    ),
    .o_VSYNC                    (o_VSYNC                    ),
    .o_VIDEO_CEN                (o_VIDEO_CEN                ),
    .o_VIDEO_DEN                (o_VIDEO_DEN                ),

    .o_VIDEO_R                  (o_VIDEO_R                  ),
    .o_VIDEO_G                  (o_VIDEO_G                  ),
    .o_VIDEO_B                  (o_VIDEO_B                  ),

    .o_SND_L                    (o_SND_L                    ),
    .o_SND_R                    (o_SND_R                    ),

    .i_IN0                      (IN0                        ),
    .i_IN1                      (IN1                        ),
    .i_IN2                      (IN2                        ),
    .i_DIPSW1                   (DIPSW1                     ),
    .i_DIPSW2                   (DIPSW2                     ),

    .o_EMU_DATAROM_ADDR         (datarom_addr               ),
    .i_EMU_DATAROM_DATA         (datarom_q                  ),
    .o_EMU_DATAROM_RDRQ         (datarom_rdrq               ),

    .o_EMU_PROGROM_ADDR         (progrom_addr               ),
    .i_EMU_PROGROM_DATA         (progrom_q                  ),
    .o_EMU_PROGROM_RDRQ         (progrom_rdrq               ),

    .o_EMU_PCMROM_ADDR          (pcmrom_addr                ),
    .i_EMU_PCMROM_DATA          (pcmrom_addr[0] ? pcmrom_q[15:8] : pcmrom_q[7:0]),
    .o_EMU_PCMROM_RDRQ          (pcmrom_rdrq                ),

    //PROM programming
    .i_EMU_PROM_ADDR            (prog_bram_addr             ),
    .i_EMU_PROM_DATA            (prog_bram_din_buf          ),
    .i_EMU_PROM_WR              (prog_bram_wr               ),
    
    .i_EMU_PROM_SNDROM_CS       (prog_bram_sndrom_cs        ),
    .i_EMU_PROM_VLMROM_CS       (prog_bram_vlmrom_cs        )
);

endmodule