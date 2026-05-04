// Design HW2 — SV Interface for the ALU. Spec: docs/week_04.md (Design HW2).
// Reference: cheatsheets/spear_ch4_interfaces.sv
interface alu_if #(parameter WIDTH = 8)(
    input logic clk, rst_n
);

    logic [WIDTH-1:0] operand_a, operand_b;
    logic [2:0] operation;
    logic valid_in;
    logic [WIDTH:0] result;
    logic valid_out;

    clocking cb @(posedge clk);
        default input #1step output #1;
        input valid_out, result;
        output operand_a, operand_b, operation, valid_in;
    endclocking

    modport dut (
        input clk, rst_n, operand_a, operand_b, operation, valid_in,
        output result, valid_out
    );

    modport tb (
        clocking cb
    );

    modport monitor (
        input clk, rst_n, operand_a, operand_b, operation,
                valid_in, result, valid_out
    );


endinterface

