class add_test extends uvm_test;
    `uvm_component_utils(add_test)
    env env_h;
    function new(string name = "add_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        base_tester::type_id::set_type_override(add_tester::get_type());
        env_h = env::type_id::create("env_h", this);
    endfunction : build_phase

endclass : add_test