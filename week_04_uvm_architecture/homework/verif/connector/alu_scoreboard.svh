class alu_scoreboard extends uvm_component;
    `uvm_component_utils(alu_scoreboard)

    virtual alu_if aluif;

    function new(string name = "alu_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_fatal("NOALUIF", "aluif not set in config_db")
    endfunction : build_phase


    // This is a passive agent so no need to raise objections, The tester will do this
    task run_phase(uvm_phase phase);
        logic [WIDTH:0] expected_result;

        forever begin
            @(aluif.monitor_cb);
            if (aluif.monitor_cb.valid_out) begin
                case(aluif.monitor_cb.operation)
                    ADD: expected_result = aluif.monitor_cb.operand_a + aluif.monitor_cb.operand_b;
                    SUB: expected_result = aluif.monitor_cb.operand_a - aluif.monitor_cb.operand_b;
                    AND: expected_result = {1'b0, aluif.monitor_cb.operand_a & aluif.monitor_cb.operand_b};
                    OR: expected_result = {1'b0, aluif.monitor_cb.operand_a | aluif.monitor_cb.operand_b};
                    XOR: expected_result = {1'b0, aluif.monitor_cb.operand_a ^ aluif.monitor_cb.operand_b};
                    default: expected_result = '0;
                endcase

                if (expected_result != aluif.monitor_cb.result)
                    `uvm_error("MISMATCH", $sformatf("A=%0h B=%0h op=%0d expected=%0h got=%0h",
                                aluif.monitor_cb.operand_a, aluif.monitor_cb.operand_b,
                                aluif.monitor_cb.operation, expected_result, aluif.monitor_cb.result))
            end
        end
    endtask : run_phase
endclass : alu_scoreboard
