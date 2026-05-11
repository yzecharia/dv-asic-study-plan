// DFF.sv — parametric n-bit positive-edge flip-flop primitive.
// Used by all the structural-style examples in this folder.

module DFF #(
    parameter N = 1
) (
    input  logic         clk,
    input  logic [N-1:0] d,
    output logic [N-1:0] q
);
    always_ff @(posedge clk) q <= d;
endmodule : DFF
