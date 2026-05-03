module decoder #(
    parameter N = 2,
    parameter M = 4
) (
    input logic[N-1:0] d_in,
    output logic [M-1:0] d_out
);
    assign d_out = (1 << d_in);    
endmodule