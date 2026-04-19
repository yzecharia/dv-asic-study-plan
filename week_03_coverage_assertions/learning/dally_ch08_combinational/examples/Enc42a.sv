module Enc42a (
    input [3:0] a,
    output logic [1:0] b,
    output logic c
);

    assign b = {a[3] | a[2], a[3] | a[1]};
    assign c = |a;


endmodule
