/*
    This is an 8 bit signed add/sub module. Tells when results cant fit in 8 bits (overflow flag). It uses 2 tricks:
        1. subtraction: a - b = a + (~b) + 1
        2. splitting the adder so we can get c[N] and c[N-1] for overflow flag

    This is a Structural code
*/

module addsub #(
    parameter N=8
) (
    input logic [N-1:0] a, b,
    input logic sub,
    output logic [N-1:0] s,
    output logic ovf
);

    logic c1, c2;

    assign ovf = c1 ^ c2;       // Get the overflow flag from the last carryout and the carry out before it

    // first split: take [N-2:0] (7 bits) of a and b^{7{sub}} + sub to get s[N-2:0] and c1
    adder1 #(N-1) ai (.a(a[N-2:0]), .b(b[N-2:0] ^ {N-1{sub}}), .cin(sub), .s(s[N-2:0]), .cout(c1));
    adder2 #(1) as (.a(a[N-1]), .b(b[N-1] ^ sub), .cin(c1), .s(s[N-1]), .cout(c2));

endmodule : addsub