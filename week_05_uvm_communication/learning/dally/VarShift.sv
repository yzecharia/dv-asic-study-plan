module VarShift #(
    parameter N=8
) (
    input logic clk, rst, 
    input logic [1:0] sh_amount,
    input logic [2:0] sin,
    output logic [N-1:0] out
);

    logic [N-1:0] next_out;

    always_ff @(posedge clk) out <= next_out;

    assign next_out = rst ? '0 : {out, sin} >> (3 - sh_amount); 
    /*
        out = 1001
        sin = 110
        {out, sin} = 1001_110

        if we dont want a shift we need to shift the cat by 3 to get the original value,
        if sh_amount = 1; then we always want the msb of sin to enter the opened slot first so we need to shift rigt by 2:
        0010_011.
        Now since compiler takes the lower N bits of the cat (because next_out only N bits) we get:
        0011 with is the shift we wanted
    */

endmodule : VarShift