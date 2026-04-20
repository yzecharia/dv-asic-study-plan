module BarrelShift #(
    parameter K=8, LK=3
)(
    input logic [LK-1:0] n,
    input logic [K-1:0] a,
    output logic [K-1:0] b
);

    logic [2*K-2:0] x = a << n;
    assign b = x[K-1:0] | {1'b0, x[2*K-2:K]};

endmodule
