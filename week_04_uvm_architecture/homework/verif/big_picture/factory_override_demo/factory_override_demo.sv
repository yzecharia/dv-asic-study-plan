// Verif HW4 — Factory Override Exercise. Spec: docs/week_04.md (HW4).
// Reference: cheatsheets/salemi_uvm_ch9-13.sv
module factory_override_demo;
    import uvm_pkg::*;
    import demo_pkg::*;
    `include "uvm_macros.svh"

    
    initial begin
        run_test();
    end


endmodule : factory_override_demo