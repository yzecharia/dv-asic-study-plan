module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "hello_uvm_test.svh"
    initial begin
        run_test();
    end


endmodule : top
