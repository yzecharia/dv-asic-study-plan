class alu_directed_tester extends alu_random_tester;
    `uvm_component_utils(alu_directed_tester)

    function new(string name = "alu_directed_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function operation_e get_operation();
        return ADD;
    endfunction : get_operation

endclass : alu_directed_tester