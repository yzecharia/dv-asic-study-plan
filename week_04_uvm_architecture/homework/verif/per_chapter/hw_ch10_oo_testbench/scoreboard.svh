class scoreboard;
    virtual tinyalu_bfm bfm;

    function new (virtual tinyalu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        shortint predicted_result;
        forever begin
            @(posedge bfm.done);
            #1;
            case (bfm.op_set)
                add_op: predicted_result = bfm.A + bfm.B;
                and_op: predicted_result = bfm.A & bfm.B;
                xor_op: predicted_result = bfm.A ^ bfm.B;
                mul_op: predicted_result = bfm.A * bfm.B;
                default: predicted_result = '0;
            endcase
            if (predicted_result != bfm.result)
                $error("FAILED: A=%0h B=%0h op=%s expected=%0h got=%0h",
                       bfm.A, bfm.B, bfm.op_set.name(),
                       predicted_result, bfm.result);
        end
    endtask : execute

endclass : scoreboard
