module Mux3a 
#(
    parameter K = 1
)
(
    input logic [K-1:0] a0, a1, a2,
    input logic [2:0] s,
    output logic [K-1:0] b
);

    always_comb begin
        case(s)
            3'b001: b = a0;
            3'b010: b = a1;
            3'b100: b = a2;
            default: b = {K{1'bx}};
        endcase
    end

endmodule

