// Verif HW4 — Combined coverage + assertions TB for up/down counter
// Spec: docs/week_03.md, HW4
//   Assertions:
//     - counter never > 15 or < 0
//     - load → count_out == data_in next cycle
//     - up and down never both high
//     - up  → count increments by 1
//     - down → count decrements by 1
//   Coverage:
//     - all count_out values 0..15
//     - all transitions 0→1..14→15 and 15→14..1→0
//     - load from every data_in value
//     - cross: direction (up/down/load/idle) × count_out region (low/mid/high)
//   Run until 100% coverage.

`include "up_down_counter.sv"

module counter_combined_tb;

    // TODO: implement

    logic clk, rst_n, up, down, load;
    logic [3:0] data_in, count_out;

    typedef enum logic [1:0] {IDLE, LOAD, UP, DOWN} dir_t;
    dir_t dir;

    up_down_counter DUT (clk, rst_n, up, down, load, data_in, count_out);

    always_comb begin
        if(load) dir = LOAD;
        else if (up) dir = UP;
        else if (down) dir = DOWN;
        else dir = IDLE;
    end

    // Always true from design spec
    property count_max_limit;
        @(posedge clk) disable iff (~rst_n) (count_out <= 15);
    endproperty

    // Always true from design spec
    property count_min_limit;
        @(posedge clk) disable iff (~rst_n) (count_out >= 0);
    endproperty

    property load_check;
        @(posedge clk) disable iff (~rst_n) load |=> (count_out == $past(data_in));
    endproperty

    property up_down;
        @(posedge clk) disable iff (~rst_n) !(up && down);
    endproperty

    property increment;
        @(posedge clk) disable iff (~rst_n)
            (up && !load && !down) |=> (count_out == ($past(count_out) + 1) % 16);
    endproperty

    property decrement;
        @(posedge clk) disable iff (~rst_n)
            (down && !load && !up) |=> (count_out == ($past(count_out) + 15) % 16);
    endproperty

    assert property (count_max_limit) else $error("Counting outside spec range, count > 15");
    assert property (count_min_limit) else $error("Counting outside spec range, count < 0");
    assert property (load_check) else $error("data_in not loading correctly");
    assert property (up_down) else $error("Invalid state, up and down both asserted");
    assert property (increment) else $error("Wrong value after Increment");
    assert property (decrement) else $error("Wrong value after Decrement");

    covergroup cg_counter @(posedge clk);
        cp_counter_range: coverpoint count_out{
            bins all[] = {[0:15]}; 
        }
        cp_transitions: coverpoint count_out {
            bins inc[] = (0=>1, 1=>2, 2=>3, 3=>4, 4=>5, 5=>6, 6=>7, 7=>8, 8=>9, 9=>10, 10=>11, 11=>12, 12=>13, 13=>14, 14=>15, 15=>0);
            bins dec[] = (0=>15, 15=>14, 14=>13, 13=>12, 12=>11, 11=>10, 10=>9, 9=>8, 8=>7, 7=>6, 6=>5, 5=>4, 4=>3, 3=>2, 2=>1, 1=>0);
        }
        cp_load_values: coverpoint data_in iff (load) {
            bins values[] = {[0:15]};
        }
        cp_dir: coverpoint dir {
            bins idle = {IDLE};
            bins load = {LOAD};
            bins up = {UP};
            bins down = {DOWN};
        }
        cp_count_region: coverpoint count_out{
            bins low = {[0:5]};
            bins mid = {[6:10]};
            bins high = {[11:15]};
        }
        cp_cross_dir_region: cross cp_dir, cp_count_region;
    endgroup : cg_counter

    cg_counter cg = new();
    initial clk=0;
    always #5 clk = ~clk;

initial begin
    rst_n = 0; up = 0; down = 0; load = 0; data_in = '0;
    #20 @(negedge clk) rst_n = 1;

    $display("========== TEST 1: UP sweep ==========");
    up = 1;
    repeat (17) @(posedge clk);
    up = 0;

    $display("========== TEST 2: DOWN sweep ==========");
    data_in = 4'd15; load = 1;
    @(posedge clk);
    load = 0; down = 1;
    repeat (17) @(posedge clk);
    down = 0;

    $display("========== TEST 3: Load every value ==========");
    load = 1;
    for (int i = 0; i < 16; i++) begin
        data_in = i[3:0];
        @(posedge clk);
    end
    load = 0;

    $display("========== TEST 4: IDLE at each region ==========");
    repeat (3) @(posedge clk);

    data_in = 4'd8; load = 1; @(posedge clk); load = 0;
    repeat (3) @(posedge clk);

    data_in = 4'd2; load = 1; @(posedge clk); load = 0;
    repeat (3) @(posedge clk);

    // ==================== Coverage report ====================
    $display("========== Coverage ==========");
    $display("Overall: %0.2f%%", cg.get_coverage());
    $display("counter_range: %0.2f%%", cg.cp_counter_range.get_coverage());
    $display("transitions: %0.2f%%", cg.cp_transitions.get_coverage());
    $display("load_values: %0.2f%%", cg.cp_load_values.get_coverage());
    $display("direction: %0.2f%%", cg.cp_dir.get_coverage());
    $display("count_region: %0.2f%%", cg.cp_count_region.get_coverage());
    $display("cross: %0.2f%%", cg.cp_cross_dir_region.get_coverage());

    $finish;
end

endmodule
