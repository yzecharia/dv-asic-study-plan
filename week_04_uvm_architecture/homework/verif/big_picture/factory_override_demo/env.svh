class env extends uvm_env;
    `uvm_component_utils(env)

    slow_driver slow_driver_h;

    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        slow_driver_h = slow_driver::type_id::create("slow_driver_h", this);
    endfunction : build_phase


endclass : env