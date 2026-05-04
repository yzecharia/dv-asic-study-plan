// Design HW1 — ALU DUT. Spec: docs/week_04.md (Design HW1).
module alu #(
    parameter WIDTH = 8
) (
    input logic clk, rst_n,
    input logic [WIDTH-1:0] operand_a, operand_b,
    input logic valid_in,
    input logic [2:0] operation,
    output logic [WIDTH:0] result,
    output logic valid_out
);  

    typedef enum logic [2:0] {
        ADD = 3'b000,
        SUB = 3'b001,
        AND = 3'b010,
        OR = 3'b011,
        XOR = 3'b100
    } operation_e;

    logic [WIDTH:0] result_reg;
    logic op_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            valid_out <= 1'b0;
        end else begin
            if (op_valid && valid_in) begin
                result <= result_reg;
                valid_out <= 1'b1;
            end else valid_out <= 1'b0;
        end
    end

    logic [WIDTH:0] a, b;
    assign a = {1'b0, operand_a};
    assign b = {1'b0, operand_b};

    always_comb begin
        result_reg = '0;
        op_valid = '1;
        case (operation)
            ADD: result_reg = a + b;
            SUB: result_reg = a - b;
            AND: result_reg = a & b;
            OR: result_reg = a | b;
            XOR: result_reg = a ^ b;
            default: {op_valid, result_reg} = '0;
        endcase
    end
endmodule : alu
