class random_tester extends base_tester;
    `uvm_component_utils(random_tester)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function op_t get_op();
        op_t v;
        assert(std::randomize(v));
        return v;
    endfunction : get_op

    virtual function byte get_data();
        return $urandom;
    endfunction : get_data
endclass : random_tester