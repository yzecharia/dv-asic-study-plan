// VendingMachineTb.sv — SV translation of Dally Figure 16.26.
// Drives the DUT through the test sequence shown in the book:
// reset → nickel → dime → idle → premature dispense → quarter × 2
// → idle → dispense (which now succeeds at amount=13, price=11)
// → release dispense → stop.

`include "vending_defines.svh"

module VendingMachineTb;

    logic       clk, rst;
    logic       nickel, dime, quarter, dispense, done;
    logic [3:0] price;
    logic       serve, change;

    // DUT — override N to 4 (4-bit amount/price for this test)
    VendingMachine #(4) vm (
        .clk      (clk),
        .rst      (rst),
        .nickel   (nickel),
        .dime     (dime),
        .quarter  (quarter),
        .dispense (dispense),
        .done     (done),
        .price    (price),
        .serve    (serve),
        .change   (change)
    );

    // ── clock generator: period = 10 units ──────────────────────────
    initial begin
        clk = 1;
        #5 clk = 0;
        forever begin
            $display("%b %h %h %b %b",
                     {nickel, dime, quarter, dispense},
                     vm.vmc.state, vm.vmd.amount,
                     serve, change);
            #5 clk = 1;
            #5 clk = 0;
        end
    end

    // ── done = prompt feedback (mimics a dispenser/coin mech) ───────
    always_ff @(posedge clk) begin
        done <= (serve | change);
    end

    // ── stimulus ────────────────────────────────────────────────────
    initial begin
        rst   = 1;
        {nickel, dime, quarter, dispense} = 4'b0000;
        price = `PRICE;                              // 11

        #25 rst = 0;
        #10 {nickel, dime, quarter, dispense} = 4'b1000;  // nickel  → amount=1
        #10 {nickel, dime, quarter, dispense} = 4'b0100;  // dime    → amount=3
        #10 {nickel, dime, quarter, dispense} = 4'b0000;  // nothing
        #10 {nickel, dime, quarter, dispense} = 4'b0001;  // try to dispense early
        #10 {nickel, dime, quarter, dispense} = 4'b0010;  // quarter → amount=8
        #10 {nickel, dime, quarter, dispense} = 4'b0010;  // quarter → amount=13
        #10 {nickel, dime, quarter, dispense} = 4'b0000;  // nothing
        #10 {nickel, dime, quarter, dispense} = 4'b0001;  // dispense → amount goes 13→2
        #10 dispense = 0;
        #100 $stop;
    end

endmodule : VendingMachineTb
