module EqComp #(
    parameter K=8
)(
    input logic [K-1:0] a, b,
    output logic eq
);
    assign eq = (a==b);
    //assign eq = &(~(a^b)); ~|(a^b);
endmodule