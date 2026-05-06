module oo_tb_demo;
    import tinyalu_pkg::*;

    tinyalu_bfm bfm();

    tinyalu DUT (
        .clk     (bfm.clk),
        .reset_n (bfm.reset_n),
        .start   (bfm.start),
        .A       (bfm.A),
        .B       (bfm.B),
        .op      (bfm.op),
        .done    (bfm.done),
        .result  (bfm.result)
    );

    testbench testbench_h;

    initial begin
        testbench_h = new(bfm);
        testbench_h.execute();
    end

endmodule : oo_tb_demo
