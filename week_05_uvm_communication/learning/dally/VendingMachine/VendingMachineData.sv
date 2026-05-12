`include "vending_defines.svh"
module VendingMachineData #(
    parameter N = `DWIDTH
) (
    input logic clk,
    input logic [3:0] selval, 
    input logic [2:0] selnext,
    input logic sub,
    input logic [N-1:0] price,
    output logic enough,
    output logic zero
);


    // Internal Signal Definitions:
    logic [N-1:0] amount, next_amount, value, sum;


    // Amount register
    always_ff @(posedge clk) amount <= next_amount;

    // value mux
    always_comb begin
        case (selval)
            4'b1000: value = price;
            4'b0100: value = N'(`NICKEL); // need to cast to N width
            4'b0010: value = N'(`DIME);
            4'b0001: value = N'(`QUARTER);
            default: value = '0;
        endcase
    end

    //add and sub  for sum signal
    assign sum = sub ? (amount - value) : (amount + value);

    // Next amount mux
    always_comb begin
        case(selnext)
            3'b100: next_amount = amount;
            3'b010: next_amount = sum;
            3'b001: next_amount = '0;
            default: next_amount = amount;
        endcase
    end

    // Status signals:
    assign enough = (amount >= price);
    assign zero = ~(|amount);


endmodule : VendingMachineData
