// Design HW4 — Barrel shifter TB
// Spec: docs/week_04.md, Design HW4
//   Verify all three shift types with various shift amounts.

`include "barrel_shifter.sv"

module barrel_shifter_tb;

    localparam WIDTH = 32;

    logic [WIDTH-1:0]         data_in;
    logic [$clog2(WIDTH)-1:0] shift_amount;
    logic [1:0]               shift_type;
    logic [WIDTH-1:0]         data_out;

    barrel_shifter #(.WIDTH(WIDTH)) DUT (.*);

    initial begin
        // TODO: drive SLL/SRL/SRA with shift_amount = 0, 1, 5, WIDTH-1
        //       compare against SV operators <<, >>, >>>
        $display("TODO: barrel_shifter_tb");
        #100 $finish;
    end

endmodule
