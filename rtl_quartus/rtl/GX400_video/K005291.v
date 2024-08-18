/*
    tilemapgen TILEMAP GENERATOR
*/

module K005291 (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,

    //CPU flip
    input   wire            i_HFLIP,
    input   wire            i_VFLIP,

    //HV counters
    input   wire            i_ABS_n256H,
    input   wire            i_ABS_128HA,
    input   wire            i_ABS_64H, 
    input   wire            i_ABS_32H, 
    input   wire            i_ABS_16H, 
    input   wire            i_ABS_8H,  
    input   wire            i_ABS_4H,  
    input   wire            i_ABS_2H,
    input   wire            i_ABS_1H,

    input   wire            i_ABS_128V,
    input   wire            i_ABS_64V,
    input   wire            i_ABS_32V,
    input   wire            i_ABS_16V,
    input   wire            i_ABS_8V, 
    input   wire            i_ABS_4V, 
    input   wire            i_ABS_2V,
    input   wire            i_ABS_1V,
    
    input   wire            i_VCLK,

    //CPU address/GFX data bus
    input   wire    [11:0]  i_CPU_ADDR,
    input   wire    [7:0]   i_GFXDATA,

    //to CHARRAM
    output  reg     [2:0]   o_TILELINEADDR,

    //to VRAM1+2
    output  wire    [11:0]  o_VRAMADDR,

    output  wire            o_SHIFTA1,
    output  wire            o_SHIFTA2,
    output  wire            o_SHIFTB
);


wire            ABS_4H      = i_ABS_4H;
wire            ABS_2H      = i_ABS_2H;
wire            ABS_1H      = i_ABS_1H;

wire            FLIP_n256H  = i_ABS_n256H ^ i_HFLIP;
wire            FLIP_128HA  = i_ABS_128HA ^ i_HFLIP;
wire            FLIP_64H    = i_ABS_64H ^ i_HFLIP;
wire            FLIP_32H    = i_ABS_32H ^ i_HFLIP;
wire            FLIP_16H    = i_ABS_16H ^ i_HFLIP;
wire            FLIP_8H     = i_ABS_8H ^ i_HFLIP;
wire            FLIP_4H     = i_ABS_4H ^ i_HFLIP;
wire            FLIP_2H     = i_ABS_2H ^ i_HFLIP;
wire            FLIP_1H     = i_ABS_1H ^ i_HFLIP;

wire            FLIP_128V   = i_ABS_128V ^ i_VFLIP;
wire            FLIP_64V    = i_ABS_64V ^ i_VFLIP;
wire            FLIP_32V    = i_ABS_32V ^ i_VFLIP;
wire            FLIP_16V    = i_ABS_16V ^ i_VFLIP;
wire            FLIP_8V     = i_ABS_8V ^ i_VFLIP;
wire            FLIP_4V     = i_ABS_4V ^ i_VFLIP;
wire            FLIP_2V     = i_ABS_2V ^ i_VFLIP;
wire            FLIP_1V     = i_ABS_1V ^ i_VFLIP;



///////////////////////////////////////////////////////////
//////  TILEMAP SCROLL
////

//
//  HSCROLL
//

reg     [8:0]   TMA_HSCROLL_VALUE = 9'h1F;
reg     [8:0]   TMB_HSCROLL_VALUE = 9'h1F; 
always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(i_VCLK) begin
            case({ABS_4H, ABS_2H, ABS_1H})
                3'd1: begin TMA_HSCROLL_VALUE[7:0] <= i_GFXDATA;    end //latch TM-A lower bits at px1
                3'd3: begin TMA_HSCROLL_VALUE[8]   <= i_GFXDATA[0]; end //latch TM-B high bit at px3
                3'd5: begin TMB_HSCROLL_VALUE[7:0] <= i_GFXDATA;    end //latch TM-A lower bits at px5
                3'd7: begin TMB_HSCROLL_VALUE[8]   <= i_GFXDATA[0]; end //latch TM-B high bit at px7
                default: begin end
            endcase
        end
    end
end

//vram address
wire    [5:0]   horizontal_tile_addr; //6 bit: 64 horizontal tiles(512 horizontal pixels)
assign  horizontal_tile_addr =  (ABS_4H == 1'b0) ? 
                                    TMA_HSCROLL_VALUE[8:3] + {FLIP_n256H, FLIP_128HA, FLIP_64H, FLIP_32H, FLIP_16H, FLIP_8H} :
                                    TMB_HSCROLL_VALUE[8:3] + {FLIP_n256H, FLIP_128HA, FLIP_64H, FLIP_32H, FLIP_16H, FLIP_8H};

//shift
assign  o_SHIFTA1 = (TMA_HSCROLL_VALUE[2:0] + {FLIP_4H, FLIP_2H, FLIP_1H} == 3'd7) ? 1'b0 : 1'b1;
assign  o_SHIFTA2 = (TMA_HSCROLL_VALUE[2:0] + {FLIP_4H, FLIP_2H, FLIP_1H} == 3'd3) ? 1'b0 : 1'b1;
assign  o_SHIFTB  = (TMB_HSCROLL_VALUE[2:0] + {FLIP_4H, FLIP_2H, FLIP_1H} == 3'd3) ? 1'b0 : 1'b1;



//
//  VSCROLL
//

reg     [7:0]   TMAB_VSCROLL_VALUE = 8'hF;
always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        case({ABS_4H, ABS_2H, ABS_1H})
            3'd3: begin TMAB_VSCROLL_VALUE     <= i_GFXDATA; //latch TM-B second at px3
                        o_TILELINEADDR         <= TMAB_VSCROLL_VALUE[2:0] + {FLIP_4V, FLIP_2V, FLIP_1V}; end
            3'd7: begin TMAB_VSCROLL_VALUE     <= i_GFXDATA; //latch TM-A first at px7 
                        o_TILELINEADDR         <= TMAB_VSCROLL_VALUE[2:0] + {FLIP_4V, FLIP_2V, FLIP_1V}; end
            default: begin end
        endcase
    end
end

//pixel 3: get TM-B vscroll value
//pixel 7: get TM-A vscroll value/update TM-B line address
//pixel 3: get TM-B vscroll value/update TM-A line address

//vram address
wire    [7:0]   vertical_tile_addr; //[7:3] 5 bit: 32 vertical tiles(512 horizontal pixels)
assign  vertical_tile_addr = TMAB_VSCROLL_VALUE + {FLIP_128V, FLIP_64V, FLIP_32V, FLIP_16V, FLIP_8V, FLIP_4V, FLIP_2V, FLIP_1V};



///////////////////////////////////////////////////////////
//////  VRAM TILE ADDRESS
////

assign  o_VRAMADDR =    (ABS_2H == 1'b0) ?
                            i_CPU_ADDR :
                            {ABS_4H, vertical_tile_addr[7:3], horizontal_tile_addr};



endmodule