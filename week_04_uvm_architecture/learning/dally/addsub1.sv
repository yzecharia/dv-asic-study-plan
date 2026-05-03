// This is a behavioral code.

module addsub1 #(
    parameter N=8
) (
    input logic [N-1:0] a, b,
    input logic sub,
    output logic [N-1:0] s,
    output logic ovf
);

    logic c1, c2;

    assign ovf = c1 ^ c2;

    assign {c1, s[N-2:0]} = a[N-2:0] + (b[N-2:0] ^ {N-1{sub}}) + sub;
    assign {c2, s[N-1]} = a[N-1] + (b[N-1] ^ sub) + c1;

endmodule : addsub1