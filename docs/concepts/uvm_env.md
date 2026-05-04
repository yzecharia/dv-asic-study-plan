# UVM Environment (`uvm_env`)

**Category**: UVM · **Used in**: W4 (anchor), W7, W12, W14, W20 · **Type**: authored

The env is the **reusable container**. Tests come and go; the env
stays. It instantiates agents, the scoreboard, and the coverage
collector, and wires the analysis chain in `connect_phase`. An env
should know nothing about *which* test is running it — that's the
test's job. If you find yourself adding test-specific behaviour
inside the env, you've broken the reuse contract.

## Position in the hierarchy

```
   uvm_test
       │ build_phase
       ▼
   uvm_env  ← THIS
    ┌──┼──┬───────────┐
    ▼  ▼  ▼           ▼
  agent agent scoreboard coverage
```

## Mandatory skeleton

```systemverilog
class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_agent       agent;
    my_scoreboard  sb;
    my_coverage    cov;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = my_agent     ::type_id::create("agent", this);
        sb    = my_scoreboard::type_id::create("sb",    this);
        cov   = my_coverage  ::type_id::create("cov",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(sb.actual_imp);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction
endclass
```

## What goes where

| Override | Purpose |
|---|---|
| `new()` | super only |
| `build_phase` | factory `create` every child component |
| `connect_phase` | hook every monitor `ap` to scoreboard / coverage |
| `end_of_elaboration_phase` (rare) | print topology with `uvm_top.print_topology()` for debug |
| no `run_phase` | env is structural, not behavioural |

## Why no `run_phase`

A clean env has no behaviour of its own — it's a wiring diagram.
If you find yourself adding logic to `env::run_phase`, you're
probably building something that belongs in a scoreboard, a
predictor child component, or a virtual sequence instead.

## Multi-UVC envs (W14 / W20 capstone shape)

Larger envs hold multiple agents (e.g. AXI-Lite + UART). They also
hold a **virtual sequencer** with handles to each per-agent
sequencer, so virtual sequences can drive across all of them in
lockstep.

```systemverilog
class soc_env extends uvm_env;
    `uvm_component_utils(soc_env)
    axi_agent       axi;
    uart_agent      uart;
    virtual_seqr    vseqr;
    soc_scoreboard  sb;

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vseqr.axi_seqr  = axi.sequencer;
        vseqr.uart_seqr = uart.sequencer;
        axi.monitor.ap.connect(sb.axi_imp);
        uart.monitor.ap.connect(sb.uart_imp);
    endfunction
endclass
```

## Common gotchas

- **Sub-component handles declared but not created** — null pointer
  in `connect_phase`. Always `create()` in `build_phase` first.
- **Skipping `super.connect_phase(phase)`** — usually harmless
  today but breaks future UVM versions / mixin patterns. Call it.
- **Putting analysis-port wiring in `build_phase`** — the children
  haven't been built yet, so `agent.monitor.ap` is null. Wire in
  `connect_phase`.

## Reading

- Salemi *UVM Primer* ch.13 (UVM Environments), pp. 82–92.
- Salemi ch.16 (Analysis Ports in a Testbench — env-level wiring),
  pp. 106–114.
- Rosenberg & Meade ch.5 — env composition patterns.
- IEEE 1800.2-2020 §F.5 — `uvm_env` class.

## Cross-links

- `[[uvm_test]]` · `[[uvm_agent]]` · `[[uvm_scoreboard]]`
  · `[[uvm_subscriber_coverage]]` · `[[uvm_phases]]`
  · `[[uvm_testbench_skeleton]]`
