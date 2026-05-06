class add_tester extends random_tester;
    `uvm_component_utils(add_tester)

    function new(string name = "add_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function int get_op();
        return 1;
    endfunction : get_op
    
endclass : add_tester