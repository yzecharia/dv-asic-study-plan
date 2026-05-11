module LRL_Shift_Register #(
    parameter N = 4
) (
    input logic clk, rst, left, right, load, sin,
    input logic [N-1:0] in,
    output logic [N-1:0] out
);

    logic [N-1:0] next_out;

    always_ff @(posedge clk) out <= next_out;

    always_comb begin
        casex({rst, left, right, load})
            4'b1xxx: next_out = '0;
            4'b01xx: next_out = {out[N-2:0], sin};
            4'b001x: next_out = {sin, out[N-1:1]};
            4'b0001: next_out = in;
            default: next_out = out;
        endcase
    end

endmodule : LRL_Shift_Register