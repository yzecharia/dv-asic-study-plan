module Enc164 (
    input [15:0] a,
    output logic [3:0] b
);
    logic [7:0] c;
    logic [3:0] valid;
    Enc42a e0 (a[3:0], c[1:0], valid[0]);
    Enc42a e1 (a[7:4], c[3:2], valid[1]);
    Enc42a e2 (a[11:8], c[5:4], valid[2]);
    Enc42a e3 (a[15:12], c[7:6], valid[3]);

    Enc42 e4 (valid, b[3:2]);
    assign b[1] = c[1] | c[3] | c[5] | c[7];
    assign b[0] = c[0] | c[2] | c[4] | c[6];


endmodule