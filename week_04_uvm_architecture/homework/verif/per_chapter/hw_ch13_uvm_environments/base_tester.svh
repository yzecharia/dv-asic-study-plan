virtual class base_tester extends uvm_component;
    `uvm_component_utils(base_tester);

    op_t op_h;
    byte data;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    pure virtual function op_t get_op();
    pure virtual function byte get_data();

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        repeat (10) begin
            op_h = get_op();
            data = get_data();
            $display("base_tester: op=%s, data=%b", op_h.name(), data);
        end
        phase.drop_objection(this);
    endtask : run_phase

endclass : base_tester