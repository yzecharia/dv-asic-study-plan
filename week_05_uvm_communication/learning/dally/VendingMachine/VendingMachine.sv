`include "vending_defines.svh"
module VendingMachine # (
    parameter N = `DWIDTH
) (
    input logic clk, rst, nickel, dime, quarter, dispense, done,
    input logic [N-1:0] price,
    output logic serve, change
);


    logic enough, zero, sub;
    logic [3:0] selval;
    logic [2:0] selnext;

    VendingMachineControl vmc (clk, rst, nickel, dime, quarter, dispense, done,
                                enough, zero, serve, change, sub, selval, selnext);

    VendingMachineData #(N) vmd (clk, selval, selnext, sub, price, enough, zero);

endmodule : VendingMachine
