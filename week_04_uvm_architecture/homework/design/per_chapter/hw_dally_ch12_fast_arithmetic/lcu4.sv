module lcu4 (
    input logic [3:0] bg, bp,
    input logic cin,
    output logic [3:1] cout,
    output logic carry_out,
    output logic bg_grp, bp_grp
);
    assign cout[1] = bg[0] | bp[0] & cin;
    assign cout[2] = bg[1] | bp[1] & bg[0] | bp[1] & bp[0] & cin;
    assign cout[3] = bg[2] | bp[2] & bg[1] | bp[2] & bp[1] & bg[0] | bp[2] & bp[1] & bp[0] & cin;
    assign carry_out = bg_grp | bp_grp & cin;

    assign bp_grp = &bp;
    assign bg_grp = bg[3] | bp[3] & bg[2] | bp[3] & bp[2] & bg[1] | bp[3] & bp[2] & bp[1] & bg[0];
endmodule : lcu4
