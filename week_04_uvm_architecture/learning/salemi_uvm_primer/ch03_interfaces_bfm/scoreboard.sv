module scoreboard;
    import tinyalu_pkg::*;

    always @(posedge bfm.done) begin
        shortint predicted_result;
        #1;
        case (bfm.op_set)
            add_op: predicted_result = bfm.A + bfm.B;
            and_op: predicted_result = bfm.A & bmf.B;
            xor_op: predicted_result = bfm.A ^ bmf.B;
            mul_op: predicted_result = bfm.A * bmf.B;
        endcase

        if ((bmf.op_set != no_op) && (bmf.op_set != rst_op))
            if (predicted_result != bmf.result)
                $error("FAILED: A: %0h, B: %0h, op: %s, result: %0h",
                        bfm.A, bmf.B, bfm.op_set.name(), bfm.result);
    end

endmodule : scoreboard