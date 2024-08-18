module GX400_video_sim
(
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_CLK6MPCEN_n,
    input   wire    [8:0]   i_HCOUNTER,
    input   wire    [8:0]   i_VCOUNTER,
    input   wire    [15:0]  i_VIDEODATA
);


/*
    VCNTR
    272 - HCNTR 278~511 + 128~149; 150 end of line
    ~
    495 - HCNTR 278~511 + 128~149; 150 end of frame
*/

reg     [7:0]       RESNET_CONSTANT[31:0];
reg     [7:0]       BITMAP_HEADER[63:0];
integer             BITMAP_LINE_ADDRESS = 32'h29D36;
wire    [4:0]       B = i_VIDEODATA[14:10];
wire    [4:0]       G = i_VIDEODATA[9:5];
wire    [4:0]       R = i_VIDEODATA[4:0];

integer             fd;
integer             i;
reg     [15:0]      frame = 16'd0;

initial begin
    $readmemh("./GX400_video/debug_resnet_level.txt", RESNET_CONSTANT);
    $readmemh("./GX400_video/debug_bitmap_header.txt", BITMAP_HEADER);
end

always @(posedge i_EMU_MCLK) begin
    if(!i_EMU_CLK6MPCEN_n) begin
        if(i_VCOUNTER > 9'd271 && i_VCOUNTER < 9'd496) begin
            if (i_VCOUNTER == 9'd272 && i_HCOUNTER == 9'd276) begin
                BITMAP_LINE_ADDRESS = 20'h29D36; //reset line

                fd = $fopen($sformatf("./vsim/gx400_frame%0d.bmp", frame), "wb"); //generate new file

                for(i = 0; i < 54; i = i + 1) begin //write bitmap header
                    $fwrite(fd, "%c", BITMAP_HEADER[i]);
                end      

                $display("Start of frame %d", frame); //debug message
                
            end
            else if(i_HCOUNTER == 9'd277) begin
                $fseek(fd, BITMAP_LINE_ADDRESS, 0); //set current line address
            end
            else if(i_HCOUNTER > 9'd277 || i_HCOUNTER < 9'd150) begin
                $fwrite(fd, "%c%c%c", RESNET_CONSTANT[B], RESNET_CONSTANT[G], RESNET_CONSTANT[R]); //B G R
            end
            else if(i_HCOUNTER == 9'd150) begin
                BITMAP_LINE_ADDRESS = BITMAP_LINE_ADDRESS - 32'h300; //decrease line
            end
            else if(i_VCOUNTER == 9'd495 && i_HCOUNTER == 9'd151) begin
                $fclose(fd); //close this frame
                $display("Frame %d saved", frame); //debug message
                
                frame = frame + 16'd1;
            end
            else begin
                
            end
        end
    end
end


endmodule