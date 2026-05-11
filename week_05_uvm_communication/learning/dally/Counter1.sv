module Counter1 (
    input logic clk, rst,
    output logic [2:0] out
);

    logic [2:0] next;

    always_ff @(posedge clk) begin
        out <= next;
    end

    always_comb begin
        casex ({rst, out})
            4'b1xxx: next = 0;
            4'd0: next = 1;
            4'd1: next = 2;
            4'd2: next = 3;
            4'd3: next = 4;
            4'd4: next = 5;
            4'd5: next = 6;
            4'd6: next = 7;
            4'd7: next = 0;
            default: next = 0;
        endcase
    end

endmodule : Counter1