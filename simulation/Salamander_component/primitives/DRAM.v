/*
    DRAM
*/

module DRAM #( parameter
	dw=8,          // data width
	aw=8,          // address bus width (number of pins)
	rw=aw,         // row width (usually address but width)
	cw=aw,         // column width (address but width or shorter)
	ctop=cw-1,     // index in address where MSB of col is
	cbot=0,        // index in address where LSB of col is
	simhexfile="",
	init=0
)
(
    input   wire            i_MCLK,
	input   wire  [aw-1:0]  i_ADDR,
	input   wire  [dw-1:0]  i_DIN,
	output  reg   [dw-1:0]  o_DOUT,
    input   wire            i_RAS_n,
    input   wire            i_CAS_n,
	input   wire            i_WR_n,
	input   wire            i_RD_n
);

reg   [dw-1:0]     RAM [0:(2**(rw+cw))-1];
reg                prev_ras;
reg                prev_cas;
reg   [rw-1:0]     ROW_ADDR;
reg   [cw-1:0]     COL_ADDR;
wire  [rw+cw-1:0]  ADDR = {COL_ADDR, ROW_ADDR};

/*
    MCLK                                    1 1
                        0 1 2 3 4 5 6 7 8 9 0 1 
    CLK18M  _|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|
    CLK9M   ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    CLK6M   ¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯|___|
    PIXEL   ----(3)----|----(4)----|----(5)----|----(6)----|----(7)----|----(0)----|----(1)----|----(2)----|----(3)----|
    /DTACK  ¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯S0¯¯S1¯¯S2¯¯S3¯¯S4¯|_w___w__S5__S6|¯S7¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
                               |-----------| = access time = 162.75ns
                                   >row
                                       >column
                                           >launch
                                               >CPU acquisition
    CHAMPX1 ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯¯¯¯¯¯
    /RAS    ___________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|________________ 
    /CAS    _______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|_______________|¯¯¯¯¯¯¯|____________
*/

always @(posedge i_MCLK)
begin
    prev_ras <= i_RAS_n;
    prev_cas <= i_CAS_n;

    if(i_RAS_n == 1'b0 && prev_ras == 1'b1)
    begin
        ROW_ADDR <= i_ADDR;
    end

    if(i_CAS_n == 1'b0 && prev_cas == 1'b1)
    begin
        COL_ADDR <= i_ADDR[ctop:cbot];
    end
end


always @(posedge i_MCLK)
begin
    if(i_WR_n == 1'b0)
    begin
        RAM[ADDR] <= i_DIN;
    end
end

always @(posedge i_MCLK) //read: latched output
begin
    if(i_RD_n == 1'b0 && i_WR_n == 1'b1)
    begin
        o_DOUT <= RAM[ADDR];
    end
end

integer i;

initial
begin
    if( simhexfile != "" )
	begin
        $readmemh(simhexfile, RAM);
    end
	else if( init != 0 )
	begin
		for(i = 0; i < 2**(rw+cw); i = i + 1)
		begin
			RAM[i] <= {dw{1'b0}};
		end
	end
end

endmodule
