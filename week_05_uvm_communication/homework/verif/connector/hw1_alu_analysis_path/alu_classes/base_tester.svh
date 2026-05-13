virtual class base_tester extends uvm_component;
    `uvm_component_utils(base_tester)

    virtual alu_if aluif;

    function new (string name = "base_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_error(get_type_name(), "Failed to get aluif");
    endfunction : build_phase

    task run_phase (uvm_phase phase);
        command_t cmd;
        phase.raise_objection(this);
        @(aluif.cb_tb iff aluif.cb_tb.reset_n);
        repeat (RAND_TEST_NUM) begin
            cmd = '{
                op: get_op(),
                a: get_operand(),
                b: get_operand()
            };
            aluif.cb_tb.cmd <= cmd;
            aluif.cb_tb.start <= 1'b1;
            @(aluif.cb_tb iff aluif.cb_tb.done);
            aluif.cb_tb.start <= 1'b0;
            // Wait one cycle so start=0 actually takes effect on the bus
            // before the next iteration re-asserts it. Without this gap,
            // both <= drives schedule for the same clock edge and the
            // command_monitor BFM never sees the 0->1 transition.
            @(aluif.cb_tb);
        end
        phase.drop_objection(this);
    endtask : run_phase

    pure virtual function logic [7:0] get_operand();
    pure virtual function alu_op_e get_op();

endclass : base_tester