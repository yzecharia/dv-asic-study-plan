class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    base_tester tester_h;
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tester_h = base_tester::type_id::create("tester_h", this);
    endfunction : build_phase


endclass : my_env