module UnvShCnt #(
    parameter N = 4
) (
    input logic clk, rst, left, right, up, down, load, sin,
    input logic [N-1:0] in,
    output logic [N-1:0] out,
    output logic done
);

    logic [N-1:0] next_out;
    always_ff @(posedge clk) out <= next_out;

    logic[N-1:0] outpm1;

    assign outpm1 = out + {{N-1{down}}, 1'b1};

    logic [6:0] sel;
    RArb #(7) arb ({rst, left, right, up, down & ~done, load, 1'b1}, sel);
    Mux7 #(N) mux ({N{1'b0}}, {out[N-2:0], sin}, {sin, out[N-1:1]}, outpm1, outpm1, in, out, sel, next_out);

    assign done = ~(|out);

endmodule : UnvShCnt

module Mux7 #(
    parameter N = 4
) (
    input logic [N-1:0] i6, i5, i4, i3, i2, i1, i0,
    input logic [6:0] sel,
    output logic [N-1:0] y
);

    always_comb begin
        unique case (sel)
            7'b100_0000: y = i6;
            7'b010_0000: y = i5;
            7'b001_0000: y = i4;
            7'b000_1000: y = i3;
            7'b000_0100: y = i2;
            7'b000_0010: y = i1;
            7'b000_0001: y = i0;
            default: y = 'x;
        endcase
    end

endmodule : Mux7

module RArb #(
    parameter W = 7
) (
    input logic [W-1:0] req,
    output logic [W-1:0] grant
);  

    always_comb begin
        logic found;
        grant = '0;
        found = 1'b0;
        for (int i = W-1; i >= 0; i--) begin
            if (req[i] & !found) begin
                grant[i] = 1'b1;
                found = 1'b1;
            end
        end
    end

endmodule : RArb