/*
    K005293 PRIORITY HANDLER
*/

module K005293
(
    //emulator
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,

    //flip
    input   wire            i_HFLIP,

    //clocked shift
    input   wire            i_SHIFTA1,
    input   wire            i_SHIFTA2,
    input   wire            i_SHIFTB,

    //timings
    input   wire            i_ABS_n1H,
    input   wire            i_ABS_n6n7H,
    input   wire            i_ABS_n2n3H,

    //pixel input
    input   wire    [3:0]   i_A_PIXEL,
    input   wire    [3:0]   i_B_PIXEL,
    //sprite pixels
    input   wire    [15:0]  i_OBJBUF_DATA,

    //pixel transparent flag
    input   wire            i_A_TRN_n,
    input   wire            i_B_TRN_n,

    //tile properties
    input   wire            i_VHFF,
    input   wire    [6:0]   i_VC,
    input   wire    [3:0]   i_PR,

    //delayed flips
    output  wire            o_A_FLIP,
    output  wire            o_B_FLIP,

    //palette code
    output  reg     [10:0]  o_CD
);



///////////////////////////////////////////////////////////
//////  PROPERTY DATA SHIFTER
////

/*
    if SCROLL = 0

            i_ABS_n2n3H     i_ABS_n6n7H     i_ABS_n2n3H     i_ABS_n6n7H       
                                            i_SHIFTA1       i_SHIFTA2
                                                            i_SHIFTB
    TM-A    DELAY1      ->  DELAY2      ->  DELAY3      ->  DELAY4
    TM-B                    DELAY1      ->  DELAY2      ->  DELAY3    
*/

//
//  TM-A
//

//PR4, PR3, PR2, PR1, VHFF, VC6 ... VC0

reg     [11:0]  A_PROPERTY_DELAY1;
reg     [11:0]  A_PROPERTY_DELAY2;
reg     [11:0]  A_PROPERTY_DELAY3;
reg     [11:0]  A_PROPERTY_DELAY4;

wire    [3:0]   a_pr = A_PROPERTY_DELAY4[11:8];
wire    [6:0]   a_palette = A_PROPERTY_DELAY4[6:0];
assign  o_A_FLIP = A_PROPERTY_DELAY3[7];

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if((i_ABS_n2n3H || i_ABS_n1H) == 1'b0) //posedge of pixel 3
        begin
            A_PROPERTY_DELAY1 <= {i_PR, i_VHFF, i_VC};
        end
    end
end

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if((i_ABS_n6n7H || i_ABS_n1H) == 1'b0) //posedge of pixel 7
        begin
            A_PROPERTY_DELAY2 <= A_PROPERTY_DELAY1;
        end
    end
end

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if(i_SHIFTA1 == 1'b0) //posedge of SHIFT-A1
        begin
            A_PROPERTY_DELAY3 <= A_PROPERTY_DELAY2;
        end
    end
end

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if(i_SHIFTA2 == 1'b0) //posedge of SHIFT-A2
        begin
            A_PROPERTY_DELAY4 <= A_PROPERTY_DELAY3;
        end
    end
end


//
//  TM-B
//

//PR2, PR1, VHFF, VC6 ... VC0
//note that PR3,2 bits of TM-B are always ignored: verified with a real hardware by brute-force

reg     [9:0]   B_PROPERTY_DELAY1;
reg     [9:0]   B_PROPERTY_DELAY2;
reg     [9:0]   B_PROPERTY_DELAY3;

wire    [1:0]   b_pr = B_PROPERTY_DELAY3[9:8];
wire    [6:0]   b_palette = B_PROPERTY_DELAY3[6:0];
assign  o_B_FLIP = B_PROPERTY_DELAY3[7];

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if((i_ABS_n6n7H || i_ABS_n1H) == 1'b0) //posedge of pixel 7
        begin
            B_PROPERTY_DELAY1 <= {i_PR[1:0], i_VHFF, i_VC};
        end
    end
end

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if((i_ABS_n2n3H || i_ABS_n1H) == 1'b0) //posedge of pixel 3
        begin
            B_PROPERTY_DELAY2 <= B_PROPERTY_DELAY1;
        end
    end
end

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if(i_SHIFTB == 1'b0) //posedge of SHIFT-B
        begin
            B_PROPERTY_DELAY3 <= B_PROPERTY_DELAY2;
        end
    end
end








///////////////////////////////////////////////////////////
//////  SPRITE PIXEL LATCH
////

reg     [7:0]   OBJ_PIXEL0;
reg     [7:0]   OBJ_PIXEL1;

wire    [7:0]   obj_pixel;
wire            obj_trn_n = (obj_pixel[3] | obj_pixel[2] | obj_pixel[1] | obj_pixel[0]);
assign  obj_pixel = ((~i_ABS_n1H ^ i_HFLIP) == 1'b0) ? OBJ_PIXEL0 : OBJ_PIXEL1;

always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if(i_ABS_n1H == 1'b0) //every odd pixel
        begin
            OBJ_PIXEL1 <= i_OBJBUF_DATA[15:8]; //BUFFER A = ODD PIXEL
            OBJ_PIXEL0 <= i_OBJBUF_DATA[7:0]; //BUFFER B = EVEN PIXEL
        end
    end
end








///////////////////////////////////////////////////////////
//////  PRIORITY HANDLER
////

/*
    K005293 priority handler. This chip was reverse-engineered 
    by Gilles Raimond, Olivier Scherler and me. 

    Since the exact behavior of the chip was not well known, I made a
    brute-force program to test all PR inputs. The tool was programmed with
    the advice of Raimond and Scherler, and was executed on my Bubble System.

    The source of the program can be found on my GitHub page below:
    github.com/ika-musume/BubbleDrive8/tree/master/BubbleDrive8_testprogram
    
    The chip showed us a total of 26 results and suggested that the source 
    of MAME was a very empirical result.
*/

reg     [4:0]   priority_mode; //set priority mode
reg     [1:0]   layer;
wire    [2:0]   transparency = ~{i_A_TRN_n, i_B_TRN_n, obj_trn_n};

//declare layer type
localparam TMA = 2'b00;
localparam TMB = 2'b01;
localparam OBJ = 2'b10;

//declare cases; all cases are named by Raimond and Scherler
`define PRCASE_A           5'd0  // A
`define PRCASE_A_B         5'd1  // A over B
`define PRCASE_A_B_O       5'd2  // A over B over Object
`define PRCASE_A_BMO       5'd3  // A over (B-masked Object)
`define PRCASE_A_O1        5'd4  // A over Object 1
`define PRCASE_A_O2        5'd5  // A over Object 2
`define PRCASE_A_O_B       5'd6  // A over Object over B
`define PRCASE_B           5'd7  // B
`define PRCASE_B_A         5'd8  // B over A
`define PRCASE_B_A_O       5'd9  // B over A over Object
`define PRCASE_B_O         5'd10 // B over Object
`define PRCASE_B_O_A       5'd11 // B over Object over A
`define PRCASE_O           5'd12 // Object
`define PRCASE_O_A         5'd13 // Object over A
`define PRCASE_O_A_B       5'd14 // Object over A over B
`define PRCASE_O_B         5'd15 // Object over B
`define PRCASE_O_B_A       5'd16 // Object over B over A
`define PRCASE_A_BMO_B     5'd17 // A over (B-masked Object) over B
`define PRCASE_APB_O       5'd18 // (A-punched B) over Object
`define PRCASE_APB_O_A     5'd19 // (A-punched B) over Object over A
`define PRCASE_B_AMO       5'd20 // B over (A-masked Object)
`define PRCASE_B_AMO_A     5'd21 // B over (A-masked Object) over A
`define PRCASE_BPA_O       5'd22 // (B-punched A) over Object
`define PRCASE_BPA_O_B     5'd23 // (B-punched A) over Object over B
`define PRCASE_O_APB       5'd24 // Object over (A-punched B)
`define PRCASE_O_BPA       5'd25 // Object over (B-punched A)

//X-decoder
always @(*)
begin
    casez({b_pr, a_pr}) //PR2, PR1, PR4, PR3, PR2, PR1
                       //|--TMB--| |------TMA-------|
        6'b??_0101: priority_mode <= `PRCASE_A;        // A
        6'b?1_1101: priority_mode <= `PRCASE_A_B;      // A over B
        6'b?1_1111: priority_mode <= `PRCASE_A_B_O;    // A over B over Object
        6'b00_1101: priority_mode <= `PRCASE_A_BMO;    // A over (B-masked Object)
        6'b??_0111: priority_mode <= `PRCASE_A_O1;     // A over Object 1
        6'b00_1111: priority_mode <= `PRCASE_A_O2;     // A over Object 2
        6'b10_1111: priority_mode <= `PRCASE_A_O_B;    // A over Object over B
        6'b01_00??: priority_mode <= `PRCASE_B;        // B
        6'b01_10?1: priority_mode <= `PRCASE_B_A;      // B over A
        6'b11_10?1: priority_mode <= `PRCASE_B_A_O;    // B over A over Object
        6'b11_00??: priority_mode <= `PRCASE_B_O;      // B over Object
        6'b11_1000: priority_mode <= `PRCASE_B_O;      // |
        6'b11_1010: priority_mode <= `PRCASE_B_O_A;    // B over Object over A
        6'b00_00??: priority_mode <= `PRCASE_O;        // Object
        6'b00_1?00: priority_mode <= `PRCASE_O;        // |
        6'b??_0100: priority_mode <= `PRCASE_O;        // |
        6'b??_0110: priority_mode <= `PRCASE_O_A;      // Object over A
        6'b00_1110: priority_mode <= `PRCASE_O_A;      // |
        6'b10_1110: priority_mode <= `PRCASE_O_A_B;    // Object over A over B
        6'b10_00??: priority_mode <= `PRCASE_O_B;      // Object over B
        6'b10_1000: priority_mode <= `PRCASE_O_B;      // |
        6'b10_1010: priority_mode <= `PRCASE_O_B_A;    // Object over B over A
        6'b10_1101: priority_mode <= `PRCASE_A_BMO_B;  // A over (B-masked Object) over B
        6'b?1_1100: priority_mode <= `PRCASE_APB_O;    // (A-punched B) over Object
        6'b?1_1110: priority_mode <= `PRCASE_APB_O_A;  // (A-punched B) over Object over A
        6'b01_1000: priority_mode <= `PRCASE_B_AMO;    // B over (A-masked Object)
        6'b01_1010: priority_mode <= `PRCASE_B_AMO_A;  // B over (A-masked Object) over A
        6'b00_10?1: priority_mode <= `PRCASE_BPA_O;    // (B-punched A) over Object
        6'b10_10?1: priority_mode <= `PRCASE_BPA_O_B;  // (B-punched A) over Object over B
        6'b10_1100: priority_mode <= `PRCASE_O_APB;    // Object over (A-punched B)
        6'b00_1010: priority_mode <= `PRCASE_O_BPA;    // Object over (B-punched A)
    endcase
end

//Y and Z-decoder
always @(*)
begin
    case(priority_mode)
        `PRCASE_A: begin
            case(transparency)

                3'b110: layer <= TMA;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= TMA;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMA;

            endcase
        end
        `PRCASE_A_B: begin
            case(transparency)

                3'b110: layer <= TMA;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= TMB;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end 
        `PRCASE_A_B_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= TMB;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_A_BMO: begin
            case(transparency)

                3'b110: layer <= TMA;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= OBJ;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= OBJ;

            endcase
        end
        `PRCASE_A_O1: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= OBJ;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMA;

            endcase
        end 
        `PRCASE_A_O2: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= OBJ;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= OBJ;

            endcase
        end   
        `PRCASE_A_O_B: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= OBJ;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_B: begin
            case(transparency)

                3'b110: layer <= TMB;   3'b010: layer <= TMB;   3'b011: layer <= TMB;   3'b111: layer <= TMB;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end   
        `PRCASE_B_A: begin
            case(transparency)

                3'b110: layer <= TMB;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMB;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end  
        `PRCASE_B_A_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_B_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= OBJ;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_B_O_A: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end 
        `PRCASE_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= OBJ;   3'b101: layer <= OBJ;

            endcase
        end    
        `PRCASE_O_A: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= TMA;   3'b101: layer <= OBJ;

            endcase
        end    
        `PRCASE_O_A_B: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_O_B: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_O_B_A: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_A_BMO_B: begin
            case(transparency)

                3'b110: layer <= TMA;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= OBJ;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_APB_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= OBJ;


                3'b100: layer <= TMB;   3'b000: layer <= OBJ;   3'b001: layer <= OBJ;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_APB_O_A: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= TMB;   3'b000: layer <= OBJ;   3'b001: layer <= TMA;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_B_AMO: begin
            case(transparency)

                3'b110: layer <= TMB;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= TMB;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_B_AMO_A: begin
            case(transparency)

                3'b110: layer <= TMB;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= TMB;


                3'b100: layer <= TMB;   3'b000: layer <= TMB;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_BPA_O: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= OBJ;   3'b101: layer <= OBJ;

            endcase
        end
        `PRCASE_BPA_O_B: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= TMB;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_O_APB: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= OBJ;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= OBJ;   3'b101: layer <= TMB;

            endcase
        end
        `PRCASE_O_BPA: begin
            case(transparency)

                3'b110: layer <= OBJ;   3'b010: layer <= OBJ;   3'b011: layer <= TMA;   3'b111: layer <= OBJ;


                3'b100: layer <= OBJ;   3'b000: layer <= OBJ;   3'b001: layer <= OBJ;   3'b101: layer <= OBJ;

            endcase
        end
        default: begin
            case(transparency)

                3'b110: layer <= TMA;   3'b010: layer <= TMA;   3'b011: layer <= TMA;   3'b111: layer <= TMA;


                3'b100: layer <= TMA;   3'b000: layer <= TMA;   3'b001: layer <= TMA;   3'b101: layer <= TMA;

            endcase
        end
    endcase
end

//output latch
always @(posedge i_EMU_MCLK)
begin
    if(!i_EMU_CLK6MPCEN_n)
    begin
        if(layer == TMA)
        begin
            o_CD <= {a_palette, i_A_PIXEL};
        end
        else if(layer == TMB)
        begin
            o_CD <= {b_palette, i_B_PIXEL};
        end
        else
        begin
            o_CD <= {3'b000, obj_pixel};
        end
    end
end

endmodule