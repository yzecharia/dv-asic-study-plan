module UDL_Count1 #(
    parameter N=4
) (
    input logic clk, rst, up, down, load,
    input logic [N-1:0] in,
    output logic [N-1:0] out
);

    logic [N-1:0] next;

    always_ff @(posedge clk) begin
        out <= next;
    end

    always_comb begin
        casex ({rst, up, down, load})
            4'b1xxx: next = '0;
            4'b01xx: next = out + 1'b1;
            4'b001x: next = out - 1'b1;
            4'b0001: next = in;
            default: next = out;
        endcase
    end

endmodule : UDL_Count1