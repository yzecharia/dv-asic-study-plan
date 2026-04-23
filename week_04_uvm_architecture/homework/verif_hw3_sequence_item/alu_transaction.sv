// Verif HW3 — Full sequence_item implementation
// Spec: docs/week_04.md, HW3
//   Take alu_transaction and fully implement:
//   - rand fields + constraints
//   - do_copy, do_compare
//   - convert2string
//   - `uvm_object_utils_begin / `uvm_field_* / `uvm_object_utils_end
//     (auto-generates copy/compare/print/record/pack/unpack via macros)

`include "uvm_macros.svh"

class alu_transaction extends uvm_sequence_item;

    // TODO: rand bit [7:0]  operand_a, operand_b;
    //       rand bit [2:0]  operation;
    //            bit [8:0]  result;
    //            bit        valid_out;

    // Option A — field macros (less manual code, slower runtime)
    `uvm_object_utils_begin(alu_transaction)
        // TODO: `uvm_field_int(operand_a, UVM_ALL_ON)
        //       `uvm_field_int(operand_b, UVM_ALL_ON)
        //       `uvm_field_int(operation, UVM_ALL_ON)
        //       `uvm_field_int(result,    UVM_ALL_ON | UVM_NOCOMPARE)  // monitor fills, don't compare on drive
    `uvm_object_utils_end

    // TODO: constraints
    // constraint c_operation { operation inside {[0:4]}; }

    function new(string name = "alu_transaction");
        super.new(name);
    endfunction

    // Option B — hand-written methods (alternative to field macros — usually faster)
    // extern virtual function void do_copy(uvm_object rhs);
    // extern virtual function bit  do_compare(uvm_object rhs, uvm_comparer comparer);
    // extern virtual function string convert2string();

endclass
