// Design HW3 — Shift-Add Multiplier TB
// Spec: docs/week_04.md, Design HW3
//   - Corner cases: 0xN, 1xN, NxN, MAX×MAX
//   - 100 random inputs, compare product against `*` operator
//   - Verify timing: exactly WIDTH clock cycles to compute

`include "shift_add_multiplier.sv"

module shift_add_multiplier_tb;

    localparam WIDTH = 8;

    logic                clk, rst_n;
    logic                start;
    logic [WIDTH-1:0]    multiplicand, multiplier;
    logic [2*WIDTH-1:0]  product;
    logic                done, busy;

    shift_add_multiplier #(.WIDTH(WIDTH)) DUT (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // TODO: reset, corner cases, random compare, timing check
        $display("TODO: shift_add_multiplier_tb");
        #1000 $finish;
    end

endmodule
