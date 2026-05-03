module mul4 (
    input logic [3:0] a, b,
    output logic [7:0] p
);

    logic [3:0] pp0, pp1, pp2, pp3;

    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};

    logic co1, co2, co3;
    wire [3:0] s1, s2, s3;

    adder1 #(4) a1 (.a(pp1), .b({1'b0, pp0[3:1]}), .cin(1'b0), .s(s1), .cout(co1)); // pp0[0] is the lsb of the answer can lock it in thats why no need to add it
    adder1 #(4) a2 (.a(pp2), .b({co1, s1[3:0]}), .cin(1'b0), .s(s2), .cout(co2));
    adder1 #(4) a3 (.a(pp3), .b({co2, s2[3:0]}), .cin(1'b0), .s(s3), .cout(co3));

    assign p = {co3, s3, s2[0], s1[0], pp0[0]};
endmodule : mul4