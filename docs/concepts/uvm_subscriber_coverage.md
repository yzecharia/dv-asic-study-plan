# UVM Subscriber & Coverage Collector

**Category**: UVM · **Used in**: W3 (anchor for cov), W7+, W12, W14, W20 · **Type**: authored

A `uvm_subscriber#(T)` is the standard endpoint for an analysis
port. Its single job is to receive transactions via `write()` and
sample a covergroup. Keeping coverage in its own component (rather
than inside the scoreboard) preserves a clean separation:
**scoreboard == verdict, subscriber == metrics.** This split also
makes coverage swappable per-test via factory override.

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

## Reading

- Salemi *UVM Primer* ch.16 (Analysis Ports), pp. 106–114.
- IEEE 1800-2017 §19 (covergroup syntax — base SystemVerilog).
- Verification Academy UVM Cookbook — coverage chapter:
  https://verificationacademy.com/cookbook/coverage

## Cross-links

- `[[coverage_functional_vs_code]]` · `[[uvm_monitor]]` · `[[uvm_scoreboard]]`
  · `[[sva_assertions]]` · `[[uvm_testbench_skeleton]]`
