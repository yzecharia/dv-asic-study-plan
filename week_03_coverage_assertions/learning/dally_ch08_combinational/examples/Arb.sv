module Arb #(
    parameter N=8
) (
    input [N-1:0] r,
    output logic [N-1:0] g
);

    logic [N-1:0] c = {~r[N-2:0] & c[N-2:0], 1'b1};

    assign g = c & r;

endmodule
