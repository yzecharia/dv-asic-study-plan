module cla4 (
    input logic [3:0] a, b,
    input logic ci,
    output logic [3:0] s,
    output logic co,
    output logic bg, bp
);
    logic [3:0] p, g;
    assign p = a ^ b;
    assign g = a & b;

    logic [4:0] c;

    assign c[0] = ci;
    assign c[1] = g[0] | (p[0] & ci);
    assign c[2] = g[1] | (p[1] & (g[0] | (p[0] & ci))); // g[1] + p[1]g[0] + p[1]p[0]ci
    assign c[3] = g[2] | ((p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & ci)); // g[2] + p[2]g[1] + p[2]p[1]g[0] + p[2]p[1]p[0]ci
    //assign c[4] = g[3] | ((p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & ci));

    assign bg = g[3] | p[3] & g[2] | p[3] & p[2] & g[1] | p[3] & p[2] & p[1] & g[0];
    assign bp = p[3] & p[2] & p[1] & p[0];

    assign c[4] = bg | (bp & ci);
    assign s = p ^ c[3:0];
    assign co = c[4];
endmodule : cla4
