// ============================================================================
// Salemi UVM Primer — CHAPTERS 9-13 — Cheatsheet
//
// Covers the factory pattern, the OO testbench bridge, uvm_test, uvm_components,
// and uvm_environments. Treat this as a syntax reference you scan, not read.
//
// Use: search this file by chapter heading or by macro name.
//      Code blocks are real SV; "// (snippet — needs surrounding pkg/module)"
//      means you'd paste it into your own class/module body.
// ============================================================================


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  GLOBAL HEADER — what every UVM file imports                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   import uvm_pkg::*;          // brings in uvm_test, uvm_env, uvm_component, …
//   `include "uvm_macros.svh"   // brings in `uvm_info, `uvm_component_utils, …
//
// Compile flag (xvlog/xelab):  -L uvm    // link the precompiled UVM library


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  CHAPTER 9 — THE FACTORY PATTERN                                         ║
// ║  "Don't `new()` — ask the factory."                                      ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// The factory is a global registry of class types + an override mechanism.
// Every uvm_component / uvm_object you write must REGISTER itself with the
// factory using one of these macros (placed right after the class statement):
//
//      `uvm_object_utils(class_name)         // for uvm_object descendants
//      `uvm_component_utils(class_name)      // for uvm_component descendants
//      `uvm_object_param_utils(class_name)   // for parameterized uvm_objects
//      `uvm_component_param_utils(class_name)
//
// The macro generates a `type_id` typedef + helper methods so you can:
//
//      lion l = lion::type_id::create("simba", null);          // UVM "new"
//      lion::type_id::get();                                    // singleton proxy
//
// This is what the macro ROUGHLY expands to (don't write this yourself):
//
//      typedef uvm_component_registry #(my_class, "my_class") type_id;
//      static function type_id get_type(); return type_id::get(); endfunction
//      virtual function uvm_object_wrapper get_object_type(); ... endfunction
//      const static string type_name = "my_class";
//      virtual function string get_type_name(); return type_name; endfunction


// ── Example: register and create via factory ───────────────────────────────
class my_driver extends uvm_driver;
    `uvm_component_utils(my_driver)             // ← REGISTER

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : my_driver

// (snippet — needs surrounding component body)
//      my_driver drv;
//      drv = my_driver::type_id::create("drv", this);   // ← BUILD via factory
//                                                       //   (NOT  drv = new(...))


// ── Factory overrides — swap one class for another at runtime ──────────────
//
// TWO flavors:
//    set_type_override_by_type()   ← TYPE-SAFE, preferred
//    set_type_override_by_name()   ← STRING-BASED, brittle but useful for plusargs
//
// Call ONCE in build_phase BEFORE any create() that should be affected.

// (snippet — inside a uvm_test::build_phase)
//   // wherever someone asks for slow_driver, give them fast_driver instead
//   slow_driver::type_id::set_type_override(fast_driver::get_type());
//
//   // or, by name:
//   factory.set_type_override_by_name("slow_driver", "fast_driver");
//
//   // also: instance-specific override (only at one path)
//   factory.set_inst_override_by_type(
//       slow_driver::get_type(),
//       fast_driver::get_type(),
//       "uvm_test_top.env.agt.drv");


// ── Cheat table: factory API ──────────────────────────────────────────────
//
//   T::type_id::create(name, parent)         create instance of T (or override)
//   T::type_id::get()                        get the singleton type-proxy of T
//   T::get_type()                            same as type_id::get()
//   <type>::type_id::set_type_override(...)  install type-level override
//   factory.set_inst_override_by_type(...)   install path-specific override
//   factory.print()                          dump the factory's registered types


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  CHAPTER 10 — OBJECT-ORIENTED TESTBENCH (THE BRIDGE TO UVM)              ║
// ║  "The architecture UVM standardizes — same shape, plain SV classes."     ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Pre-UVM pattern that every UVM testbench is the standardization of:
//
//   testbench (orchestrator)
//      ├── tester       (drives stimulus into BFM)
//      ├── coverage     (samples covergroups)
//      └── scoreboard   (predicts + checks)
//
// Three structural moves you MUST internalize because UVM repeats them all:
//
//   1) Each TB class holds a `virtual <interface_name>` handle to reach the BFM:
//
//          class scoreboard;
//              virtual tinyalu_bfm bfm;          // ← bridge to static hardware
//              function new(virtual tinyalu_bfm b); bfm = b; endfunction
//          endclass
//
//   2) The orchestrator instantiates children, then forks them concurrently:
//
//          task testbench::execute();
//              tester_h     = new(bfm);
//              coverage_h   = new(bfm);
//              scoreboard_h = new(bfm);
//              fork
//                  tester_h.execute();
//                  coverage_h.execute();
//                  scoreboard_h.execute();
//              join_none                 // join_none = fire and don't wait
//          endtask
//
//   3) The top-level module wires the BFM to the DUT and to the testbench:
//
//          module top;
//              tinyalu_bfm bfm();
//              tinyalu DUT (.A(bfm.A), .B(bfm.B), .clk(bfm.clk), ...);
//              testbench tb_h;
//              initial begin
//                  tb_h = new(bfm);
//                  tb_h.execute();
//              end
//          endmodule
//
// In UVM this becomes: virtual interface goes through `uvm_config_db`,
// fork/join_none becomes the run_phase machinery, manual `new()` becomes
// `type_id::create()`, and the orchestrator becomes `uvm_env`.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  CHAPTER 11 — UVM TESTS                                                  ║
// ║  "The first UVM class — your top-level testbench class."                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Class skeleton — MEMORIZE this:

class my_test extends uvm_test;
    `uvm_component_utils(my_test)               // ← REGISTER with factory

    // --- handles to children (env, config, etc.) go here ---

    function new(string name, uvm_component parent);
        super.new(name, parent);                 // ← always call super.new
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);                // ← always call super.build_phase
        // 1) install factory overrides FIRST
        // 2) read config_db
        // 3) create the env: env = my_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);             // ← "don't end the sim yet"
        // 4) create + start sequences here
        #1us;                                     // settling time
        phase.drop_objection(this);              // ← "ok, sim can end"
    endtask
endclass : my_test


// ── uvm_config_db — the shared key/value store between top and components ─
//
// Pattern: top.sv `set`s the BFM/interface; every component `get`s it.
//
//   // in top.sv (scope = null because top is not a uvm_component)
//   uvm_config_db #(virtual my_bfm)::set(null, "*", "bfm", bfm);
//
//   // in any component's build_phase
//   if (!uvm_config_db #(virtual my_bfm)::get(this, "", "bfm", bfm))
//       `uvm_fatal("NOBFM", "BFM not set in config_db")
//
//  arg 1 = scope (this | null)
//  arg 2 = path glob ("*" = anywhere; or specific hierarchical path)
//  arg 3 = key name
//  arg 4 = value (stored OR retrieved depending on set/get)


// ── Top-level module template (the only module you write) ──────────────────
//
//   module tb_top;
//       import uvm_pkg::*;
//       import my_pkg::*;
//       `include "uvm_macros.svh"
//
//       logic clk = 0;  always #5 clk = ~clk;
//       logic rst_n;    initial begin rst_n=0; #50 rst_n=1; end
//
//       my_bfm vif();
//       my_dut dut(.clk(clk), .rst_n(rst_n), .a(vif.a), ...);
//
//       initial begin
//           uvm_config_db #(virtual my_bfm)::set(null, "*", "vif", vif);
//           run_test();      // ← reads +UVM_TESTNAME=<name> plusarg
//       end
//   endmodule


// ── Picking the test at run time ──────────────────────────────────────────
//
//   xsim sim --runall -testplusarg UVM_TESTNAME=my_test
//   vsim +UVM_TESTNAME=my_test top                  // Mentor Questa


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  CHAPTER 12 — UVM COMPONENTS                                              ║
// ║  "Every long-lived UVM thing is a uvm_component. Phases are its life."   ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Class lineage — what extends what:
//
//   uvm_object
//      └── uvm_report_object
//             └── uvm_component
//                    ├── uvm_test
//                    ├── uvm_env
//                    ├── uvm_agent
//                    ├── uvm_driver #(REQ, RSP)
//                    ├── uvm_monitor
//                    ├── uvm_scoreboard
//                    └── uvm_subscriber #(T)
//
// uvm_object descendants (NOT uvm_components — short-lived data):
//      uvm_sequence_item, uvm_sequence


// ── The 9 phases — they ALL run automatically when you call run_test() ────
//
//   1. build_phase             FUNCTION  top-down   (parents create children)
//   2. connect_phase           FUNCTION  bottom-up  (wire TLM ports/imps)
//   3. end_of_elaboration_phase FUNCTION bottom-up   (last sanity check)
//   4. start_of_simulation_phase FUNCTION bottom-up  (print topology, etc.)
//   5. run_phase               TASK      parallel   (where time advances)
//   6. extract_phase           FUNCTION  bottom-up
//   7. check_phase             FUNCTION  bottom-up
//   8. report_phase            FUNCTION  bottom-up
//   9. final_phase             FUNCTION  bottom-up
//
// Rules of thumb:
//   • build_phase = "create my children with type_id::create()"
//   • connect_phase = "wire ap.connect(ap_imp)"  — happens AFTER build is fully done
//   • run_phase = the only TIME-CONSUMING phase. raise_objection here.
//   • Always call super.<phase>(phase) FIRST in your override.


// ── Phase function/task signatures — copy verbatim ────────────────────────

class my_component extends uvm_component;
    `uvm_component_utils(my_component)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // create child components here via type_id::create
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // ap.connect(scb.ap_imp) etc.
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        // ... time-consuming work ...
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        // print pass/fail summary
    endfunction
endclass : my_component


// ── Reporting macros (preferred over $display) ────────────────────────────
//
//   `uvm_info   ("ID", "msg",                UVM_LOW)
//   `uvm_warning("ID", "msg")
//   `uvm_error  ("ID", "msg")
//   `uvm_fatal  ("ID", "msg")
//
// Verbosity levels (used by `uvm_info only):
//   UVM_NONE = 0      always print
//   UVM_LOW  = 100    default
//   UVM_MEDIUM = 200
//   UVM_HIGH = 300
//   UVM_FULL = 400
//   UVM_DEBUG = 500
//
// Set verbosity from CLI:
//   xsim sim -testplusarg UVM_VERBOSITY=UVM_HIGH


// ── Useful introspection methods (every uvm_component has these) ──────────
//
//   string s = get_full_name();          // "uvm_test_top.env.agt.drv"
//   string n = get_name();               // "drv"
//   uvm_component p = get_parent();
//   int    n  = get_num_children();
//   bit    ok = get_is_active();         // for uvm_agent only


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  CHAPTER 13 — UVM ENVIRONMENTS                                            ║
// ║  "Where the OO testbench's orchestrator becomes uvm_env."                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// uvm_env is JUST a uvm_component. The convention is: it composes the
// testbench's children (agent, scoreboard, coverage, …) and connects them.
//
// Skeleton — copy this and fill in:

class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_agent      agt;
    my_scoreboard scb;
    my_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = my_agent     ::type_id::create("agt", this);
        scb = my_scoreboard::type_id::create("scb", this);
        cov = my_coverage  ::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass : my_env


// ── ABSTRACT BASE CLASS PATTERN (ch.13's headline) ────────────────────────
//
// You write a base class that the env always asks for, then derived classes
// (random_tester, add_tester, …) provide the actual stimulus. The TEST
// installs a factory override BEFORE the env builds, so the factory swaps
// the base for the concrete class transparently.
//
// QUESTA portability shim: Questa requires `virtual class` if there are
// pure virtuals; other simulators don't. Use this conditional:
//
//   `ifdef QUESTA
//   virtual class base_tester extends uvm_component;
//   `else
//   class base_tester extends uvm_component;
//   `endif
//       `uvm_component_utils(base_tester)
//
//       pure virtual function operation_t get_op();
//       pure virtual function byte        get_data();
//
//       virtual task run_phase(uvm_phase phase);
//           phase.raise_objection(this);
//           repeat (1000) bfm.send_op(get_data(), get_data(), get_op(), result);
//           phase.drop_objection(this);
//       endtask
//   endclass : base_tester
//
//   class random_tester extends base_tester;
//       `uvm_component_utils(random_tester)
//       function operation_t get_op();   return $random; endfunction
//       function byte        get_data(); return $random; endfunction
//   endclass


// ── The override-then-build pattern (in the test) ─────────────────────────

// (snippet — inside a uvm_test::build_phase)
//   virtual function void build_phase(uvm_phase phase);
//       super.build_phase(phase);
//       // STEP 1: install override BEFORE creating env
//       base_tester::type_id::set_type_override(random_tester::get_type());
//       // STEP 2: create env — its build_phase will ask the factory for
//       //         base_tester, factory will give random_tester instead
//       env_h = my_env::type_id::create("env_h", this);
//   endfunction


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  COMMON GOTCHAS                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
//   • Forgetting `super.<phase>(phase)` — silently breaks UVM internals.
//   • Forgetting `super.new(name, parent)` — same.
//   • Calling `new()` instead of `type_id::create()` — factory overrides
//     stop working.
//   • Missing `uvm_component_utils` macro — class isn't registered, factory
//     can't find it; +UVM_TESTNAME=<name> errors with "no such class".
//   • Doing `set_type_override` AFTER the env is created — too late.
//   • Forgetting to raise/drop objections in run_phase — sim ends instantly.
//   • `uvm_config_db::get` returning 0 silently — always check the return:
//        if (!uvm_config_db #(T)::get(...)) `uvm_fatal(...)
//   • Compile-order bug: package compiled BEFORE the interface it references
//     as `virtual <iface>`. Workaround: pass both files to xvlog in one call,
//     interface first, package second.


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  THE 6 SELF-CHECK QUESTIONS (from week_04.md) — make sure you can answer ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// 1) What's the difference between uvm_object and uvm_component?
//    → uvm_object = data, no hierarchy, short-lived (transactions, sequences,
//      configs). uvm_component = persistent, has parent/children, has phases
//      (drivers, monitors, env, test).
//
// 2) Why use type_id::create() instead of new()?
//    → So the factory can swap in an override at runtime without touching
//      the calling code. new() bypasses the factory.
//
// 3) Main UVM phases in order?
//    → build → connect → end_of_elaboration → start_of_simulation → run
//      → extract → check → report → final
//
// 4) What is a TLM analysis port and why is it used instead of direct calls?
//    → A 1-to-many broadcast port. The monitor calls ap.write(tr) once and
//      ALL connected subscribers (scoreboard, coverage, checker) receive it.
//      Decouples the monitor from its consumers.
//
// 5) Active vs passive agent?
//    → Active = builds driver + sequencer + monitor (drives stimulus).
//      Passive = builds monitor only (observes external stimulus).
//      Switch via UVM_ACTIVE / UVM_PASSIVE in the agent's get_is_active().
//
// 6) What does uvm_config_db do?
//    → Globally accessible key/value store keyed by hierarchical path.
//      Used to pass virtual interfaces (top → all components), config
//      objects (test → env → agents), and tunable knobs without explicit
//      handles.

// ============================================================================
// END OF CHEATSHEET
// ============================================================================
