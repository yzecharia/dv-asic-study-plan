// ripple carry adder
module adder2 #(
    parameter N=8
) (
    input logic [N-1:0] a, b,
    input logic cin,
    output logic [N-1:0] s,
    output logic cout
);

    logic [N-1: 0] p, g; 
    logic [N:0] c;
    assign p = a ^ b;                       // Get the propogate value for each weight 
    assign g = a & b;                       // get the generate of g[i]
    //assign c = {g | (p & c[N-1:0]), cin};         // carry[i+1] = g[i] | c[i] & p[i]
    genvar i;
    assign c[0] = cin;
    generate
        for (i = 0; i < N; i++) begin
            assign c[i+1] = g[i] | (p & c[i]);
        end
    endgenerate

    assign s = c ^ p;
    assign cout = c[N];
endmodule : adder2