// Verif HW1 — FIFO covergroup TB
// Spec: docs/week_03.md, HW1
//   - coverpoint data_count (empty/low/mid/high/full bins)
//   - coverpoint operation (write/read/both/idle from wr_en & rd_en)
//   - cross coverage: data_count_level × operation
//   - transition coverage on data_count (fill-up / drain)
//   - coverpoint error flags (overflow / underflow)
//   Drive random reads/writes for 10k cycles. Target: 100% coverage.

`include "fifo_model.sv"

module fifo_coverage_tb;
    // TODO: implement

    logic clk, rst_n;
    logic wr_en, rd_en;
    logic [7:0] wr_data;
    logic [7:0] rd_data;
    logic full, empty;
    logic [4:0] data_count;
    logic overflow, underflow;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    fifo_model #(.DEPTH(16), .WIDTH(8)) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty),
        .overflow(overflow),
        .underflow(underflow),
        .data_count(data_count)
    );

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ_ONLY = 2'b01,
        WRITE_ONLY = 2'b10,
        BOTH = 2'b11
    } fifo_op_t;

    fifo_op_t op;
    assign op = fifo_op_t'({wr_en, rd_en});

    covergroup fifo_cg @(posedge clk);
        cp_data_count: coverpoint data_count {
            bins empty = {0};
            bins low = {[1:5]};
            bins mid = {[6:10]};
            bins high = {[11:15]};
            bins full = {16};
            illegal_bins impossible = {[17:$]};
        }
        cp_operation: coverpoint op {
            bins idle = {IDLE};
            bins read_only = {READ_ONLY};
            bins write_only = {WRITE_ONLY};
            bins both = {BOTH};
        }
        cp_cross: cross cp_operation, cp_data_count;
        cp_transition: coverpoint data_count {
            bins fill_up = (0=>1=>2=>3=>4=>5=>6=>7=>8=>9=>10=>11=>12=>13=>14=>15=>16);
            bins drain = (16=>15=>14=>13=>12=>11=>10=>9=>8=>7=>6=>5=>4=>3=>2=>1=>0);
            bins inc_any = ([0:15] => [1:16]);
            bins dec_any = ([1:16] => [0:15]);
            bins hold = (0[*4]);
        }
        cp_errors: coverpoint {overflow, underflow}{
            bins overflow = {2'b10};
            bins underflow = {2'b01};
        }
    endgroup : fifo_cg
    fifo_cg cg = new();

    initial begin
        rst_n = 0; wr_en = 0; rd_en = 0; wr_data = '0;
        #20 @(negedge clk) rst_n = 1;
        repeat (10000) @(posedge clk) begin
            wr_en <= $urandom_range(0,1);
            rd_en <= $urandom_range(0,1);
            wr_data <= $urandom;
        end

        // transitions at 60%
        /*
        cp_transition: coverpoint data_count {
            bins fill_up = (0=>1=>2=>3=>4=>5=>6=>7=>8=>9=>10=>11=>12=>13=>14=>15=>16);
            bins drain = (16=>15=>14=>13=>12=>11=>10=>9=>8=>7=>6=>5=>4=>3=>2=>1=>0);
            bins inc_any = ([0:15] => [1:16]);
            bins dec_any = ([1:16] => [0:15]);
            bins hold = (0[*4]);
        */

        #20 @(negedge clk) rst_n = 0;
        #20 @(negedge clk) rst_n = 1;
        repeat (17) @(posedge clk) begin // fill_up
            wr_en <= 1;
            rd_en <= 0;
            wr_data <= $urandom;
        end
        repeat (17) @(posedge clk) begin //drain
            wr_en <= 0;
            rd_en <= 1;
        end
        repeat (5) @(posedge clk) begin // hold;
            wr_en <= 0;
            rd_en <= 0;
        end


        $display("Overall:     %0.2f%%", cg.get_coverage());
        $display("data_count:  %0.2f%%", cg.cp_data_count.get_coverage());
        $display("operation:   %0.2f%%", cg.cp_operation.get_coverage());
        $display("cross:       %0.2f%%", cg.cp_cross.get_coverage());
        $display("transitions: %0.2f%%", cg.cp_transition.get_coverage());
        $display("errors:      %0.2f%%", cg.cp_errors.get_coverage());
        $finish;
    end

endmodule
