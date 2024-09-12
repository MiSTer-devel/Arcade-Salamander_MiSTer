module Salamander_SRAM #(parameter AW=10, parameter DW=8, parameter simhexfile="") (
    input   wire            i_MCLK,
    
    input   wire   [AW-1:0] i_ADDR,
    input   wire   [DW-1:0] i_DIN,
    output  reg    [DW-1:0] o_DOUT,
    input   wire            i_RD,
    input   wire            i_WR
);

reg     [DW-1:0]   RAM [0:(2**AW)-1];
always @(posedge i_MCLK) begin
    if(i_WR) RAM[i_ADDR] <= i_DIN;
    else begin
        if(i_RD) o_DOUT <= RAM[i_ADDR];
    end
end

integer i;
initial begin
    if( simhexfile != "" ) begin
        $readmemh(simhexfile, RAM);
    end
    else begin
        for(i=0; i<2**AW; i=i+1) RAM[i] = {DW{1'b0}};
    end
end

endmodule