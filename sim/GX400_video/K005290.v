/*
    tilemapsr TILEMAP SHIFT REGISTER ARRAY
*/

module K005290 (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,

    //pixel data
    input   wire    [31:0]  i_GFXDATA,

    //hcounter
    input   wire            i_ABS_n4H,
    input   wire            i_ABS_2H,

    //flips
    input   wire            i_AFF,
    input   wire            i_BFF,

    //sr mode
    input   wire    [1:0]   i_A_MODE,
    input   wire    [1:0]   i_B_MODE,

    //pixel output
    output  reg     [3:0]   o_A_PIXEL,
    output  reg     [3:0]   o_B_PIXEL,

    //pixel transparent flag
    output  wire            o_A_TRN_n,
    output  wire            o_B_TRN_n
);


///////////////////////////////////////////////////////////
//////  TILELINE LATCH
////

/*
    pixel   0 1 2 3 4 5 6 7
    1H      _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    2H      ___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    /4H     ¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|
    4H      _______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|
*/

reg             ABS_2H_dl;
always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        ABS_2H_dl <= i_ABS_2H;
    end
end

wire            pixel3_n = ~(i_ABS_2H & ABS_2H_dl & i_ABS_n4H);
wire            pixel7_n = ~(i_ABS_2H & ABS_2H_dl & ~i_ABS_n4H);


//
//  tileline latches
//

reg     [31:0]  A_TILELINELATCH;
reg     [31:0]  B_TILELINELATCH;

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(!pixel7_n) begin //posedge of px7
            A_TILELINELATCH <= i_GFXDATA;
        end
    end
end

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(!pixel3_n) begin //posedge of px3
            B_TILELINELATCH <= i_GFXDATA;
        end
    end
end








///////////////////////////////////////////////////////////
//////  PIXEL SHIFT REGISTER
////

//
//  TM-A shift register
//

reg     [3:0]   A_PIXEL0 = 4'h0;
reg     [3:0]   A_PIXEL1 = 4'h0;
reg     [3:0]   A_PIXEL2 = 4'h0;
reg     [3:0]   A_PIXEL3 = 4'h0;
reg     [3:0]   A_PIXEL4 = 4'h0;
reg     [3:0]   A_PIXEL5 = 4'h0;
reg     [3:0]   A_PIXEL6 = 4'h0;
reg     [3:0]   A_PIXEL7 = 4'h0;

reg     [3:0]   A_PIXEL_DELAY1;
reg     [3:0]   A_PIXEL_DELAY2;
reg     [3:0]   A_PIXEL_DELAY3;
            
always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        case(i_A_MODE)
            2'b00: begin end
            2'b01: begin //shift reversed direction(right)                 
                A_PIXEL0 <= 4'h0;
                A_PIXEL1 <= A_PIXEL0;
                A_PIXEL2 <= A_PIXEL1;
                A_PIXEL3 <= A_PIXEL2;
                A_PIXEL4 <= A_PIXEL3;
                A_PIXEL5 <= A_PIXEL4;
                A_PIXEL6 <= A_PIXEL5;
                A_PIXEL7 <= A_PIXEL6;
            end
            2'b10: begin
                A_PIXEL0 <= A_PIXEL1;
                A_PIXEL1 <= A_PIXEL2;
                A_PIXEL2 <= A_PIXEL3;
                A_PIXEL3 <= A_PIXEL4;
                A_PIXEL4 <= A_PIXEL5;
                A_PIXEL5 <= A_PIXEL6;
                A_PIXEL6 <= A_PIXEL7;
                A_PIXEL7 <= 4'h0;    
            end
            2'b11: begin
                A_PIXEL0 <= A_TILELINELATCH[31:28];
                A_PIXEL1 <= A_TILELINELATCH[27:24];
                A_PIXEL2 <= A_TILELINELATCH[23:20];
                A_PIXEL3 <= A_TILELINELATCH[19:16];
                A_PIXEL4 <= A_TILELINELATCH[15:12];
                A_PIXEL5 <= A_TILELINELATCH[11:8];
                A_PIXEL6 <= A_TILELINELATCH[7:4];
                A_PIXEL7 <= A_TILELINELATCH[3:0];
            end
        endcase
    end
end

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(i_AFF == 1'b0)  begin
            A_PIXEL_DELAY1 <= A_PIXEL0; //shift normally
        end
        else begin
            A_PIXEL_DELAY1 <= A_PIXEL7; //shift reversed direction(right)
        end

        A_PIXEL_DELAY2 <= A_PIXEL_DELAY1;
        A_PIXEL_DELAY3 <= A_PIXEL_DELAY2;

        o_A_PIXEL <= A_PIXEL_DELAY3;
    end
end

assign  o_A_TRN_n = |{o_A_PIXEL};


//
//  TM-B shift register
//

reg     [3:0]   B_PIXEL0 = 4'h0;
reg     [3:0]   B_PIXEL1 = 4'h0;
reg     [3:0]   B_PIXEL2 = 4'h0;
reg     [3:0]   B_PIXEL3 = 4'h0;
reg     [3:0]   B_PIXEL4 = 4'h0;
reg     [3:0]   B_PIXEL5 = 4'h0;
reg     [3:0]   B_PIXEL6 = 4'h0;
reg     [3:0]   B_PIXEL7 = 4'h0;

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        case(i_B_MODE)
            2'b00: begin end
            2'b01: begin
                B_PIXEL0 <= 4'h0;
                B_PIXEL1 <= B_PIXEL0;
                B_PIXEL2 <= B_PIXEL1;
                B_PIXEL3 <= B_PIXEL2;
                B_PIXEL4 <= B_PIXEL3;
                B_PIXEL5 <= B_PIXEL4;
                B_PIXEL6 <= B_PIXEL5;
                B_PIXEL7 <= B_PIXEL6;
            end
            2'b10: begin
                B_PIXEL0 <= B_PIXEL1;
                B_PIXEL1 <= B_PIXEL2;
                B_PIXEL2 <= B_PIXEL3;
                B_PIXEL3 <= B_PIXEL4;
                B_PIXEL4 <= B_PIXEL5;
                B_PIXEL5 <= B_PIXEL6;
                B_PIXEL6 <= B_PIXEL7;
                B_PIXEL7 <= 4'h0;
            end
            2'b11: begin
                B_PIXEL0 <= B_TILELINELATCH[31:28];
                B_PIXEL1 <= B_TILELINELATCH[27:24];
                B_PIXEL2 <= B_TILELINELATCH[23:20];
                B_PIXEL3 <= B_TILELINELATCH[19:16];
                B_PIXEL4 <= B_TILELINELATCH[15:12];
                B_PIXEL5 <= B_TILELINELATCH[11:8];
                B_PIXEL6 <= B_TILELINELATCH[7:4];
                B_PIXEL7 <= B_TILELINELATCH[3:0];
            end
        endcase
    end
end

always @(*) begin
    if(i_BFF == 1'b0) begin
        o_B_PIXEL <= B_PIXEL0; //shift normally
    end
    else begin
        o_B_PIXEL <= B_PIXEL7; //shift reversed direction(right)
    end
end

assign  o_B_TRN_n = |{o_B_PIXEL};


endmodule