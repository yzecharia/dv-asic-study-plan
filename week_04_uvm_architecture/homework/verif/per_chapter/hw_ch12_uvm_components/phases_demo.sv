import uvm_pkg::*;
`include "uvm_macros.svh"
class my_component extends uvm_component;
    `uvm_component_utils(my_component)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        $display("my_component: build");
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        $display("my_component: run");
        phase.drop_objection(this);
    endtask : run_phase
endclass : my_component

class my_test extends uvm_test;
    `uvm_component_utils(my_test)
    my_component comp_h;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        $display("my_test: build");
        comp_h = my_component::type_id::create("comp_h", this);
    endfunction : build_phase
endclass : my_test

module top; 
    initial begin
        run_test();
    end
endmodule : top