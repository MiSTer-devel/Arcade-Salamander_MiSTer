module Salamander_PROM #(parameter AW=10, parameter DW=8, parameter simhexfile="") (
    input   wire            i_MCLK,

    input   wire   [AW-1:0] i_PROG_ADDR,
    input   wire   [DW-1:0] i_PROG_DIN,
    input   wire            i_PROG_CS,
    input   wire            i_PROG_WR,
    
    input   wire   [AW-1:0] i_ADDR,
    output  reg    [DW-1:0] o_DOUT,
    input   wire            i_RD
);

reg     [DW-1:0]   ROM [0:(2**AW)-1];
always @(posedge i_MCLK) begin
    if(i_PROG_CS & i_PROG_WR) ROM[i_PROG_ADDR] <= i_PROG_DIN;
    else begin
        if(i_RD) o_DOUT <= ROM[i_ADDR];
    end
end

initial
begin
    if( simhexfile != "" ) begin
        $readmemh(simhexfile, ROM);
    end
end

endmodule