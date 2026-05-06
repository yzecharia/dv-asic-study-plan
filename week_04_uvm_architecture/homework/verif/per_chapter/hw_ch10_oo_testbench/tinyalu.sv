module tinyalu (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    input  logic [7:0]  A,
    input  logic [7:0]  B,
    input  logic [2:0]  op,
    output logic        done,
    output logic [15:0] result
);

    logic [1:0] mul_count;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            result    <= 16'h0000;
            done      <= 1'b0;
            mul_count <= 2'd0;
        end else if (start) begin
            case (op)
                3'b001: begin result <= {8'h00, A} + {8'h00, B}; done <= 1'b1; mul_count <= 2'd0; end
                3'b010: begin result <= {8'h00, (A & B)};        done <= 1'b1; mul_count <= 2'd0; end
                3'b011: begin result <= {8'h00, (A ^ B)};        done <= 1'b1; mul_count <= 2'd0; end
                3'b100: begin
                    if (mul_count == 2'd2) begin
                        result    <= A * B;
                        done      <= 1'b1;
                        mul_count <= 2'd0;
                    end else begin
                        mul_count <= mul_count + 2'd1;
                        done      <= 1'b0;
                    end
                end
                default: begin done <= 1'b0; mul_count <= 2'd0; end
            endcase
        end else begin
            done      <= 1'b0;
            mul_count <= 2'd0;
        end
    end

endmodule : tinyalu
