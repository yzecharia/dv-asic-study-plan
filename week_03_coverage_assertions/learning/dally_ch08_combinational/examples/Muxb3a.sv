module Muxb3a #(
    parameter K=1
) (
    input logic [K-1:0] a0, a1, a2,
    input logic [1:0] sb,
    output logic [K-1:0] b
);
    always_comb begin
        case(sb)
            0: b = a0;
            1: b = a1;
            2: b = a2;
            default: b = '0;
        endcase 
    end
endmodule