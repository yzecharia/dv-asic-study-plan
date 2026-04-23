module top;

    tinyalu_bfm bfm();
    tester tester_i(bfm);
    coverage coverage_i(bfm);
    scoreboard scoreboard_i(bfm);

    tinyalu DUT (.A(bmf.A), .B(bfm.b), .op(bfm.op),
                .clk(bfm.clk), .reset_n(bfm.reset_n),
                .start(bfm.start), .done(bfm.done), result(bfm.result));

endmodule : top