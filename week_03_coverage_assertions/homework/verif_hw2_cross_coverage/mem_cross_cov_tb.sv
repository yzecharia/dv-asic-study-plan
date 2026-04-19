// Verif HW2 — Cross coverage deep dive
// Spec: docs/week_03.md, HW2
//   Memory controller signals:
//     operation      : READ / WRITE
//     address_region : LOW / MID / HIGH
//     burst_size     : 1 / 4 / 8 / 16
//   Covergroup mem_cg with a cross of all three (2 × 3 × 4 = 24 bins).
//   Use ignore_bins for illegal combos (e.g. burst_size 16 to LOW region).
//   Drive random transactions until 100% cross coverage; print tx count.
//
// No separate DUT — purely behavioral stimulus + sampling in the TB.

module mem_cross_cov_tb;

    // TODO: implement

    initial begin
        $display("TODO: mem_cross_cov_tb");
        $finish;
    end

endmodule
