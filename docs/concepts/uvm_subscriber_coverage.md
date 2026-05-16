# UVM Subscriber & Coverage Collector

**Category**: UVM · **Used in**: W3 (anchor for cov), W5 ch.18 (`coverage.svh`), W7+, W12, W14, W20 · **Type**: authored

A `uvm_subscriber#(T)` is the standard endpoint for an analysis
port. Its single job is to receive transactions via `write()` and
sample a covergroup. Keeping coverage in its own component (rather
than inside the scoreboard) preserves a clean separation:
**scoreboard == verdict, subscriber == metrics.** This split also
makes coverage swappable per-test via factory override.

This note covers HW2's `coverage.svh` — a `uvm_subscriber #(command_t)`
that owns the TinyALU functional-coverage covergroups and samples
them in `write()`.

## Position

```
   Monitor.ap ──analysis_port──┐
                               │
                               ├──→ uvm_scoreboard.write()
                               │
                               └──→ uvm_subscriber#(T).write()  ← THIS
                                          │
                                          └─ cg.sample()
```

## Mandatory skeleton

```systemverilog
class my_coverage extends uvm_subscriber #(my_seq_item);
    `uvm_component_utils(my_coverage)

    my_seq_item txn;

    covergroup cg;
        cp_kind: coverpoint txn.kind {
            bins read  = {READ};
            bins write = {WRITE};
        }
        cp_addr: coverpoint txn.addr {
            bins low  = {[0:255]};
            bins high = {[256:'hFFFF]};
        }
        cross_kind_addr: cross cp_kind, cp_addr;
    endgroup

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        cg = new();                        // covergroup is an object — must construct
    endfunction

    function void write(my_seq_item t);    // called when monitor.ap.write() fires
        txn = t;
        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV",
            $sformatf("functional coverage = %0.2f%%", cg.get_coverage()),
            UVM_LOW)
    endfunction
endclass
```

## What goes where

| Override | Purpose |
|---|---|
| `new()` | super + `cg = new()` (covergroup is an object, must be constructed) |
| `write(T t)` | mandatory — only API to a subscriber. Sample the covergroup here. |
| `report_phase` | print coverage % so it lands in PASS log |
| no `build_phase` | unless config_db tweaks needed (rare) |

## Why subscriber, not just `uvm_component`

`uvm_subscriber#(T)` already declares the `analysis_export` and
forces you to implement `write(T t)` — saves you the boilerplate
and prevents "I forgot to wire it" bugs. Plain components would
need explicit `uvm_analysis_imp_decl` macros.

## Coverage closure workflow

1. Write covergroup with bins that map to spec features.
2. Run randomised tests; check `cg.get_coverage()` in `report_phase`.
3. Holes → add **directed sequences** that hit the missing bins.
4. Re-run; iterate until 100% on the bins you care about.

The point of step 3 is that constrained-random alone almost never
closes the last 5–10% — directed help is part of the methodology,
not a smell.

## Common gotchas

- **Forgetting `cg = new()`** — covergroup is null, every sample
  is a silent no-op, your coverage report says 0% and you don't
  notice until the manager asks.
- **Sampling on a stale `txn`** — must assign `txn = t` *before*
  `cg.sample()`. Covergroups close over the variable, not the
  parameter.
- **Putting coverage in the scoreboard** — works for tiny envs
  (and Salemi does it), but couples metrics with verdict and
  blocks per-test override. Bad in larger envs.

## Sampling on an event vs in `write()`

| Mode | When |
|---|---|
| `covergroup cg @(posedge clk);` | sample tied to a clock — for protocol coverage |
| `cg.sample()` inside `write()` | sample per transaction — most common |

Salemi uses the per-transaction mode because the analysis port
fires once per protocol-meaningful event already.

## Two architectural styles for the coverage collector

The `uvm_subscriber #(T)` *class* is the same in both styles. The
split is **how the covergroup is fed** and **how much the collector
knows about coverage closure**.

### Style A — Salemi ch.16/18: subscriber owns the covergroups, samples in `write()`

This is HW2's `coverage.svh` verbatim. The collector extends
`uvm_subscriber #(command_t)`, declares its covergroups as class
fields, constructs them in `new()`, and samples them inside the
inherited `write()` callback. The covergroups close over the class's
*member variables*, so `write()` must copy the transaction's fields
into those members **before** calling `sample()`.

```systemverilog
class coverage extends uvm_subscriber #(command_t);
    `uvm_component_utils(coverage)

    byte unsigned A, B;                       // covergroup samples these members
    operation_t   op_set;

    covergroup op_cov;
        coverpoint op_set { /* bins ... */ }
    endgroup

    covergroup zeros_or_ones_on_ops;
        all_ops : coverpoint op_set;
        a_leg   : coverpoint A;
        b_leg   : coverpoint B;
        op_00_FF: cross a_leg, b_leg, all_ops;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        op_cov               = new();         // covergroups are objects — construct
        zeros_or_ones_on_ops = new();
    endfunction

    function void write(command_t t);
        A = t.A;  B = t.B;  op_set = t.op;     // copy INTO members first
        op_cov.sample();
        zeros_or_ones_on_ops.sample();
    endfunction
endclass
```

Salemi's design keeps coverage as pure conduit code — it touches no
signals, no clocks, no verdict. The covergroup definition *is* the
coverage model; the component is a thin shell around it.

### Style B — Industry: shared transaction handle, `sample(t)` argument, embedded model

Production coverage collectors generalise three things:

- **Pass the transaction as a `sample()` argument** rather than
  copying into stale members. SystemVerilog covergroups accept formal
  arguments: `covergroup cg with function sample(command_t t);` then
  `coverpoint t.op;`. This removes the copy-then-sample race entirely.
- **A covergroup-per-mode**, gated by config. A real block has
  dozens of coverpoints; tests enable subsets via `uvm_config_db`
  rather than always sampling everything.
- **The collector is factory-overridable per test.** Because it is
  its own component (not folded into the scoreboard), a test can
  `set_type_override` it for a directed-coverage variant — see
  `[[uvm_factory_config_db]]`.

Production teams also wrap `get_coverage()` reporting in
`report_phase` / `check_phase` so the number lands in the regression
log, and feed coverage holes back into directed sequences (the
closure workflow above).

### Why Salemi uses Style A
- **One concept at a time.** Ch.16 introduces the subscriber as "the
  simplest analysis-port endpoint." Covergroup `sample()` arguments,
  config-gated bins, and factory overrides would bury that.
- **The covergroup is the lesson.** Salemi's `op_cov` /
  `zeros_or_ones_on_ops` are rich (transition bins, crosses) — the
  *component* is deliberately trivial so attention stays on the
  coverage model.
- **No build-time config.** The TinyALU coverage model is fixed, so
  there is nothing to gate. Member-copy + `sample()` is the shortest
  correct code.

### Why industry uses Style B
- **`sample(t)` argument kills a real bug class.** Member-copy
  coverage silently samples stale data if you forget the copy or
  reorder it. A `sample(command_t t)` argument makes the data flow
  explicit and un-forgettable.
- **Coverage models are large and modal.** Hundreds of bins across
  many modes; tests need to enable subsets. Config-gated covergroups
  scale; one always-on covergroup does not.
- **Per-test override.** Directed-coverage runs want a different
  collector. A standalone, factory-registered component allows that;
  coverage folded into the scoreboard does not.

### When to use which

| Context | Style |
|---|---|
| Salemi ch.16/18 homework (HW2 `coverage.svh`) | A — match the book |
| W3 coverage drills | A is fine — the model is small |
| W11 SPI/AXI-Lite, W12+ portfolio | **B** — `sample(t)` argument, config-gated bins |
| Any production / NVIDIA-tier env | **B** — and never fold coverage into the scoreboard |

## Reading

- Salemi *UVM Primer* ch.16 (Analysis Ports — the coverage class as
  a subscriber, Figure 109), pp. 106–114.
- Salemi *UVM Primer* ch.18 (Put and Get Ports in Action — the same
  `coverage` subscriber, unchanged by the tester/driver split),
  pp. 123–129.
- IEEE 1800-2017 §19 (covergroup syntax — base SystemVerilog,
  including `with function sample(...)`).
- Verification Academy UVM Cookbook — coverage chapter:
  https://verificationacademy.com/cookbook/coverage

## Cross-links

- `[[coverage_functional_vs_code]]` · `[[uvm_monitor]]` · `[[uvm_scoreboard]]`
  · `[[sva_assertions]]` · `[[uvm_testbench_skeleton]]`
- `[[uvm_analysis_ports]]` — the publisher whose `ap` feeds this
  subscriber's `analysis_export`.
- `[[uvm_factory_config_db]]` — per-test override of the collector.
