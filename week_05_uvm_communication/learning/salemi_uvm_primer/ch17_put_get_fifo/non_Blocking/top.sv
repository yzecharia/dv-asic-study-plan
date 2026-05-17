interface clk_bfm;
    bit clk;
    initial clk = 0;
    always #7 clk = ~clk;
endinterface : clk_bfm

module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import nonblocking_pkg::*;

    clk_bfm clk_bfm_i();
    initial begin
        nonblocking_pkg::clk_bfm_i = clk_bfm_i;
        run_test();
    end
endmodule : top
