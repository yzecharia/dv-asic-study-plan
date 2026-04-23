// Verif HW2 — Skeleton UVM Environment
// Spec: docs/week_04.md, HW2
//   Build a minimal UVM env for the ALU DUT:
//   - alu_transaction  (extends uvm_sequence_item)
//   - alu_driver       (extends uvm_driver #(alu_transaction))
//   - alu_monitor      (extends uvm_monitor)
//   - alu_sequencer    (extends uvm_sequencer #(alu_transaction))
//   - alu_agent        (extends uvm_agent) — contains driver + sequencer + monitor
//   - alu_env          (extends uvm_env) — contains agent
//   - alu_base_test    (extends uvm_test) — builds env, runs sequence

package alu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ─── Transaction ─────────────────────────────────────────────────────
    class alu_transaction extends uvm_sequence_item;
        // TODO: rand bit [7:0]  operand_a, operand_b;
        //       rand bit [2:0]  operation;
        //            bit [8:0]  result;

        `uvm_object_utils(alu_transaction)

        function new(string name = "alu_transaction");
            super.new(name);
        endfunction
    endclass

    // ─── Driver ──────────────────────────────────────────────────────────
    class alu_driver extends uvm_driver #(alu_transaction);
        // TODO: virtual alu_if vif;

        `uvm_component_utils(alu_driver)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // TODO: virtual function void build_phase(uvm_phase phase);
        // TODO: virtual task run_phase(uvm_phase phase);
    endclass

    // ─── Monitor ─────────────────────────────────────────────────────────
    class alu_monitor extends uvm_monitor;
        // TODO: virtual alu_if vif;
        // TODO: uvm_analysis_port #(alu_transaction) ap;

        `uvm_component_utils(alu_monitor)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // TODO: virtual function void build_phase(uvm_phase phase);
        // TODO: virtual task run_phase(uvm_phase phase);
    endclass

    // ─── Sequencer ───────────────────────────────────────────────────────
    typedef uvm_sequencer #(alu_transaction) alu_sequencer;

    // ─── Agent ───────────────────────────────────────────────────────────
    class alu_agent extends uvm_agent;
        alu_driver    drv;
        alu_sequencer seqr;
        alu_monitor   mon;

        `uvm_component_utils(alu_agent)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // TODO: build_phase — create drv/seqr/mon via factory
        // TODO: connect_phase — drv.seq_item_port.connect(seqr.seq_item_export);
    endclass

    // ─── Env ─────────────────────────────────────────────────────────────
    class alu_env extends uvm_env;
        alu_agent agent;

        `uvm_component_utils(alu_env)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // TODO: build_phase — create agent
    endclass

    // ─── Base test ───────────────────────────────────────────────────────
    class alu_base_test extends uvm_test;
        alu_env env;

        `uvm_component_utils(alu_base_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        // TODO: build_phase — create env, get vif from config_db, set on driver/monitor
        // TODO: run_phase — objection + start a sequence
    endclass

endpackage
