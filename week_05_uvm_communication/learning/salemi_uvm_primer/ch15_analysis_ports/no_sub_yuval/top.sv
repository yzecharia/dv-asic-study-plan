module top;

    import uvm_pkg::*;
    `include "ucm_macros.svh"

    import dice_pkg::*;

    initial begin
        run_test("dice_test");
    end

endmodule : top