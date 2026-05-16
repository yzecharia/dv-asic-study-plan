# UVM Test (`uvm_test`)

**Category**: UVM · **Used in**: W4 (anchor), W5 ch.18 (`random_test.svh` + `add_test.svh`), W7, W12, W14, W20 · **Type**: authored

The test is the **top-level container**. It picks the env, sets up
factory overrides for *this run only*, configures sequences, and
controls the run via objections. Everything below it (env, agent,
driver) is reusable; the test is where per-run intent lives. A
clean env can be reused unchanged across dozens of tests — only the
test class changes from one run to the next.

This note covers HW2's `random_test.svh` and `add_test.svh` — a
two-class test hierarchy where the base test builds the env and the
derived test adds a single factory `set_type_override`.

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

## Two architectural styles for the test hierarchy

The `uvm_test` class is the same in both styles. The split is **what
the derived test changes** — a factory *type* override on a
component, or a *sequence* selection.

### Style A — Salemi ch.18: base test builds env, derived test factory-overrides a component

HW2's `random_test.svh` and `add_test.svh` are this exact pattern.
The base test does the env wiring once. The derived test calls
`super.build_phase()` to inherit that wiring, then adds **one
factory `set_type_override`** that swaps a concrete tester
component.

```systemverilog
class random_test extends uvm_test;            // the base — builds the env
    `uvm_component_utils(random_test)
    env env_h;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env_h = env::type_id::create("env_h", this);
    endfunction
endclass

class add_test extends random_test;            // derived — one override, nothing else
    `uvm_component_utils(add_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        random_tester::type_id::set_type_override(add_tester::get_type());
        super.build_phase(phase);              // override set BEFORE env builds
    endfunction
endclass
```

The ordering is the load-bearing detail: `add_test` registers the
override **before** `super.build_phase()` runs. The env's
`build_phase` then calls `random_tester::type_id::create(...)`, the
factory consults the override table, and an `add_tester` is
constructed in its place. Register the override *after*
`super.build_phase()` and the env has already built a plain
`random_tester` — the override is a dead letter. See
`[[uvm_factory_config_db]]` and `[[uvm_tester_component]]`.

Note also that `random_test` itself has **no `run_phase`**. The
stimulus generation lives in the tester component's `run_phase`, and
the *tester* raises the objection — see `[[uvm_run_workflow]]`. The
test is purely structural here: build the env, set overrides, done.

### Style B — Industry: base test builds env, derived test starts a different sequence

In a production env the derived test does **not** factory-override a
*component*. It runs a different **sequence** on the agent's
sequencer. The component topology is fixed by the env; only the
stimulus changes.

```systemverilog
class alu_base_test extends uvm_test;
    `uvm_component_utils(alu_base_test)
    alu_env env;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
    endfunction
endclass

class alu_add_test extends alu_base_test;      // derived — picks a sequence
    `uvm_component_utils(alu_add_test)

    task run_phase(uvm_phase phase);
        add_only_seq seq = add_only_seq::type_id::create("seq");
        phase.raise_objection(this, "add_only_seq");
        seq.start(env.agent.sequencer);        // run THIS sequence
        phase.drop_objection(this, "done");
    endtask
endclass
```

Two structural differences from Style A: the *test* owns the
objection (there is no self-objecting tester), and the derived test
overrides `run_phase` (sequence selection) rather than `build_phase`
(component override). Factory `set_type_override` is still used in
production tests — but typically to swap a *sequence item* type
(e.g. inject errors) or a *config* object, not a stimulus-generating
component.

### Why Salemi uses Style A
- **No sequencer yet.** Ch.18 predates sequences (ch.23). With no
  sequencer, the only way to vary stimulus per test is to swap the
  tester *component* via the factory.
- **It teaches the factory override cleanly.** `add_test` is four
  lines: the whole lesson is "register an override, then call
  `super.build_phase`." Nothing else competes for attention.
- **`add_test extends random_test` reuses env wiring.** The derived
  test inherits the base's `env_h` construction for free — the
  textbook DRY payoff of test inheritance.

### Why industry uses Style B
- **Sequences are the unit of stimulus variation.** A production env
  has one fixed topology; tests differ by *what sequence runs*, not
  *what components exist*. Swapping components per test would mean
  the env is not really reusable.
- **The test owns the objection in production.** Without a
  self-objecting tester, `raise`/`drop_objection` around
  `seq.start()` is the run-control contract — see
  `[[uvm_run_workflow]]`.
- **Component overrides are for structure, not stimulus.** Factory
  `set_type_override` in production swaps a config object, a
  sequence-item subtype for error injection, or a model variant —
  structural concerns, not "which operations to send."

### When to use which

| Context | Style |
|---|---|
| Salemi ch.18 homework (HW2 `random_test`/`add_test`) | A — component override, match the book |
| W6 first sequence-based test | **B** — derived test starts a sequence |
| W11 SPI/AXI-Lite, W12+ portfolio | **B, always** |
| Error-injection / config variants | factory override of a *sequence item* or *config*, not a tester |

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
- Salemi ch.18 (Put and Get Ports in Action — `random_test` builds
  the env, `add_test` factory-overrides the tester), pp. 123–129.
- Rosenberg & Meade ch.4 — test-vs-env separation.
- IEEE 1800.2-2020 §F — `uvm_test` class reference.

## Cross-links

- `[[uvm_phases]]` · `[[uvm_factory_config_db]]` · `[[uvm_env]]`
- `[[uvm_sequences_sequencers]]` · `[[uvm_testbench_skeleton]]`
- `[[uvm_tester_component]]` — the component the ch.18 `add_test`
  factory-overrides.
- `[[uvm_run_workflow]]` — why the ch.18 test owns no objection.
