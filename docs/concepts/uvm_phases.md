# UVM Phases

**Category**: UVM · **Used in**: W4, W12, W14, W20 · **Type**: authored

UVM testbenches run through a fixed sequence of **phases**. Each
component overrides one or more phases; the framework calls them in
deterministic order across the entire env hierarchy. Knowing the
order is interview-table-stakes.

## The build-time phases (top-down, function calls)

| Phase | Purpose | Called bottom-up or top-down? |
|---|---|---|
| `build_phase` | Construct child components, fetch config from db | **top-down** |
| `connect_phase` | Connect TLM ports, wire scoreboard analysis fifos | bottom-up |
| `end_of_elaboration_phase` | Final tweaks before sim starts | bottom-up |

Top-down for `build_phase` matters: a parent must build its children,
which means the parent's `build_phase` runs first, then each child's.

## The run-time phase (bottom-up, tasks — fork-and-join)

| Phase | Notes |
|---|---|
| `start_of_simulation_phase` | last function before time advances |
| `run_phase` | the actual simulation runs here; `forever` allowed |
| `extract_phase` | (function) collect coverage / data |
| `check_phase` | (function) post-sim assertions |
| `report_phase` | (function) emit summary |
| `final_phase` | (function) cleanup |

Most components do their actual work in `run_phase` (driver loops on
the sequencer, monitor samples the bus, scoreboard compares).

## Objection mechanism

`run_phase` is a task; UVM keeps it alive as long as some component
has raised an objection. Tests typically:

```systemverilog
task my_test::run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // ... drive sequences ...
    phase.drop_objection(this);
endtask
```

Forgetting to raise the objection → the test exits at time 0.
Forgetting to drop it → the test runs forever. Both are common
junior bugs.

## Reading

- Salemi *UVM Primer* ch.12 (components and phases), pp. 95–110
  approx (verify).
- IEEE 1800.2-2020 §5.2.

## Cross-links

- `[[uvm_factory_config_db]]` — `build_phase` is where you fetch
  config and override types.
- `[[uvm_sequences_sequencers]]` — sequences run inside `run_phase`.
