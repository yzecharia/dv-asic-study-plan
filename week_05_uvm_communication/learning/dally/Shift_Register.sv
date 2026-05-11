module Shift_Register #(
    parameter N = 4
) (
    input logic clk, rst, sin,
    output logic [N-1:0] out
);

    logic [N-1:0] next_out;
    
    always_ff @(posedge clk) out <= next_out;

    assign next_out = rst ? '0 : {out[N-2:0], sin};

endmodule : Shift_Register