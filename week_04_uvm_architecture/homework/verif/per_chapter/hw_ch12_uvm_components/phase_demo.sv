module phase_demo;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "my_component.svh"
    `include "my_test.svh"

    initial begin
        run_test();
    end
endmodule : phase_demo