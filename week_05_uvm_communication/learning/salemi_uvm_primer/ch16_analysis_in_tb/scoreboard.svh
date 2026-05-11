class scoreboard extends uvm_subscriber #(shortint);
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(command_s) cmd_f;

    function void build_phase (uvm_phase phase);
        cmd_f = new("cmd_f", this);
    endfunction : build_phase

    function void write (shortint t);
        shortint predicted_result;
        command_s cmd;
        cmd.op = no_op;


        // Going through cmd_f. if op is no_op or rst_op we continue the search.
        // When a cmd hit that is not (no_op or rst_op) we continue to check what command it is
        // try_get(cmd) returns 0 if there are no commands in the FIFO, So in that case we through a fatal exception
        do
            if (!cmd_f.try_get(cmd)) $fatal(1, "No command in self checker");
        while ((cmd.op == no_op) || (cmd.op == rst_op));

        case (cmd.op)
            add_op: predicted_result = cmd.A + cmd.B;
            and_op: predicted_result = cmd.A & cmd.B;
            xor_op: predicted_result = cmd.A ^ cmd.B;
            mul_op: predicted_result = cmd.A * cmd.B;
        endcase 

        if (predicted_result != t)
            $error(
                "FAILED: A: %2h B: %2h op: %s actual result: %4h    expected: %4h",
                cmd.A, cmd.B, cmd.op.name(), t, predicted_result
            );

    endfunction : write

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : scoreboard