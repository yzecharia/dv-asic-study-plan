# UVM Test (`uvm_test`)

**Category**: UVM · **Used in**: W4 (anchor), W7, W12, W14, W20 · **Type**: authored

The test is the **top-level container**. It picks the env, sets up
factory overrides for *this run only*, configures sequences, and
controls the run via objections. Everything below it (env, agent,
driver) is reusable; the test is where per-run intent lives. A
clean env can be reused unchanged across dozens of tests — only the
test class changes from one run to the next.

## Position in the hierarchy

```
   module top
       │ run_test()
       ▼
   uvm_test  ← THIS
       │ build_phase: create env, set overrides
       ▼
   uvm_env
       │
      ...
```

## Mandatory skeleton

```systemverilog
class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    my_env env;

    function new(string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Per-test factory overrides go HERE (before env is created):
        // base_seq_item::type_id::set_type_override(error_seq_item::get_type());

        // config_db sets that the env needs:
        // uvm_config_db#(int)::set(this, "env.*", "num_txns", 1000);

        env = my_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        my_seq seq = my_seq::type_id::create("seq");
        phase.raise_objection(this, "starting seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this, "seq done");
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        // emit one greppable PASS/FAIL line for the Iron-Rule log
        if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) == 0)
            `uvm_info("RESULT", "TEST PASSED", UVM_LOW)
        else
            `uvm_info("RESULT", "TEST FAILED", UVM_LOW)
    endfunction
endclass
```

## Required overrides

| Phase | Function/task | What you put here |
|---|---|---|
| `new()` | constructor | call `super.new(name, parent)` — never anything else |
| `build_phase` | function | factory overrides, config_db sets, env creation |
| `run_phase` | task | raise objection → start sequence → drop objection |
| `report_phase` | function | emit one greppable "TEST PASSED/FAILED" line |

## Launching the test from the top module

```systemverilog
module top;
    initial begin
        run_test();   // reads +UVM_TESTNAME=my_test from cmdline
    end
endmodule
```

`run_test()` uses the factory + the cmd-line string to instantiate
the test class. **Never `new` the test directly** — the factory
override path becomes useless.

## Test inheritance pattern

A typical env has a `base_test` that does the env wiring once, and
N child tests that just change overrides or pick a different
sequence:

```systemverilog
class base_test extends uvm_test;
    my_env env;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = my_env::type_id::create("env", this);
    endfunction
endclass

class read_only_test extends base_test;
    `uvm_component_utils(read_only_test)
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);    // env still gets created
        my_seq_item::type_id::set_type_override(read_only_item::get_type());
    endfunction
endclass
```

This is the W4 ch.13-drill pattern (abstract base_tester + factory
override) scaled up.

## Common gotchas

- **Forgetting `super.build_phase(phase)`** silently breaks
  config_db propagation. Always call it.
- **`new my_env(...)`** instead of factory `create` — kills every
  override the factory provides.
- **Never raising objection** → `run_phase` exits at time 0 → the
  test silently "passes" with zero stimulus. The Iron-Rule PASS log
  becomes a lie.

## Reading

- Salemi *UVM Primer* ch.11 (UVM Tests), pp. 67–75.
- Salemi ch.13 (UVM Environments — abstract base_tester pattern), pp. 82–92.
- Rosenberg & Meade ch.4 — test-vs-env separation.
- IEEE 1800.2-2020 §F — `uvm_test` class reference.

## Cross-links

- `[[uvm_phases]]` · `[[uvm_factory_config_db]]` · `[[uvm_env]]`
- `[[uvm_sequences_sequencers]]` · `[[uvm_testbench_skeleton]]`
