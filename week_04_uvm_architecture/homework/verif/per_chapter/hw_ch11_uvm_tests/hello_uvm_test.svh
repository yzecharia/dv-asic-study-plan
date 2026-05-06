class hello_uvm_test extends uvm_test;

    `uvm_component_utils(hello_uvm_test)

    function new (string name = "hello_uvm_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        $display("Hello world!");
        phase.drop_objection(this);
    endtask : run_phase

endclass : hello_uvm_test