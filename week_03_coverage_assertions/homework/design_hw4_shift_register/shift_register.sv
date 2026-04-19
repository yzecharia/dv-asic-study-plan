// Design HW4 — Parameterized shift register
// Spec: docs/week_03.md, Design HW4
//   - parallel load overrides shift
//   - serial_out is MSB for LEFT, LSB for RIGHT
//   - serial_in feeds the vacated bit

module shift_register #(
    parameter WIDTH     = 8,
    parameter DIRECTION = "LEFT"   // "LEFT" or "RIGHT"
)(
    input  logic             clk, rst_n,
    input  logic             shift_en,
    input  logic             load,
    input  logic [WIDTH-1:0] data_in,
    input  logic             serial_in,
    output logic [WIDTH-1:0] data_out,
    output logic             serial_out
);

    // TODO: implement

endmodule
