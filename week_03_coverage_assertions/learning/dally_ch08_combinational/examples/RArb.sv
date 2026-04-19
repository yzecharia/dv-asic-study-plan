module RArb #(
    parameter N=8
) (
    input logic [N-1:0] r,
    output logic [N-1:0] g
);

    logic [N-1:0] c = {1'b1, ~r[N-1:1] & c[N-1:1]};
    assign g = r & c;

endmodule