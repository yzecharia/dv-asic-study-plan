module funnel_shifter #(
    parameter I = 16,
    parameter J = 8,
    localparam int L = $clog2(I-J)    
)(
    input  logic [I-1:0] a,
    input  logic [L-1:0] n,
    output logic [J-1:0] b
);

    assign b = a[n +: J];

endmodule : funnel_shifter