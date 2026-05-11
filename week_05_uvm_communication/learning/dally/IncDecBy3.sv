module IncDecBy3 #(
    parameter N = 8
) (
    input logic clk, rst, up, down,
    output logic [N-1:0] out
);

    logic [N-1:0] next_out, outpm3;

    assign outpm3 = out + (down ? (~2) : 3); // +3 = 0000_00(11) = 3, -3 = 1111_11(01) = ~2

    always_ff @(posedge clk) out <= next_out;

    always_comb begin
        casex ({rst, up, down})
            3'b1xx: next_out = '0;
            3'b010: next_out = outpm3;
            3'b001: next_out = outpm3;
            3'b000: next_out = out;
            default: next_out = 'x;
        endcase
    end

    

endmodule : IncDecBy3