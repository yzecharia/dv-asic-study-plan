// VendingMachineData.sv — datapath half of the vending machine.
// SV translation of Dally Figure 16.25.
//
// Holds the `amount` register and contains:
//   - 4:1 value mux (price, NICKEL, DIME, QUARTER)
//   - add/sub unit that computes sum = amount ± value
//   - 3:1 next-amount mux (amount, sum, 0)
//   - comparators producing the status signals enough / zero
//
// All sub-blocks are instantiated as primitives (DFF, Mux3, Mux4,
// AddSub) — faithful to Dally's structural style.

`include "vending_defines.svh"

module VendingMachineData #(
    parameter N = `DWIDTH
) (
    input  logic         clk,
    input  logic [3:0]   selval,    // 4:1 one-hot select for value
    input  logic [2:0]   selnext,   // 3:1 one-hot select for next amount
    input  logic         sub,       // 0=add, 1=subtract
    input  logic [N-1:0] price,     // soft-drink price in nickels
    output logic         enough,    // amount >= price
    output logic         zero       // amount == 0
);
    logic [N-1:0] sum;              // output of add/subtract unit
    logic [N-1:0] amount;           // current amount (registered)
    logic [N-1:0] next;             // next amount
    logic [N-1:0] value;            // value to add or subtract
    logic         ovf;              // overflow (unused)

    // state register holds the current amount
    DFF #(N) amt (.clk(clk), .d(next), .q(amount));

    // select next amount from { amount, sum, 0 }
    Mux3 #(N) nsmux (
        .i2  (amount),
        .i1  (sum),
        .i0  ({N{1'b0}}),
        .sel (selnext),
        .y   (next)
    );

    // add or subtract value from amount
    AddSub #(N) addsub (
        .a   (amount),
        .b   (value),
        .sub (sub),
        .sum (sum),
        .ovf (ovf)
    );

    // select the value to add or subtract — { price, 1, 2, 5 }
    // The constant 1/2/5 literals widen to N bits via the cast.
    Mux4 #(N) vmux (
        .i3  (price),
        .i2  (N'(`NICKEL)),
        .i1  (N'(`DIME)),
        .i0  (N'(`QUARTER)),
        .sel (selval),
        .y   (value)
    );

    // comparators producing the status signals
    assign enough = (amount >= price);
    assign zero   = (amount == '0);

endmodule : VendingMachineData
