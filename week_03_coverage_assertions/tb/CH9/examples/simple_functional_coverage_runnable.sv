// Runnable version of Spear Ch.9 example 9-2 (simple functional coverage).
// Replaces program/interface/clocking block with a plain module + clock,
// so it compiles under both iverilog and xsim.

module tb_cov;

    // --- Clock ---
    logic clk = 0;
    always #5 clk = ~clk;   // 10 time-unit period

    // --- Transaction class ---
    class Transaction;
        rand bit [31:0] data;
        rand bit [2:0]  dst;     // 3 bits -> 8 possible dst values
    endclass : Transaction

    Transaction tr;

    // --- Covergroup ---
    covergroup CovDst2;
        coverpoint tr.dst;       // auto-bins: one bin per value (0..7)
    endgroup : CovDst2

    CovDst2 ck;

    // --- Test ---
    initial begin
        ck = new();              // instantiate covergroup

        repeat (32) begin
            @(posedge clk);      // wait a cycle
            tr = new();
            assert(tr.randomize())
                else $fatal("randomize failed");
            ck.sample();         // record current value of tr.dst
            $display("[%0t] dst=%0d data=%h", $time, tr.dst, tr.data);
        end

        // Coverage report
        $display("\n=== Coverage Report ===");
        $display("CovDst2 coverage = %0.2f%%", ck.get_coverage());
        $finish;
    end

endmodule : tb_cov
