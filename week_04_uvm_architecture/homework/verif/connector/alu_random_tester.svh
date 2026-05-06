class alu_random_tester extends alu_base_tester;
    `uvm_component_utils(alu_random_tester)

    function new(string name = "alu_random_tester", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function bit [WIDTH-1:0] get_operand();
        bit [1:0] operand_type;
        operand_type = $urandom;
        case(operand_type)
            2'b00: return '0;
            2'b11: return '1;
            default: return $urandom_range(1, (2**(WIDTH)) - 2);
        endcase
    endfunction : get_operand

    virtual function operation_e get_operation();
        return operation_e'($urandom_range(ADD, XOR));
    endfunction : get_operation

endclass : alu_random_tester