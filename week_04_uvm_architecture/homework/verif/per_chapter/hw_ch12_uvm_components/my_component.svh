class my_component extends uvm_component;
    `uvm_component_utils(my_component)

    function new(string name = "my_component", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        $display("my_component: build_phase");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        $display("my_component: run_phase");
        phase.drop_objection(this);
    endtask : run_phase

endclass : my_component