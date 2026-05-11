// Mux3.sv — 3-input one-hot multiplexer, parametric width.
// sel[k]=1 selects input ik (exactly one bit of sel must be hot).

module Mux3 #(
    parameter N = 6
) (
    input  logic [N-1:0] i2, i1, i0,
    input  logic [2:0]   sel,
    output logic [N-1:0] y
);
    always_comb begin
        unique case (sel)
            3'b100:  y = i2;
            3'b010:  y = i1;
            3'b001:  y = i0;
            default: y = 'x;        // illegal non-one-hot
        endcase
    end
endmodule : Mux3
