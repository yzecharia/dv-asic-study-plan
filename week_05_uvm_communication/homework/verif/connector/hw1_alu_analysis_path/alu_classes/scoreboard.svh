class scoreboard extends uvm_subscriber #(result_t);
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(command_t) cmd_fifo;

    int pass, fail;

    function new (string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        cmd_fifo = new("cmd_fifo", this);
        pass = 0;
        fail = 0;
    endfunction : new

    function void write (result_t t);
        command_t cmd_in;
        result_t exp_result;
        if (!cmd_fifo.try_get(cmd_in)) begin
            `uvm_error(get_type_name(), "Failed to get command from tlm")
            fail++;
        end
        else begin
            exp_result = expected_result(cmd_in);
            if (exp_result === t) pass++;
            else fail++;
        end
    endfunction : write

    function result_t expected_result(command_t cmd);
        result_t res;
        case(cmd.op)
            OP_ADD: res = cmd.a + cmd.b;
            OP_AND: res = cmd.a & cmd.b;
            OP_XOR: res = cmd.a ^ cmd.b;
            OP_MUL: res = cmd.a * cmd.b;
        endcase
        return res;
    endfunction : expected_result

    function void report_phase (uvm_phase phase);
        if (fail == 0) `uvm_info(get_type_name(), $sformatf("Test PASS: %0d/%0d", pass, pass+fail), UVM_LOW)
        else `uvm_info(get_type_name(), $sformatf("Test FAIL: %0d/%0d", fail, fail+pass), UVM_LOW)
    endfunction : report_phase
endclass : scoreboard