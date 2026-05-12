import alu_pkg::*;

module simple_alu_tb;

    command_t cmd;
    result_t res;
    result_t exp_res;
    int pass_count = 0; // added: counts passing checks
    int fail_count = 0; // added: counts failing checks

    simple_alu dut (cmd, res);

    function command_t randomize_command();
        return '{
            op: alu_op_t'($urandom_range(0,7)),
            a: 8'($urandom()),
            b: 8'($urandom()),
            id: 4'($urandom()),
            valid: 1'($urandom())
        };
    endfunction : randomize_command

    task drive_command (command_t d_cmd);
        cmd = d_cmd;
        #1;
        verify();
    endtask : drive_command

    task drive_ramdom ();
        drive_command(randomize_command());
    endtask : drive_ramdom


    function verify ();
        exp_res = '{
            result: '0,
            error: 1'b0,
            id: cmd.id,
            valid: cmd.valid
        };
        if (cmd.valid) begin
            case (cmd.op)
                OP_ADD: {exp_res.error, exp_res.result} = cmd.a + cmd.b;
                OP_SUB: {exp_res.error, exp_res.result} = cmd.a - cmd.b;
                OP_AND: {exp_res.error, exp_res.result} = {1'b0, cmd.a & cmd.b};
                OP_OR: {exp_res.error, exp_res.result} = {1'b0, cmd.a | cmd.b};
                OP_XOR: {exp_res.error, exp_res.result} = {1'b0, cmd.a ^ cmd.b};
                OP_SHL: {exp_res.error, exp_res.result} = {1'b0, cmd.a << (cmd.b[2:0])};
                OP_SHR: {exp_res.error, exp_res.result} = {1'b0, cmd.a >> (cmd.b[2:0])};
                OP_NOP: {exp_res.error, exp_res.result} = {1'b1, '0};
                default: {exp_res.error, exp_res.result} = '0;
            endcase
        end

        if ((exp_res.result !== res.result) || (exp_res.error !== res.error) || (exp_res.id !== res.id) || (exp_res.valid !== res.valid)) begin // fixed: was multi-line string, now %p prints whole struct on one line
            $error("Test failed: got=%p exp=%p", res, exp_res);
            fail_count++; // added: tally failure
        end else begin
            pass_count++; // added: tally pass
        end
    endfunction : verify


    initial begin
        alu_op_t op;

        $dumpfile("waves.vcd");    
        $dumpvars(0, simple_alu_tb); 
        op = op.first();
        // check !valid sets error and result to 0
        for (int i = 0; i < op.num(); i ++ ) begin
            drive_command('{op:op, a:8'($urandom()), b:8'($urandom()), id:4'($urandom()), valid:1'b0 });
            drive_command('{op:op, a:8'h00, b:8'h00, id:4'($urandom()), valid:1'b1});
            drive_command('{op:op, a:8'hFF, b:8'hFF, id:4'($urandom()), valid:1'b1});
            op = op.next();
        end

        repeat (100) begin
            drive_ramdom();
        end

        // added: final pass/fail report at end of sim
        if (fail_count == 0) $display("PASS: %0d / %0d checks", pass_count, pass_count);
        else                 $fatal(1, "FAIL: %0d / %0d checks failed", fail_count, pass_count + fail_count);
        $finish;
    end

endmodule : simple_alu_tb

