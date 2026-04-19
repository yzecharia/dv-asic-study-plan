// Dally Example 8.3 — programmable-priority arbiter (CYCLIC form)
// Educational only: this has a combinational loop (c[0] ← c[N-1]).
// STA and some synthesis tools will reject this — that's the lesson.

module prog_priority_arbiter_cyclic #(
    parameter int N = 4
)(
    input  logic [N-1:0] r,
    input  logic [N-1:0] p,   // one-hot priority pointer
    output logic [N-1:0] g
);

    logic [N-1:0] c;

    // c[0] wraps from c[N-1] — this is the edge that creates the cycle
    assign c[0] = p[0] | (c[N-1] & ~r[N-1]);

    genvar i;
    generate
        for (i = 1; i < N; i++) begin : chain
            assign c[i] = p[i] | (c[i-1] & ~r[i-1]);
        end
    endgenerate

    assign g = r & c;

endmodule
