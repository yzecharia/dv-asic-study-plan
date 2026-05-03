module primed (
    input logic [2:0] d_in,
    output logic isprime
);
    logic [7:0] b;
    decoder #(3,8) d(d_in, b);
    assign isprime = b[1] | b[2] | b[3] | b[5] | b[7];
endmodule