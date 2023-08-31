/*
    74373 synchronous latch without tri-state
*/

module LOGIC373
(   
    input   wire            i_MCLK,
    input   wire    [7:0]   i_D,
    output  wire    [7:0]   o_Q,
    input   wire            i_LE
);

reg     [7:0]   REGISTER;
always @(posedge i_MCLK)
begin
    if(i_LE)
    begin
        REGISTER <= i_D;
    end
end

assign  o_Q =   (i_LE) ? i_D : REGISTER;

endmodule