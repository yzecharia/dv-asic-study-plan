module ripple_carry_adder #(
    parameter WIDTH = 8
) (
    input logic [WIDTH-1:0] a, b,
    input logic cin,
    output logic [WIDTH-1:0] s,
    output logic cout
);

    logic [WIDTH:0] c;
    logic [WIDTH-1:0] p, g;

    assign c[0] = cin;

    assign p = a ^ b;
    assign g = a & b;

    genvar i;
    generate
        for (i = 1; i <= WIDTH; i++) begin
            assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
        end
    endgenerate

    assign s = p ^ c[WIDTH-1:0];
    assign cout = c[WIDTH];

endmodule : ripple_carry_adder
