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

    typedef enum logic [1:0] {
        LOW,
        MID,
        HIGH
    } region_t;
    typedef enum {READ, WRITE} op_t;

    op_t op;
    region_t address_region;
    logic clk;
    int burst;

    covergroup cg_mem @(posedge clk);
        cp_op: coverpoint op {
            bins read = {READ};
            bins write = {WRITE};
        }
        cp_addr_region: coverpoint address_region {
            bins low = {LOW};
            bins mid = {MID};
            bins high = {HIGH};
        }
        cp_burst_size: coverpoint burst {
            bins b1 = {1};
            bins b4 = {4};
            bins b8 = {8};
            bins b16 = {16};
        }
        cp_cross: cross cp_op, cp_addr_region, cp_burst_size {
            ignore_bins big_burst_to_low = binsof(cp_addr_region.low) && binsof(cp_burst_size.b16);
        }
    endgroup : cg_mem
    

    cg_mem cg = new();

    always #5 clk = ~clk;

    initial begin
        int count = 0;
        clk = 0;

        while (cg.cp_cross.get_coverage() < 100.0) begin
            @(posedge clk);
            op = op_t'($urandom_range(0, 1));
            address_region = region_t'($urandom_range(0, 2));
            case ($urandom_range(0, 3))
                0: burst = 1;
                1: burst = 4;
                2: burst = 8;
                3: burst = 16;
            endcase
            count++;
        end

        $display("Reached 100%% cross coverage in %0d transactions", count);
        $display("Overall: %0.2f%%", cg.get_coverage());
        $display("operation: %0.2f%%", cg.cp_op.get_coverage());
        $display("address: %0.2f%%", cg.cp_addr_region.get_coverage());
        $display("burst: %0.2f%%", cg.cp_burst_size.get_coverage());
        $display("cross: %0.2f%%", cg.cp_cross.get_coverage());
        $finish;
    end

endmodule
