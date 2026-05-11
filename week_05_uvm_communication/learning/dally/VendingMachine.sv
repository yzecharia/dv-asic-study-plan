// VendingMachine.sv — top level.
// SV translation of Dally Figure 16.22. Just hooks the control FSM and
// the datapath together — no logic of its own.

`include "vending_defines.svh"

module VendingMachine #(
    parameter N = `DWIDTH
) (
    input  logic         clk, rst,
    input  logic         nickel, dime, quarter, dispense, done,
    input  logic [N-1:0] price,
    output logic         serve, change
);

    // ── inter-module wires (between control and datapath) ───────────
    logic        enough, zero, sub;
    logic [3:0]  selval;
    logic [2:0]  selnext;

    // ── control FSM ─────────────────────────────────────────────────
    VendingMachineControl vmc (
        .clk      (clk),
        .rst      (rst),
        .nickel   (nickel),
        .dime     (dime),
        .quarter  (quarter),
        .dispense (dispense),
        .done     (done),
        .enough   (enough),
        .zero     (zero),
        .serve    (serve),
        .change   (change),
        .selval   (selval),
        .selnext  (selnext),
        .sub      (sub)
    );

    // ── datapath ────────────────────────────────────────────────────
    VendingMachineData #(N) vmd (
        .clk     (clk),
        .selval  (selval),
        .selnext (selnext),
        .sub     (sub),
        .price   (price),
        .enough  (enough),
        .zero    (zero)
    );

endmodule : VendingMachine
