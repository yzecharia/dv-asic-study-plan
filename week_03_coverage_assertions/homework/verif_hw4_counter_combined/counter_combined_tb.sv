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

    initial begin
        $display("TODO: counter_combined_tb");
        $finish;
    end

endmodule
