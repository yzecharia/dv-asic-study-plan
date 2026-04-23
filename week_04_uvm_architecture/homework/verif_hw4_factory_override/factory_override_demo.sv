// Verif HW4 — Factory Override Exercise
// Spec: docs/week_04.md, HW4
//   Demonstrate factory overrides:
//   1. Create a base transaction class
//   2. Create an extended class with different constraints / behavior
//   3. Show how set_type_override_by_type() swaps the child for the parent
//      without changing the code that creates the object via type_id::create()
//   4. Prove that objects created in the testbench are of the extended type

`include "uvm_macros.svh"

package factory_demo_pkg;
    import uvm_pkg::*;

    // ─── Base class ──────────────────────────────────────────────────────
    class base_tx extends uvm_sequence_item;
        rand bit [7:0] data;
        `uvm_object_utils(base_tx)

        function new(string name = "base_tx");
            super.new(name);
        endfunction

        // TODO: virtual function string convert2string();
    endclass

    // ─── Extended class (different constraint) ──────────────────────────
    class bounded_tx extends base_tx;
        `uvm_object_utils(bounded_tx)

        // TODO: constraint c_bounded { data inside {[0:15]}; }

        function new(string name = "bounded_tx");
            super.new(name);
        endfunction
    endclass

endpackage

// ─── Test module ────────────────────────────────────────────────────────
module factory_override_tb;
    import uvm_pkg::*;
    import factory_demo_pkg::*;

    initial begin
        base_tx tx;

        // TODO:
        // 1. Create tx normally — should be base_tx
        //    tx = base_tx::type_id::create("tx");
        //    $display("Before override: %s", tx.get_type_name());
        //
        // 2. Register override
        //    factory.set_type_override_by_type(base_tx::get_type(), bounded_tx::get_type());
        //
        // 3. Create tx again — should now be bounded_tx under the hood
        //    tx = base_tx::type_id::create("tx");
        //    $display("After override: %s", tx.get_type_name());
        //
        // 4. Randomize and print — constraints should be bounded_tx's

        $finish;
    end

endmodule
