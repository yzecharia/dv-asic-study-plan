// Design HW3 — Sequential Shift-Add Multiplier
// Spec: docs/week_04.md, Design HW3
//   Multi-cycle multiplier:
//   - Load multiplier into shift register
//   - For each bit of multiplier:
//       if bit is 1 → add shifted multiplicand to accumulator
//       shift multiplicand left by 1
//       shift multiplier right by 1
//   - After WIDTH cycles, product is ready
//
//   FSM: IDLE → COMPUTE → DONE
//   Bonus: support signed multiplication (Booth's algorithm)

module shift_add_multiplier #(
    parameter WIDTH = 8
)(
    input  logic                clk, rst_n,
    input  logic                start,
    input  logic [WIDTH-1:0]    multiplicand,
    input  logic [WIDTH-1:0]    multiplier,
    output logic [2*WIDTH-1:0]  product,
    output logic                done,
    output logic                busy
);

    // TODO: implement FSM + shift/add datapath

endmodule
