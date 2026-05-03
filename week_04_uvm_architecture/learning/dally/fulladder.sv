module fulladder (
    input logic a, b, cin,
    output logic s, cout
);
    logic p, g, cp;
    halfadder ha1(a,b, g, p);
    halfadder ha2(cin, p, cp, s);
    assign cout = cp | g;
endmodule : fulladder