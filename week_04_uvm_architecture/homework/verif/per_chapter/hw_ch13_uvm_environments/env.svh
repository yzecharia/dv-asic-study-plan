class env extends uvm_env;

    `uvm_component_utils(env)

    base_tester base_tester_h;

    function new (string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);

        base_tester_h = base_tester::type_id::create("base_tester_h", this);
    endfunction : build_phase

endclass : env