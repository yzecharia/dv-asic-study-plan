/*
    Carry look ahead works by computing the carry propogate and carry generate accross groups of bits in the upper tree 
    and using these signals to generate the carry signal into each bit in the lower tree.

    p_ij is true if a carry into bit i will propagate from bit i to j and generate a carry out of bit j.
    g_ij is true if a carry will be generated out of bit j regardless of the carry into bit i.

    p_ij = p_i = a_i ^ b_i
    g_ij = g_i = a_i & b_i

    c_i = g_i | p_i & c_(i-1)

    Example:
    g3 = g3 | p3(g2 + p2(g1 + p1g0))

    A block propagetes a carry if all the colums in the block propagate the carry.
    Example: The propagate logic for a block spanning columns 3 through 0 is: 
    p3 = p3 and p2 and p1 and p0

    ci = gij | pij & cj-1

*/

module carry_look_ahead (
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

    assign bg = g[3] | (p[3] & g[2]) | (p[3] & p[2] & p[1]) | (p[3] & g[3] & g[2] & g[1] & g[0]);
    assign bp = p[3] & p[2] & p[1] & p[0];

    assign c[4] = bg | (bp & ci);
    assign s = p ^ c[3:0];
    assign co = c[4];
endmodule