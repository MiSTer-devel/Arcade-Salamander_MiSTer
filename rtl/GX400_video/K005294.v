/*
    objlinelatch "LINELATCH"
*/

module K005294 (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,

    input   wire    [31:0]  i_GFXDATA,
    input   wire    [3:0]   i_OC,

    input   wire            i_TILELINELATCH_n,

    output  reg     [7:0]   o_DA,
    output  reg     [7:0]   o_DB,

    //control signals
    input   wire            i_WRTIME2,
    input   wire            i_COLORLATCH_n,
    input   wire            i_XPOS_D0,
    input   wire            i_PIXELLATCH_WAIT_n,
    input   wire            i_LATCH_A_D2,
    input   wire    [2:0]   i_PIXELSEL
);



///////////////////////////////////////////////////////////
//////  COLORLATCH
////

//latches pixel palette data from VRAM
reg     [3:0]   OBJ_PALETTE;

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(!i_COLORLATCH_n) OBJ_PALETTE <= i_OC;
    end
end








///////////////////////////////////////////////////////////
//////  TILELINE LATCH
////

reg     [31:0]  OBJ_TILELINELATCH;

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(!i_TILELINELATCH_n) OBJ_TILELINELATCH <= i_GFXDATA; //posedge of px7
    end
end








///////////////////////////////////////////////////////////
//////  PIXEL SELECT / PIXELLATCH_WAIT / WRTIME2 DELAY
////

reg     [2:0]   pixelsel_dly [3:0];
reg     [1:0]   wrtime2_dly;
reg     [3:0]   pixellatch_wait_dly;

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        pixelsel_dly[0] <= i_PIXELSEL;
        pixelsel_dly[1] <= pixelsel_dly[0];
        pixelsel_dly[2] <= pixelsel_dly[1];
        pixelsel_dly[3] <= pixelsel_dly[2];
    end
end


always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        wrtime2_dly[0] <= i_WRTIME2;
        wrtime2_dly[1] <= wrtime2_dly[0];
    end
end


always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        pixellatch_wait_dly[3:1] <= pixellatch_wait_dly[2:0];
        pixellatch_wait_dly[0] <= ~i_PIXELLATCH_WAIT_n;
    end
end








///////////////////////////////////////////////////////////
//////  PIXEL SELECTOR AND PIXEL LATCH
////

wire            pixellatch_n = wrtime2_dly[1] | pixellatch_wait_dly[2];
reg     [3:0]   OBJ_PIXEL_LATCHED;
reg     [3:0]   OBJ_PIXEL_UNLATCHED;

always @(*)
begin
    case(pixelsel_dly[3])
        3'b000: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[31:28]; //pixel 0(A)
        3'b001: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[27:24]; //pixel 1(B)
        3'b010: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[23:20];
        3'b011: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[19:16];
        3'b100: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[15:12];
        3'b101: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[11:8];
        3'b110: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[7:4];
        3'b111: OBJ_PIXEL_UNLATCHED <= OBJ_TILELINELATCH[3:0];
    endcase
end

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(!pixellatch_n) OBJ_PIXEL_LATCHED <= OBJ_PIXEL_UNLATCHED;
    end
end







///////////////////////////////////////////////////////////
//////  DOUT MUX
////

always @(*)
begin
    case({pixellatch_wait_dly[2], i_XPOS_D0})
        2'b00: begin
            o_DA <= {OBJ_PALETTE, OBJ_PIXEL_LATCHED};
            o_DB <= {OBJ_PALETTE, OBJ_PIXEL_UNLATCHED};
        end
        2'b01: begin
            o_DA <= {OBJ_PALETTE, OBJ_PIXEL_UNLATCHED};
            o_DB <= {OBJ_PALETTE, OBJ_PIXEL_LATCHED};
        end
        2'b10: begin
            o_DA <= {OBJ_PALETTE, OBJ_PIXEL_LATCHED};
            o_DB <= {4'b0000, 4'b0000};
        end
        2'b11: begin
            o_DA <= {4'b0000, 4'b0000};
            o_DB <= {OBJ_PALETTE, OBJ_PIXEL_LATCHED};
        end
    endcase
end

endmodule