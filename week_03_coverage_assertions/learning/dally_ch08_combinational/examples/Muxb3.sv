module Muxb3 #(
    parameter K = 1
) (
    input logic [K-1:0] a0, a1, a2,
    input logic [1:0] s,
    output logic [K-1:0] b
);
    logic [2:0] s_hot;
    decoder #(2,3) d (s, s_hot);
    Mux3a #(K) m (a0, a1, a2, s_hot[2:0], b);

endmodule
