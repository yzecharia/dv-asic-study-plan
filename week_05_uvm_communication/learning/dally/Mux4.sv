// Mux4.sv — 4-input one-hot multiplexer, parametric width.
// sel[k]=1 selects input ik (exactly one bit of sel must be hot).

module Mux4 #(
    parameter N = 6
) (
    input  logic [N-1:0] i3, i2, i1, i0,
    input  logic [3:0]   sel,
    output logic [N-1:0] y
);
    always_comb begin
        unique case (sel)
            4'b1000: y = i3;
            4'b0100: y = i2;
            4'b0010: y = i1;
            4'b0001: y = i0;
            default: y = 'x;        // illegal non-one-hot
        endcase
    end
endmodule : Mux4
