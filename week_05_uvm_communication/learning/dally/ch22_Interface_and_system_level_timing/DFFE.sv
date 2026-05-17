// DFFE.sv — parametric N-bit positive-edge D flip-flop with clock enable.
// Companion to DFF.sv. When `en` is high the flop captures `d`; when
// `en` is low it holds its value. Used by the ch.22 deserializer
// (Dally & Harting, Example 22.2) as the per-slot data store.

module DFFE #(
    parameter N = 1
) (
    input  logic         clk,
    input  logic         en,
    input  logic [N-1:0] d,
    output logic [N-1:0] q
);
    always_ff @(posedge clk)
        if (en) q <= d;
endmodule : DFFE
