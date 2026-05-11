// This is like UDL_Count1, but instead of incrementer and decrementer we use 2's comp

module UDL_Count2 # (
    parameter N = 4
) (
    input logic clk, rst, up, down, load,
    input logic [N-1:0] in,
    output logic [N-1:0] out
);
    logic [N-1:0] next;
    logic [N-1:0] outpml;

    assign outpml = out + {{N-1{~up}}, 1'b1}; // If up is 1 = 0001, else down 1111;
    always_ff @(posedge clk) begin
        out <= next;
    end

    always_comb begin
        casex ({rst, up, down, load})
            4'b1xxx: next = '0;
            4'b01xx: next = outpml;
            4'b001x: next = outpml;
            4'b0001: next = in;
            default: next = out;
        endcase
    end
endmodule : UDL_Count2