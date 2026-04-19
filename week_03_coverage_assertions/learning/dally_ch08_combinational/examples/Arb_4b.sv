module Arb_4b (
    input logic [3:0] r,
    output logic [3:0] g
);

    always_comb begin
        casex(r)
            4'b0000: g = 4'b0000;
            4'bxxx1: g = 4'b0001;
            4'bxx10: g = 4'b0010;
            4'bx100: g = 4'b0100;
            4'b1000: g = 4'b1000;
            default: g = 4'hx;
        endcase
    end

endmodule