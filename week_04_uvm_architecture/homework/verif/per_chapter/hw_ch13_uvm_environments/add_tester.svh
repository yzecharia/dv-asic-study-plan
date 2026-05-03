class add_tester extends random_tester;
    `uvm_component_utils(add_tester)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function op_t get_op();
        return ADD;
    endfunction : get_op

endclass : add_tester