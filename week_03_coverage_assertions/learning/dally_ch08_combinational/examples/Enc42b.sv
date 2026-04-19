module Enc42b (
    input [3:0] a,
    output logic [1:0] b
);  

    always_comb begin
        case (a)
            4'b1000: b = 2'b11;
            4'b0100: b = 2'b10;
            4'b0010: b = 2'b01;
            4'b0001: b = 2'b00;
            4'b0000: b = 2'b00;
            default: b = 2'bxx;
        endcase
    end

endmodule
