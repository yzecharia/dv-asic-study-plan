import alu_pkg::*;
module simple_alu (
    input command_t cmd,
    output result_t res
);

    always_comb begin
        logic [7:0] result_local;
        logic error_local;
        if (!cmd.valid) {error_local, result_local} = '0;
        else begin
            case (cmd.op) 
                OP_ADD: {error_local, result_local} = cmd.a + cmd.b;
                OP_SUB: {error_local, result_local} = cmd.a - cmd.b;
                OP_AND: {error_local, result_local} = {1'b0, cmd.a & cmd.b};
                OP_OR: {error_local, result_local} = {1'b0, cmd.a | cmd.b};
                OP_XOR: {error_local, result_local} = {1'b0, cmd.a ^ cmd.b};
                OP_SHL: {error_local, result_local} = {1'b0, cmd.a << (cmd.b[2:0])};
                OP_SHR: {error_local, result_local} = {1'b0, cmd.a >> (cmd.b[2:0])};
                OP_NOP: {error_local, result_local} = {1'b1, '0};
                default: {error_local, result_local} = '0;
            endcase
        end

        res = '{
            result: result_local,
            error: error_local,
            id: cmd.id,
            valid: cmd.valid
        };

    end



endmodule : simple_alu
