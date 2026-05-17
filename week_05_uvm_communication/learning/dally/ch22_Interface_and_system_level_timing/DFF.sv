// DFF.sv — parametric N-bit positive-edge D flip-flop primitive.
// Standard library primitive (Dally & Harting). Copied into this
// folder so the ch.22 deserializer example compiles standalone.

module DFF #(
    parameter N = 1
) (
    input  logic         clk,
    input  logic [N-1:0] d,
    output logic [N-1:0] q
);
    always_ff @(posedge clk) q <= d;
endmodule : DFF
