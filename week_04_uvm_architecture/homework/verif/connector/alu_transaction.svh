// uvm_sequence_item extends uvm_object so no need to pass parent
// need to pass parent when dealing with uvm_component

class alu_transaction extends uvm_sequence_item;
    `uvm_object_utils(alu_transaction);

    rand bit [7:0] operand_a, operand_b;
    rand enum {ADD, SUB, AND, OR, XOR};
    bit [8:0] result;

    function new (string name = "alu_transaction");
        super.new(name);
    endfunction : new

    // do-copy


    // do_compare

    
    // convert2string
endclass : alu_transaction