module Salamander_sound (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK3M58_PCEN,
    input   wire            i_EMU_CLK3M58_NCEN,

    input   wire            i_EMU_INITRST_n,
    input   wire            i_EMU_SOFTRST_n,

    input   wire    [7:0]   i_SNDCODE,
    input   wire            i_SNDINT,

    output  reg signed      [15:0]  o_SND_R, o_SND_L,

    output  wire    [16:0]  o_EMU_PCMROM_ADDR,
    input   wire    [7:0]   i_EMU_PCMROM_DATA,
    output  wire            o_EMU_PCMROM_RDRQ,

    input   wire            i_EMU_PROM_CLK,
    input   wire    [15:0]  i_EMU_PROM_ADDR,
    input   wire    [7:0]   i_EMU_PROM_DATA,
    input   wire            i_EMU_PROM_WR,
    
    input   wire            i_EMU_PROM_SNDROM_CS,
    input   wire            i_EMU_PROM_VLMROM_CS
);



///////////////////////////////////////////////////////////
//////  CLOCK AND RESET
////

wire            sndcpu_rst = ~i_EMU_INITRST_n | ~i_EMU_SOFTRST_n;
wire            mclk = i_EMU_MCLK;
wire            clk3m58_pcen = i_EMU_CLK3M58_PCEN;
wire            clk3m58_ncen = i_EMU_CLK3M58_NCEN;



///////////////////////////////////////////////////////////
//////  SOUND CPU
////

wire    [15:0]  sndcpu_addr;
reg     [7:0]   sndcpu_di;
wire    [7:0]   sndcpu_do;
wire            sndcpu_wr_n, sndcpu_rd_n;

wire            sndcpu_mreq_n;
wire            sndcpu_iorq_n;
wire            sndcpu_rfsh_n;
reg             sndcpu_int_n;

T80pa u_sndcpu (
    .RESET_n                    (~sndcpu_rst                ),
    .CLK                        (mclk                       ),
    .CEN_p                      (clk3m58_pcen               ),
    .CEN_n                      (clk3m58_ncen               ),
    .WAIT_n                     (1'b1                       ),
    .INT_n                      (sndcpu_int_n               ),
    .NMI_n                      (1'b1                       ),
    .RD_n                       (sndcpu_rd_n                ),
    .WR_n                       (sndcpu_wr_n                ),
    .A                          (sndcpu_addr                ),
    .DI                         (sndcpu_di                  ),
    .DO                         (sndcpu_do                  ),
    .IORQ_n                     (sndcpu_iorq_n              ),
    .M1_n                       (                           ),
    .MREQ_n                     (sndcpu_mreq_n              ),
    .BUSRQ_n                    (1'b1                       ),
    .BUSAK_n                    (                           ),
    .RFSH_n                     (sndcpu_rfsh_n              ),
    .out0                       (1'b0                       ), //?????
    .HALT_n                     (                           )
);



///////////////////////////////////////////////////////////
//////  SOUND IRQ
////

reg     [3:0]   sndint_dly; //CDC!!!
always @(posedge mclk) begin
    sndint_dly[0] <= i_SNDINT;
    sndint_dly[3:1] <= sndint_dly[2:0];

    if(sndcpu_rst | ~sndcpu_iorq_n) sndcpu_int_n <= 1'b1;
    else begin
        if(sndint_dly[3:2] == 2'b01) sndcpu_int_n <= 1'b0;
    end
end



///////////////////////////////////////////////////////////
//////  ADDRESS DECODER
////

reg             vlmctrl_wr, vlmbusy_rd, vlmparam_wr;
reg             ymfm_cs, pcm_cs;
reg             sndcode_rd, sndram_cs;
wire            sndrom_rd = ~sndcpu_addr[15];

always @(*) begin
    vlmctrl_wr = 1'b0;
    vlmbusy_rd = 1'b0;
    vlmparam_wr = 1'b0;
    ymfm_cs = 1'b0;
    pcm_cs = 1'b0;
    sndcode_rd = 1'b0;
    sndram_cs = 1'b0;

    if(!sndcpu_mreq_n && sndcpu_rfsh_n && sndcpu_addr[15]) begin
        case(sndcpu_addr[14:12])
            3'd0: sndram_cs = 1'b1;
            3'd1: ;
            3'd2: sndcode_rd = 1'b1;
            3'd3: pcm_cs = 1'b1;
            3'd4: ymfm_cs = 1'b1;
            3'd5: vlmparam_wr = 1'b1;
            3'd6: vlmbusy_rd = 1'b1;
            3'd7: vlmctrl_wr = 1'b1;
        endcase
    end
end



///////////////////////////////////////////////////////////
//////  SOUND PROGRAM SPACE
////

wire    [7:0]   sndrom_q;
Salamander_PROM_DC #(.AW(15), .DW(8), .simhexfile()) u_sndrom (
    .i_PROG_CLK                 (i_EMU_PROM_CLK             ),
    .i_PROG_ADDR                (i_EMU_PROM_ADDR[14:0]      ),
    .i_PROG_DIN                 (i_EMU_PROM_DATA            ),
    .i_PROG_CS                  (i_EMU_PROM_SNDROM_CS       ),
    .i_PROG_WR                  (i_EMU_PROM_WR              ),

    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (sndcpu_addr[14:0]          ),
    .o_DOUT                     (sndrom_q                   ),
    .i_RD                       (sndrom_rd                  )
);

wire    [7:0]  sndram_q;
Salamander_SRAM #(.AW(11), .DW(8), .simhexfile()) u_sndram (
    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (sndcpu_addr[10:0]          ),
    .i_DIN                      (sndcpu_do                  ),
    .o_DOUT                     (sndram_q                   ),
    .i_WR                       (sndram_cs && ~sndcpu_wr_n  ),
    .i_RD                       (sndram_cs && ~sndcpu_rd_n  )
);



///////////////////////////////////////////////////////////
//////  YM2151
////

wire    [7:0]   ymfm_q;
wire signed [15:0]  ymfm_r, ymfm_l;
IKAOPM #(
    .FULLY_SYNCHRONOUS          (1                          ),
    .FAST_RESET                 (1                          ),
    .USE_BRAM                   (0                          )
) u_ikaopm (
    .i_EMUCLK                   (i_EMU_MCLK                 ),

    .i_phiM_PCEN_n              (~clk3m58_pcen              ),

    .i_IC_n                     (~sndcpu_rst                ),

    .o_phi1                     (                           ),

    .i_CS_n                     (~ymfm_cs                   ),
    .i_RD_n                     (sndcpu_rd_n                ),
    .i_WR_n                     (sndcpu_wr_n                ),
    .i_A0                       (sndcpu_addr[0]             ),

    .i_D                        (sndcpu_do                  ),
    .o_D                        (ymfm_q                     ),
    .o_D_OE                     (                           ),

    .o_CT1                      (                           ),
    .o_CT2                      (                           ),

    .o_IRQ_n                    (                           ),

    .o_SH1                      (                           ),
    .o_SH2                      (                           ),

    .o_SO                       (                           ),

    .o_EMU_R_SAMPLE             (                           ),
    .o_EMU_R_EX                 (                           ),
    .o_EMU_R                    (ymfm_r                     ),

    .o_EMU_L_SAMPLE             (                           ),
    .o_EMU_L_EX                 (                           ),
    .o_EMU_L                    (ymfm_l                     )
);



///////////////////////////////////////////////////////////
//////  VLM5030
////

//VLM5030 control latches
reg     [7:0]   vlm_param_latch;
reg     [2:0]   vlm_ctrl_latch = 3'b000;

always @(posedge mclk) begin
    if(vlmparam_wr && !sndcpu_wr_n) vlm_param_latch <= sndcpu_do;
    if(vlmctrl_wr && !sndcpu_wr_n) vlm_ctrl_latch <= sndcpu_do[2:0];
end

//VLM5030 side wires
wire            vlm_rst = vlm_ctrl_latch[0];
wire            vlm_st = vlm_ctrl_latch[1];
wire            vlm_busy;

wire    [13:0]  vlm_addr;
wire            vlm_me_n; //Memory Enable
wire signed     [9:0]   vlm_snd;

//VLM5030 command rom
wire    [7:0]   vlmrom_q;
Salamander_PROM_DC #(.AW(14), .DW(8), .simhexfile()) u_vlmrom (
    .i_PROG_CLK                 (i_EMU_PROM_CLK             ),
    .i_PROG_ADDR                (i_EMU_PROM_ADDR[13:0]      ),
    .i_PROG_DIN                 (i_EMU_PROM_DATA            ),
    .i_PROG_CS                  (i_EMU_PROM_VLMROM_CS       ),
    .i_PROG_WR                  (i_EMU_PROM_WR              ),

    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (vlm_addr                   ),
    .o_DOUT                     (vlmrom_q                   ),
    .i_RD                       (~vlm_me_n                  )
);

//VLM5030 bus
wire    [7:0]   vlm_di = vlm_ctrl_latch[2] ? vlmrom_q : vlm_param_latch;

//main chip
vlm5030_gl u_vlm (
    .i_clk                      (i_EMU_MCLK                 ),
    .i_oscen                    (clk3m58_pcen               ),
    .i_rst                      (vlm_rst                    ),
    .i_start                    (vlm_st                     ),
    .i_vcu                      (1'b0                       ),
    .i_tst1                     (1'b0                       ),
    .i_d                        (vlm_di                     ),
    .o_a                        ({2'bzz, vlm_addr}          ),
    .o_me_l                     (vlm_me_n                   ),
    .o_bsy                      (vlm_busy                   ),
    .o_audio                    (vlm_snd                    )
);



///////////////////////////////////////////////////////////
//////  K007232
////

//PCM sample ROM
wire    [7:0]   pcmrom_q;
wire    [16:0]  pcmrom_addr;
wire    [6:0]   pcm_snd_a, pcm_snd_b;

//PCM volume register
wire            pcm_vol_wr_n;
reg     [7:0]   pcm_vol;

K007232 u_pcm (
    .i_EMUCLK                   (i_EMU_MCLK                 ),
    .i_PCEN                     (clk3m58_pcen               ), 
    .i_NCEN                     (clk3m58_ncen               ),
    .i_RST_n                    (~sndcpu_rst                ),

    .i_RCS_n                    (1'b1                       ),
    .i_DACS_n                   (~pcm_cs                    ),
    .i_RD_n                     (1'b1                       ),
    
    .i_AB                       ({sndcpu_addr[3:1], ~sndcpu_addr[0]}),
    .i_DB                       (sndcpu_do                  ),
    .o_DB                       (                           ),
    .o_DB_OE                    (                           ),

    .o_SLEV_n                   (pcm_vol_wr_n               ),
    .o_Q_n                      (                           ),
    .o_E_n                      (                           ),

    .i_RAM                      (pcmrom_q                   ),
    .o_RAM                      (                           ),
    .o_RAM_OE                   (                           ),
    .o_SA                       (pcmrom_addr                ),

    .o_ASD                      (pcm_snd_a                  ),
    .o_BSD                      (pcm_snd_b                  ),

    .o_CK2M                     (                           )
);

/*
F007232 u_pcm(
    .CLK                        (i_EMU_MCLK                 ),
    .clk_en_p                   (clk3m58_pcen               ),
    .clk_en_n                   (clk3m58_ncen               ),
    .NRES                       (~sndcpu_rst                ),
    
    .NRCS                       (1'b1                       ),
    .DACS                       (~pcm_cs                    ),
    .NRD                        (1'b1                       ),
    
    .AB                         ({sndcpu_addr[3:1], ~sndcpu_addr[0]}),
    .DB                         (sndcpu_do                  ),

    .RAM_IN                     (pcmrom_q                   ),
    .SA                         (pcmrom_addr                ),
    .ASD                        (pcm_snd_a                  ),
    .BSD                        (pcm_snd_b                  ),
    .SLEV                       (pcm_vol_wr_n               )
);*/


//volume latch
always @(posedge i_EMU_MCLK) begin
    if(!pcm_vol_wr_n) pcm_vol <= sndcpu_do;
end

//SDRAM interface - CDC!!!!!
reg     [16:0]  pcmrom_addr_z;
reg             pcmrom_rdrq, pcmrom_rdrq_z, pcmrom_rdrq_zz, pcmrom_rdrq_zzz;
always @(posedge i_EMU_MCLK) begin
    pcmrom_addr_z <= pcmrom_addr;
end
always @(posedge i_EMU_PROM_CLK) begin
    pcmrom_rdrq <= pcmrom_addr_z != pcmrom_addr;
    pcmrom_rdrq_z <= pcmrom_rdrq;
    pcmrom_rdrq_zz <= pcmrom_rdrq_z;
end

assign  o_EMU_PCMROM_ADDR = pcmrom_addr;
assign  o_EMU_PCMROM_RDRQ = pcmrom_rdrq_z && !pcmrom_rdrq_zz; //posedge
assign  pcmrom_q = i_EMU_PCMROM_DATA;

//PROM
/*
Salamander_PROM_DC #(.AW(17), .DW(8), .simhexfile("rom_10a.txt")) u_pcmrom (
    .i_PROG_CLK                 (i_EMU_PROM_CLK             ),
    .i_PROG_ADDR                (17'h0                      ),
    .i_PROG_DIN                 (i_EMU_PROM_DATA            ),
    .i_PROG_CS                  (1'b0                       ),
    .i_PROG_WR                  (1'b0                       ),

    .i_MCLK                     (i_EMU_MCLK                 ),
    .i_ADDR                     (pcmrom_addr                ),
    .o_DOUT                     (pcmrom_q                   ),
    .i_RD                       (1'b1                       )
);
*/

wire signed [15:0]  pcm_a_signed = $signed({9'd0, pcm_snd_a}) - 16'sd64;
wire signed [15:0]  pcm_b_signed = $signed({9'd0, pcm_snd_b}) - 16'sd64;

reg signed [15:0]  pcm_mixed;
always @(posedge mclk) begin
    pcm_mixed <= (pcm_a_signed * $signed({1'b0, pcm_vol[7:4]})) + (pcm_b_signed * $signed({1'b0, pcm_vol[3:0]}));
end



///////////////////////////////////////////////////////////
//////  MIXER
////

always @(posedge mclk) begin
    o_SND_R <= ymfm_r + (vlm_snd * 6'sd45) + (pcm_mixed * 6'sd2);
    o_SND_L <= ymfm_l + (vlm_snd * 6'sd45) + (pcm_mixed * 6'sd2);
end



///////////////////////////////////////////////////////////
//////  BUS MUX
////

always @(*) begin
    sndcpu_di = 8'hFF;

    if(sndrom_rd) sndcpu_di = sndrom_q;
    else if(sndram_cs) sndcpu_di = sndram_q;
    else if(ymfm_cs) sndcpu_di = ymfm_q;
    else if(sndcode_rd) sndcpu_di = i_SNDCODE;
    else if(vlmbusy_rd) sndcpu_di = {7'b0000_000, vlm_busy};
end



endmodule