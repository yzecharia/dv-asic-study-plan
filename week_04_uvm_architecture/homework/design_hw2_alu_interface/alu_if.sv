// Design HW2 — SystemVerilog Interface for the ALU
// Spec: docs/week_04.md, Design HW2
//   - DUT-side and TB-side modports
//   - clocking block for synchronous TB driving (UVM driver will use this)

interface alu_if (input logic clk, rst_n);

    logic [7:0] operand_a, operand_b;
    logic [2:0] operation;
    logic       valid_in;
    logic [8:0] result;
    logic       valid_out;

    // TODO: modport dut  (input  operand_a, operand_b, operation, valid_in,
    //                     output result, valid_out);
    // TODO: modport tb   (output operand_a, operand_b, operation, valid_in,
    //                     input  result, valid_out);
    // TODO: clocking cb @(posedge clk);
    //           output operand_a, operand_b, operation, valid_in;
    //           input  result, valid_out;
    //       endclocking

endinterface
