module Enc83 (
    input [7:0] a,
    output logic [2:0] b
);

    logic [1:0] valid;
    logic [3:0] c;
    Enc42a lower (a[3:0], c[1:0], valid[0]);
    Enc42a higher (a[7:4], c[3:2], valid[1]);

    assign b[2] = valid[1];
    assign b[1] = c[3] | c[1];
    assign b[0] = c[2] | c[0];
 
endmodule