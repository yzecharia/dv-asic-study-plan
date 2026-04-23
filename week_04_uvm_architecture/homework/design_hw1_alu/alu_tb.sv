// Design HW1 — ALU TB (non-UVM sanity TB, before you build the UVM env in HW2+)
// Spec: docs/week_04.md, Design HW1

`include "alu.sv"

module alu_tb;

    localparam WIDTH = 8;

    logic             clk, rst_n;
    logic [WIDTH-1:0] operand_a, operand_b;
    logic [2:0]       operation;
    logic             valid_in;
    logic [WIDTH:0]   result;
    logic             valid_out;

    alu #(.WIDTH(WIDTH)) DUT (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // TODO: reset, drive all 5 operations with known operands,
        //       verify result matches the gold model.
        $display("TODO: alu_tb");
        #100 $finish;
    end

endmodule
