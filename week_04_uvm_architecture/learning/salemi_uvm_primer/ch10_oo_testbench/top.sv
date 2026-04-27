/*
    The top level does 3 things:
    1. Imports the class definitions.
    2. Instantiates the DUT and BFM and declares the testbench class variable.
    3. Instantiates and launches the testbench class.
*/

module top;
    import tinyalu_pkg::*;
    `include "tinyalu_macros.svh"

    tinyalu DUT (.A(bfm.A), .B(bfm.B), .op(bfm.op),
                .clk(bfm.clk), .reset_n(bfm.reset_n), 
                .start(bfm.start), .done(bfm.done), .result(bfm.result));
    
    tinyalu_bfm bfm();
    testbench testbench_h;

    initial begin
        testbench_h = new(bfm);
        testbench_h.execute();
    end
endmodule : top