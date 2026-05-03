module Enc42(
    input [3:0] a,
    output logic [1:0] b
);

    assign b = {a[3] | a[2], a[3] | a[1]};

endmodule

