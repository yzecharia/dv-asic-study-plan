class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    my_component my_component_h;

    function new (string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        $display("my_test: build_phase");
        my_component_h = my_component::type_id::create("my_component_h", this);
    endfunction : build_phase
endclass : my_test