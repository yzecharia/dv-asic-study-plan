virtual class base_tester extends uvm_component;
    `uvm_component_utils(base_tester)

    function new (string name = "base_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction :build_phase

    task run_phase(uvm_phase phase);
        byte iA;
        int op;
        phase.raise_objection(this);
            repeat(10) begin
                iA = get_data();
                op = get_op();

                $display("base_tester: data=%0h, op=%0d", iA, op);
            end
        phase.drop_objection(this);
    endtask : run_phase

    pure virtual function int get_op();
    pure virtual function byte get_data();

endclass : base_tester