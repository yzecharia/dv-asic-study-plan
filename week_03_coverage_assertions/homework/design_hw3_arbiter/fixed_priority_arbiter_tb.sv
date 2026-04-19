// Design HW3 — Fixed-priority arbiter TB
// Spec: docs/week_03.md, Design HW3
//   1. Assert all 4 requests → grant should be request 0
//   2. De-assert request 0 → grant moves to request 1
//   3. Test all priority orderings
//   4. SVA: grant is always one-hot or zero

`include "fixed_priority_arbiter.sv"

module fixed_priority_arbiter_tb;

    // TODO: implement

    initial begin
        $display("TODO: fixed_priority_arbiter_tb");
        $finish;
    end

endmodule
