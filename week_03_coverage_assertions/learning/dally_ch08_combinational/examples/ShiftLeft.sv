module ShiftLeft #(
    parameter K=8, LK=3
) (
    input logic [LK-1:0] n, // How much to shift?
    input logic [K-1:0] a, // Number to shift
    output logic [2*K-1:0] b // Output
);

    assign b = a<<n;

endmodule
