module Mux6a #(
    parameter K=1
) (
    input logic [K-1:0] a0, a1, a2, a3, a4, a5,
    input logic [5:0] s,
    output logic [K-1:0] b
);

    logic [K-1:0] ba, bb;

    assign b = ba | bb;

    Mux3a #(K) ma (a2, a1, a0, s[2:0], ba);
    Mux3a #(K) mb (a3, a4, a5, s[5:3], bb);
    
endmodule