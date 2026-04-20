// Design HW3 — Fixed-priority arbiter TB
// Spec: docs/week_03.md, Design HW3
//   1. Assert all 4 requests → grant should be request 0
//   2. De-assert request 0 → grant moves to request 1
//   3. Test all priority orderings
//   4. SVA: grant is always one-hot or zero

`include "fixed_priority_arbiter.sv"

module fixed_priority_arbiter_tb;

    // TODO: implement
    localparam int N = 4;
    logic clk, rst_n;
    logic [N-1:0] request, grant;
    logic grant_valid;

    initial clk = 0;
    always #5 clk = ~clk; 

    fixed_priority_arbiter DUT(clk, rst_n, request, grant, grant_valid);

    property grant_one_hot_or_zero;
        @(posedge clk) disable iff (~rst_n) $onehot0(grant);
    endproperty

    assert property (grant_one_hot_or_zero)
        else $error("ERROR: grant violation one-hot-or-zero: %b", grant);

    initial begin
        rst_n = 0;
        request = '0;
        #20 @(negedge clk) rst_n = 1;
        for (int i = 0; i < 2**N; i++) begin
            request = i[N-1:0];
            @(posedge clk); #1;
            $display("[%0t] request = %b, grant = %b, grant_valid = %b", $time, request, grant, grant_valid);
        end

        #20 $finish;
    end

endmodule
