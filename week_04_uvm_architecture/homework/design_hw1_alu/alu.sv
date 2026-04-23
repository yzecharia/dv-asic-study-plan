// Design HW1 — ALU DUT
// Spec: docs/week_04.md, Design HW1
//   - Registered outputs (1-cycle latency)
//   - Valid in/out handshake
//   - Parameterized width
//   - Operations: ADD, SUB, AND, OR, XOR (encoded via `operation`)

module alu #(
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] operand_a,
    input  logic [WIDTH-1:0] operand_b,
    input  logic [2:0]       operation,   // 0:ADD 1:SUB 2:AND 3:OR 4:XOR
    input  logic             valid_in,
    output logic [WIDTH:0]   result,      // extra bit for carry/overflow
    output logic             valid_out
);

    // TODO: implement
    // - operation encoding as typedef enum
    // - always_ff with registered result + valid_out
    // - handle ADD/SUB carry/borrow into bit [WIDTH]

endmodule
