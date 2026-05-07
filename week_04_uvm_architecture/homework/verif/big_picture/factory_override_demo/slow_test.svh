class slow_test extends uvm_test;
    `uvm_component_utils(slow_test)

    env env_h;

    function new (string name = "slow_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_h = env::type_id::create("env_h", this);
    endfunction : build_phase


endclass : slow_test