// Verif HW2 — UVM TB top module
// Instantiates DUT, interface, sets vif in config_db, calls run_test().

`include "uvm_macros.svh"

module alu_tb_top;
    import uvm_pkg::*;
    import alu_pkg::*;

    // TODO: logic clk, rst_n;
    // TODO: clock generator + reset sequence
    // TODO: alu_if vif(clk, rst_n);
    // TODO: alu DUT (...);
    // TODO: initial begin
    //           uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
    //           run_test("alu_base_test");
    //       end

endmodule
