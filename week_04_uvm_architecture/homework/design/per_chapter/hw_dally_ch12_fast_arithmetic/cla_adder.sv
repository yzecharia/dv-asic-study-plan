module cla_adder (
    input logic [15:0] a, b,
    input logic cin, 
    output logic [15:0] s,
    output logic cout,
    output logic bg_grp,
    output logic bp_grp
);

    logic [3:0] block_bg;
    logic [3:0] block_bp;
    logic [3:1] c_inter;

    cla4 b0 (.a(a[3:0]), .b(b[3:0]), .ci(cin), .s(s[3:0]), .co(), .bg(block_bg[0]), .bp(block_bp[0]));
    cla4 b1 (.a(a[7:4]), .b(b[7:4]), .ci(c_inter[1]), .s(s[7:4]), .co(), .bg(block_bg[1]), .bp(block_bp[1]));
    cla4 b2 (.a(a[11:8]), .b(b[11:8]), .ci(c_inter[2]), .s(s[11:8]), .co(), .bg(block_bg[2]), .bp(block_bp[2]));
    cla4 b3 (.a(a[15:12]), .b(b[15:12]), .ci(c_inter[3]), .s(s[15:12]), .co(), .bg(block_bg[3]), .bp(block_bp[3]));


    lcu4 lcu(.bg(block_bg), .bp(block_bp), .cin(cin), .cout(c_inter), .bp_grp(bp_grp), .bg_grp(bg_grp), .carry_out(cout));

endmodule : cla_adder