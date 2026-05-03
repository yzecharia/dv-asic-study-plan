module cla16 (
    input  logic [15:0] a, b,
    input  logic        ci,
    output logic [15:0] s,
    output logic        co
);
    logic [3:0] BG, BP;            // block G/P from each cla4
    logic [4:0] C;                  // C[0]=ci, C[4]=c into block 1, ... C[16]=cout

    assign C[0] = ci;

    // Four cla4 blocks
    carry_look_ahead b0 (.a(a[ 3: 0]), .b(b[ 3: 0]), .ci(C[0]), .s(s[ 3: 0]), .co(), .bg(BG[0]), .bp(BP[0]));
    carry_look_ahead b1 (.a(a[ 7: 4]), .b(b[ 7: 4]), .ci(C[1]), .s(s[ 7: 4]), .co(), .bg(BG[1]), .bp(BP[1]));
    carry_look_ahead b2 (.a(a[11: 8]), .b(b[11: 8]), .ci(C[2]), .s(s[11: 8]), .co(), .bg(BG[2]), .bp(BP[2]));
    carry_look_ahead b3 (.a(a[15:12]), .b(b[15:12]), .ci(C[3]), .s(s[15:12]), .co(), .bg(BG[3]), .bp(BP[3]));

    // Second-level look-ahead carry generator — compare to cla4's c[1]..c[4]!
    assign C[1] = BG[0] | (BP[0] & ci);
    assign C[2] = BG[1] | (BP[1] & BG[0]) | (BP[1] & BP[0] & ci);
    assign C[3] = BG[2] | (BP[2] & BG[1]) | (BP[2] & BP[1] & BG[0]) | (BP[2] & BP[1] & BP[0] & ci);
    assign C[4] = BG[3] | (BP[3] & BG[2]) | (BP[3] & BP[2] & BG[1]) | (BP[3] & BP[2] & BP[1] & BG[0]) | (BP[3] & BP[2] & BP[1] & BP[0] & ci);

    assign co = C[4];
endmodule