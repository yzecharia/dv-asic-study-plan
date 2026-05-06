class alu_random_test extends uvm_test;
    `uvm_component_utils(alu_random_test)
    
    alu_env env_h;

    function new(string name = "alu_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        alu_base_tester::type_id::set_type_override(alu_random_tester::get_type());
        env_h = alu_env::type_id::create("env_h", this);
    endfunction : build_phase
endclass : alu_random_test