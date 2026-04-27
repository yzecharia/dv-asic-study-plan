class my_test extends uvm_test;
    `uvm_component_utils(my_test)
    my_env env_h;
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        base_tester::type_id::set_type_override(add_tester::get_type());
        env_h = my_env::type_id::create("env_h", this);
    endfunction : build_phase
endclass : my_test