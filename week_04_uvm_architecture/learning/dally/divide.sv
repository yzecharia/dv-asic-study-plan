module divide(y, x, q, r);
    input  [5:0] y;
    input  [2:0] x;
    output [5:0] q;
    output [2:0] r;

    wire co5, co4, co3, co2, co1, co0;

    wire sum5;
    Adder1 #(1) sub5(y[5], ~x[0], 1'b1, co5, sum5);
    assign q[5] = co5 & ~(|x[2:1]);
    wire [5:0] r4 = q[5] ? {sum5, y[4:0]} : y;

    wire [1:0] sum4;
    Adder1 #(2) sub4(r4[5:4], ~x[1:0], 1'b1, co4, sum4);
    assign q[4] = co4 & ~x[2];
    wire [5:0] r3 = q[4] ? {sum4, r4[3:0]} : r4;

    wire [2:0] sum3;
    Adder1 #(3) sub3(r3[5:3], ~x, 1'b1, co3, sum3);
    assign q[3] = co3;
    wire [5:0] r2 = q[3] ? {sum3, r3[2:0]} : r3;

    wire [3:0] sum2;
    Adder1 #(4) sub2(r2[5:2], {1'b0, ~x}, 1'b1, co2, sum2);
    assign q[2] = co2;
    wire [4:0] r1 = q[2] ? {sum2[2:0], r2[1:0]} : r2[4:0];

    wire [3:0] sum1;
    Adder1 #(4) sub1(r1[4:1], {1'b0, ~x}, 1'b1, co1, sum1);
    assign q[1] = co1;
    wire [3:0] r0 = q[1] ? {sum1[2:0], r1[0]} : r1[3:0];

    wire [3:0] sum0;
    Adder1 #(4) sub0(r0[3:0], {1'b0, ~x}, 1'b1, co0, sum0);
    assign q[0] = co0;
    assign r = q[0] ? sum0[2:0] : r0[2:0];
endmodule
