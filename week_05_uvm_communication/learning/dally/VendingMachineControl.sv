// VendingMachineControl.sv — FSM half of the vending machine.
// SV translation of Dally Figures 16.23 + 16.24 (kept the same structure:
// output/command logic with `assign`, next-state logic with `casez`).

`include "vending_defines.svh"

module VendingMachineControl (
    input  logic        clk, rst,
    // command inputs
    input  logic        nickel, dime, quarter, dispense, done,
    // status from datapath
    input  logic        enough, zero,
    // outputs to outside world
    output logic        serve, change,
    // command outputs to datapath
    output logic [3:0]  selval,
    output logic [2:0]  selnext,
    output logic        sub
);

    logic [`SWIDTH-1:0] state, next;
    logic [`SWIDTH-1:0] next1;      // next state w/o reset
    logic               first;
    logic               nfirst;

    // ── outputs ──────────────────────────────────────────────────────
    logic serve1, change1;          // true during state SERVE1 / CHANGE1
    assign serve1  = (state == `SERVE1);
    assign change1 = (state == `CHANGE1);
    assign serve   = serve1  & first;
    assign change  = change1 & first;

    // ── datapath controls ────────────────────────────────────────────
    logic dep;                      // currently in DEPOSIT state
    assign dep = (state == `DEPOSIT);

    // selval — one-hot 4:1 select for value: { price, 1, 2, 5 }
    assign selval = {  (dep & dispense),
                       ((dep & nickel) | change),
                       (dep & dime),
                       (dep & quarter) };

    // selv — true when amount should be updated (sum drives next)
    logic selv;
    assign selv = (dep & (nickel | dime | quarter | (dispense & enough)))
                 | (change & first);

    // selnext — one-hot 3:1 select for amount next: { hold, sum, 0 }
    assign selnext = { ~(selv | rst), ~rst & selv, rst };

    // sub — subtract on dispense (deduct price) and change (deduct nickel)
    assign sub = (dep & dispense) | change;

    // ── first-cycle tracker for SERVE1 / CHANGE1 ─────────────────────
    // first is true UNLESS we were already in SERVE1 or CHANGE1 last cycle.
    assign nfirst = !(serve1 | change1);
    DFF #(1) first_reg (.clk(clk), .d(nfirst), .q(first));

    // ── state register (synchronous reset to DEPOSIT) ────────────────
    DFF #(`SWIDTH) state_reg (.clk(clk), .d(next), .q(state));
    assign next = rst ? `DEPOSIT : next1;

    // ── next-state logic (casez form, faithful to Dally Fig 16.24) ───
    always_comb begin
        casez ({dispense, enough, done, zero, state})
            // DEPOSIT — wait for coins + dispense+enough
            {4'b11??, `DEPOSIT}:  next1 = `SERVE1;
            {4'b0???, `DEPOSIT}:  next1 = `DEPOSIT;
            {4'b?0??, `DEPOSIT}:  next1 = `DEPOSIT;

            // SERVE1 — assert serve, wait for done to assert
            {4'b??1?, `SERVE1}:   next1 = `SERVE2;
            {4'b??0?, `SERVE1}:   next1 = `SERVE1;

            // SERVE2 — wait for done to deassert; branch to CHANGE or DEPOSIT
            {4'b??01, `SERVE2}:   next1 = `DEPOSIT;   // ~done & zero → done, no change
            {4'b??00, `SERVE2}:   next1 = `CHANGE1;   // ~done & ~zero → return change
            {4'b??1?, `SERVE2}:   next1 = `SERVE2;    // done still asserted → stay

            // CHANGE1 — assert change, wait for done
            {4'b??1?, `CHANGE1}:  next1 = `CHANGE2;   // done → advance
            {4'b??0?, `CHANGE1}:  next1 = `CHANGE1;   // ~done → stay

            // CHANGE2 — wait for done to deassert; loop or finish
            {4'b??00, `CHANGE2}:  next1 = `CHANGE1;   // ~done & ~zero → more change
            {4'b??01, `CHANGE2}:  next1 = `DEPOSIT;   // ~done & zero  → done
            {4'b??1?, `CHANGE2}:  next1 = `CHANGE2;   // done still asserted → stay

            default:              next1 = `DEPOSIT;
        endcase
    end

endmodule : VendingMachineControl
