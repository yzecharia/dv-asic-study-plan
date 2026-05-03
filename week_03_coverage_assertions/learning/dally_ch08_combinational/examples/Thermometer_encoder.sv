module Thermometer_encoder (
    input [3:0] code,
    output logic [2:0] num
);

    always_comb begin
        case (code)
            4'b0000: num = 0;
            4'b0001: num = 1;
            4'b0011: num = 2;
            4'b0111: num = 3;
            4'b1111: num = 4;
            default: num = 3'bx;
        endcase
    end

endmodule