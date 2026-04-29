module halfadder(
    input logic a, b, 
    output logic c, s
);

    assign s = a ^ b;
    assign c = a & b;

endmodule : halfadder