module top; 
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import analysis_pkg::*;

    initial begin
        run_test("analysis_test");
    end

endmodule : top