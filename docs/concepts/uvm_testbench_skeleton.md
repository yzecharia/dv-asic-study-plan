# UVM Testbench Skeleton — Generic Reference

**Category**: UVM · **Used in**: every UVM week (W4–W7, W12, W14, W20) · **Type**: authored

This is the master cheat-sheet. When you're starting a new UVM
testbench and the page is blank, scroll here. Every UVC in this
curriculum follows the same shape — what changes between projects
is the *transaction type*, the *interface signals*, and the
*reference model*. The skeleton itself is identical.

## The full hierarchy

```
                     module top                ← non-UVM, holds DUT + clocking + run_test()
                        │
                        ├── DUT instance
                        ├── interface vif      ← uvm_config_db::set( vif )
                        └── initial run_test();
                                │ (factory + +UVM_TESTNAME)
                                ▼
                          uvm_test             ← per-run intent: overrides, sequence selection
                                │
                                ▼
                          uvm_env              ← reusable container; instantiates agents + analysis chain
                                │
            ┌──────────────────┬┴────────┬─────────────────────────┐
            ▼                  ▼         ▼                         ▼
        uvm_agent          uvm_agent  uvm_scoreboard       uvm_subscriber#(txn)  (coverage)
            │                                ▲                     ▲
            │ (active)                       │                     │
            ├── uvm_sequencer                │                     │
            ├── uvm_driver  ─ vif ──→ DUT    │                     │
            └── uvm_monitor ─ vif ──→ analysis_port ───────────────┴─────────────┘
```

## Build/run order — what runs when

| Time | Phase | Direction | Who does what |
|---|---|---|---|
| t<0 | `build_phase` | top-down | test creates env; env creates agents; agent creates driver/monitor/sequencer |
| t<0 | `connect_phase` | bottom-up | `monitor.ap → scoreboard.imp` ; `driver.seq_item_port → sequencer.seq_item_export` |
| t<0 | `end_of_elaboration_phase` | bottom-up | print topology, sanity-check connections |
| t<0 | `start_of_simulation_phase` | bottom-up | last function call before time advances |
| t≥0 | `run_phase` | parallel (task) | test starts sequence; driver pulls items; monitor samples; scoreboard checks |
| t=∞ | `extract_phase → check_phase → report_phase → final_phase` | bottom-up | post-sim checks and summary |

## Where does each thing live?

| Thing | Who owns it | Created in |
|---|---|---|
| DUT instance | `top` module | RTL elaboration |
| `virtual <if>` handle | passed via `uvm_config_db` | `top.initial` (set), `agent.build_phase` (get) |
| Sequence | `uvm_sequence` factory-registered class | started in `test.run_phase`, runs on agent's sequencer |
| Reference model | usually inside scoreboard | `scoreboard.write()` or a separate predictor child |
| Coverage groups | `uvm_subscriber` (or scoreboard) | sampled in `write()` |

## File layout convention (mirrors Salemi tinyalu)

```
uvm/
├── <name>_pkg.sv           ← package wrapping every class with `import uvm_pkg::*;`
├── <name>_if.sv            ← interface (modports for driver / monitor)
├── <name>_seq_item.sv      ← uvm_sequence_item (transaction)
├── <name>_seq.sv           ← uvm_sequence subclasses
├── <name>_driver.sv        ← uvm_driver
├── <name>_monitor.sv       ← uvm_monitor
├── <name>_agent.sv         ← uvm_agent (wraps drv/mon/seqr)
├── <name>_scoreboard.sv    ← uvm_scoreboard
├── <name>_coverage.sv      ← uvm_subscriber#(txn)
├── <name>_env.sv           ← uvm_env
├── <name>_test.sv          ← uvm_test (and child tests)
└── top.sv                  ← module top: DUT + interface + run_test()
```

## The seven non-negotiable boilerplate lines per class

Every component class has these seven lines. Burn them into muscle
memory:

```systemverilog
class my_<role> extends uvm_<role>;             // 1. extend the right base class
    `uvm_component_utils(my_<role>)              // 2. factory register
                                                 //    (use `uvm_object_utils for transactions)

    function new(string name, uvm_component parent = null);  // 3. constructor signature
        super.new(name, parent);                 // 4. always call super
    endfunction

    function void build_phase(uvm_phase phase);  // 5. build_phase signature
        super.build_phase(phase);                // 6. always call super
        // create children, fetch config_db
    endfunction
                                                 // 7. close with `endclass`
endclass
```

Skipping (4) or (6) breaks UVM silently — most subtle bug class
juniors hit in their first month.

## Salemi ch.13 style vs production style

| Aspect | Salemi ch.13 ("tester") | Production (ch.22+) |
|---|---|---|
| Driver class | `extends uvm_component` "tester" | `extends uvm_driver#(T)` |
| Stimulus | `randomize()` inside tester `run_phase` | sequence on a sequencer |
| Sequencer | none | `uvm_sequencer#(T)` |
| Use when | learning UVM, single-test bring-up | every real env |

W4 HW2 uses the Salemi ch.13 style; W6 onwards uses production.

## Reading

- Salemi *UVM Primer* ch.11–16, pp. 67–114 (test → env → analysis ports).
- Salemi ch.21–23, pp. 143–179 (transactions, agents, sequences — production shape).
- Rosenberg & Meade *Practical Guide to Adopting the UVM* ch.4–6.
- IEEE 1800.2-2020 §F (class reference for every component).
- Verification Academy UVM Cookbook (free): https://verificationacademy.com/cookbook/uvm

## Cross-links

- `[[uvm_test]]` · `[[uvm_env]]` · `[[uvm_agent]]` · `[[uvm_driver]]`
  · `[[uvm_monitor]]` · `[[uvm_scoreboard]]` · `[[uvm_subscriber_coverage]]`
  · `[[uvm_sequence_item]]` · `[[uvm_sequences_sequencers]]`
  · `[[uvm_phases]]` · `[[uvm_factory_config_db]]`
