class random_tester extends base_tester;

    `uvm_component_utils(random_tester)

    function new(string name = "random_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function int get_op();
        int op_type;
        op_type = $urandom_range(0, 7);
        case(op_type)
            0, 5: return 0;
            6, 7: return 7;
            default: return op_type;
        endcase
    endfunction : get_op

    virtual function byte get_data();
        bit [1:0] data_type;
        data_type = $urandom;
        if (data_type == 2'b00) return 8'h00;
        else if (data_type == 2'b11) return 8'hFF;
        else return byte'($urandom);
    endfunction : get_data

endclass : random_tester