// vending_defines.svh — shared macros for the vending-machine example.
// Faithful to Dally's chapter 16.3, including the use of `define for both
// widths and state encodings.

`ifndef VENDING_DEFINES_SVH
`define VENDING_DEFINES_SVH

// ── Data widths ──────────────────────────────────────────────────────
`define DWIDTH 6        // width of amount, price, value, sum
`define SWIDTH 3        // width of FSM state register

// ── Coin values (in nickels) ─────────────────────────────────────────
`define NICKEL  1
`define DIME    2
`define QUARTER 5

// ── Example price (for the testbench) ────────────────────────────────
`define PRICE   11

// ── State encodings ──────────────────────────────────────────────────
`define DEPOSIT 3'b000
`define SERVE1  3'b001
`define SERVE2  3'b010
`define CHANGE1 3'b011
`define CHANGE2 3'b100

`endif // VENDING_DEFINES_SVH
