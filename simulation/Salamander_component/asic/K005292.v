/*
    K005292 VIDEO TIMING GENERATOR
*/

module K005292
(
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,

    input   wire            i_MRST_n,

    input   wire            i_HFLIP,
    input   wire            i_VFLIP,

    output  wire            o_HBLANK_n,
    output  reg             o_VBLANK_n = 1'b1,
    output  reg             o_VBLANKH_n = 1'b1,

    output  wire            o_ABS_256H,
    output  wire            o_ABS_128H,
    output  wire            o_ABS_64H, 
    output  wire            o_ABS_32H, 
    output  wire            o_ABS_16H, 
    output  wire            o_ABS_8H,  
    output  wire            o_ABS_4H,  
    output  wire            o_ABS_2H,
    output  wire            o_ABS_1H,

    output  wire            o_ABS_128V,
    output  wire            o_ABS_64V,
    output  wire            o_ABS_32V,
    output  wire            o_ABS_16V,
    output  wire            o_ABS_8V, 
    output  wire            o_ABS_4V, 
    output  wire            o_ABS_2V,
    output  wire            o_ABS_1V,

    output  wire            o_FLIP_128H, 
    output  wire            o_FLIP_64H, 
    output  wire            o_FLIP_32H, 
    output  wire            o_FLIP_16H, 
    output  wire            o_FLIP_8H,  
    output  wire            o_FLIP_4H,  
    output  wire            o_FLIP_2H,
    output  wire            o_FLIP_1H,

    output  wire            o_FLIP_128V,
    output  wire            o_FLIP_64V,
    output  wire            o_FLIP_32V,
    output  wire            o_FLIP_16V,
    output  wire            o_FLIP_8V, 
    output  wire            o_FLIP_4V, 
    output  wire            o_FLIP_2V,
    output  wire            o_FLIP_1V,

    output  reg             o_VCLK,

    output  reg             o_FRAMEPARITY = 1'b0,

    output  wire            o_VSYNC_n,
    output  reg             o_CSYNC,

    output  wire    [8:0]   __REF_HCOUNTER,
    output  wire    [8:0]   __REF_VCOUNTER
);

reg             __REF_DMA_n;

///////////////////////////////////////////////////////////
//////  PIXEL COUNTER/BLANKING/SYNC/DMA
////

reg     [8:0]   horizontal_counter = 9'd511;
assign  __REF_HCOUNTER = horizontal_counter;
assign  {
            o_ABS_256H, 
            o_ABS_128H, 
            o_ABS_64H, 
            o_ABS_32H, 
            o_ABS_16H, 
            o_ABS_8H,  
            o_ABS_4H,  
            o_ABS_2H,
            o_ABS_1H
        } = horizontal_counter;
assign  {
            o_FLIP_128H, 
            o_FLIP_64H, 
            o_FLIP_32H, 
            o_FLIP_16H, 
            o_FLIP_8H,  
            o_FLIP_4H,  
            o_FLIP_2H,
            o_FLIP_1H
        } = horizontal_counter[7:0] ^ {8{i_HFLIP}};
assign  o_HBLANK_n = horizontal_counter[8];

reg     [8:0]   vertical_counter = 9'd248;
assign  __REF_VCOUNTER = vertical_counter;
assign  {
            o_ABS_128V, 
            o_ABS_64V, 
            o_ABS_32V, 
            o_ABS_16V, 
            o_ABS_8V,  
            o_ABS_4V,  
            o_ABS_2V,
            o_ABS_1V
        } = vertical_counter[7:0];

assign  {
            o_FLIP_128V, 
            o_FLIP_64V, 
            o_FLIP_32V, 
            o_FLIP_16V, 
            o_FLIP_8V,  
            o_FLIP_4V,  
            o_FLIP_2V,
            o_FLIP_1V
        } = vertical_counter[7:0] ^ {8{i_VFLIP}};


//
//  HCOUNTER
//

always @(posedge i_EMU_MCLK)
begin
    if(!i_MRST_n) //asynchronous reset
    begin
        horizontal_counter <= 9'd128;
    end
    else
    begin
        if(!i_EMU_CLK6MPCEN_n)
        begin
            if(horizontal_counter < 9'd511) //h count up
            begin
                horizontal_counter <= horizontal_counter + 9'd1;
            end
            else //h loop
            begin
                horizontal_counter <= 9'd128;
            end
        end
    end
end


//
//  SYNC TIP GENERATOR
//

reg             narrow_hsync_on_vsync = 1'b0; //appears on just before vsync period of even frame
reg             wide_hsync_on_vsync = 1'b0; //appears on vsync period
reg             hsync = 1'b0; //normal vclk

reg             narrow_hsync_on_vsync_clken_n = 1'b1;
reg             hsync_clken_n = 1'b1;

always @(posedge i_EMU_MCLK)
begin
    if(!i_MRST_n) //asynchronous reset
    begin
        narrow_hsync_on_vsync <= 1'b0;
        wide_hsync_on_vsync <= 1'b0;
        hsync <= 1'b0;
    end
    else
    begin
        if(!i_EMU_CLK6MPCEN_n)
        begin
            //narrow hsync on vsync
            if(horizontal_counter == 9'd175)
            begin
                narrow_hsync_on_vsync <= 1'b1;
            end
            else if(horizontal_counter == 9'd191)
            begin
                narrow_hsync_on_vsync <= 1'b0;
            end

            else if(horizontal_counter == 9'd367)
            begin
                narrow_hsync_on_vsync <= 1'b1;
            end
            else if(horizontal_counter == 9'd383)
            begin
                narrow_hsync_on_vsync <= 1'b0;
            end

            else
            begin
                narrow_hsync_on_vsync <= narrow_hsync_on_vsync;
            end


            //wide hysnc on vsync
            if(horizontal_counter == 9'd143)
            begin
                wide_hsync_on_vsync <= 1'b1;
            end
            else if(horizontal_counter == 9'd175)
            begin
                wide_hsync_on_vsync <= 1'b0;
            end

            else if(horizontal_counter == 9'd335)
            begin
                wide_hsync_on_vsync <= 1'b1;
            end
            else if(horizontal_counter == 9'd367)
            begin
                wide_hsync_on_vsync <= 1'b0;
            end

            else
            begin
                wide_hsync_on_vsync <= wide_hsync_on_vsync;
            end


            //hysnc
            if(horizontal_counter == 9'd175)
            begin
                hsync <= 1'b1;
            end
            else if(horizontal_counter == 9'd207)
            begin
                hsync <= 1'b0;
            end

            else
            begin
                hsync <= hsync;
            end



            //narrow hsync on vsync clken
            if(horizontal_counter == 9'd366)
            begin
                narrow_hsync_on_vsync_clken_n <= 1'b0;
            end
            else
            begin
                narrow_hsync_on_vsync_clken_n <= 1'b1;
            end

            //hsync clken
            if(horizontal_counter == 9'd174)
            begin
                hsync_clken_n <= 1'b0;
            end
            else
            begin
                hsync_clken_n <= 1'b1;
            end
        end
    end
end


//
//  VCLK GENERATOR
//

//VCLK output
always @(*)
begin
    if(o_FRAMEPARITY == 1'b0) //EVEN FRAME
    begin
        if(vertical_counter > 9'd503 || vertical_counter < 9'd266)
        begin
            o_VCLK <= narrow_hsync_on_vsync & o_HBLANK_n;
        end
        else
        begin
            o_VCLK <= hsync;
        end
    end
    else //ODD FRAME
    begin
        o_VCLK <= hsync;
    end
end


//VCLK clken
reg                 vclk_clken_n;

always @(*)
begin
    if(o_FRAMEPARITY == 1'b0) //EVEN FRAME
    begin
        if(vertical_counter > 9'd502 || vertical_counter < 9'd265) //not 503 and 266!! clken should be asserted before a posedge of VCLK, so it have to go 1V faster
        begin
            vclk_clken_n <= narrow_hsync_on_vsync_clken_n;
        end
        else
        begin
            vclk_clken_n <= hsync_clken_n;
        end
    end
    else //ODD FRAME
    begin
        vclk_clken_n <= hsync_clken_n;
    end
end


//
//  VCOUNTER
//

always @(posedge i_EMU_MCLK) //do not use asynchronous VCLK
begin
    if(!i_MRST_n) //asynchronous reset
    begin
        vertical_counter <= 9'd248;
    end
    else
    begin
        if(!i_EMU_CLK6MPCEN_n)
        begin
            if(!vclk_clken_n)
            begin
                if(vertical_counter < 9'd511)
                begin
                    //VBLANK
                    if(vertical_counter > 9'd494 || vertical_counter < 9'd271)
                    begin
                        o_VBLANK_n <= 1'b0;
                    end
                    else
                    begin
                        o_VBLANK_n <= 1'b1;
                    end
                    
                    //VBLANK**
                    if(vertical_counter > 9'd494 || vertical_counter < 9'd271)
                    begin
                        o_VBLANKH_n <= 1'b0;
                    end
                    else
                    begin
                        o_VBLANKH_n <= 1'b1; //VBLANK** goes high when vcounter = 248
                    end
                    
                    //256V
                    if(vertical_counter == 9'd495) //flip parity value
                    begin
                        o_FRAMEPARITY <= ~o_FRAMEPARITY;
                    end

                    //DMA
                    if(vertical_counter > 9'd478 && vertical_counter < 9'd495)
                    begin
                        __REF_DMA_n <= 1'b0;
                    end
                    else
                    begin
                        __REF_DMA_n <= 1'b1;
                    end

                    vertical_counter <= vertical_counter + 9'd1;
                end
                else
                begin
                    vertical_counter <= 9'd248;

                    o_VBLANKH_n <= 1'b1;
                end
            end
        end
    end
end




///////////////////////////////////////////////////////////
//////  SYNC GENERATOR
////

assign o_VSYNC_n = vertical_counter[8];

always @(*)
begin
    if(vertical_counter > 9'd503 || vertical_counter < 9'd266)
    begin
        if(vertical_counter > 9'd247 && vertical_counter < 9'd256)
        begin
            o_CSYNC <= o_VSYNC_n ^ wide_hsync_on_vsync;
        end
        else
        begin
            o_CSYNC <= o_VSYNC_n ^ narrow_hsync_on_vsync;
        end
    end
    else
    begin
        o_CSYNC <= o_VSYNC_n ^ hsync;
    end
end


endmodule