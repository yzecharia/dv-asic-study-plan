# UVM Environment (`uvm_env`)

**Category**: UVM · **Used in**: W4 (anchor), W5 ch.18 (`env.svh`), W7, W12, W14, W20 · **Type**: authored

The env is the **reusable container**. Tests come and go; the env
stays. It instantiates agents, the scoreboard, and the coverage
collector, and wires the analysis chain in `connect_phase`. An env
should know nothing about *which* test is running it — that's the
test's job. If you find yourself adding test-specific behaviour
inside the env, you've broken the reuse contract.

This note covers HW2's `env.svh` — an env that owns all six
TinyALU components **plus a `uvm_tlm_fifo #(command_t)`** for the
tester→driver stimulus path, and wires both the stimulus fifo and
the analysis chain in `connect_phase`.

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

## Two architectural styles for the env

The `uvm_env` class is identical in both styles. The split is **what
the env contains** and **how the stimulus path is wired**.

### Style A — Salemi ch.18: env owns loose components + a stimulus `uvm_tlm_fifo`

HW2's `env.svh` is a *flat* env. There is no agent: the env directly
owns the tester, the driver, both monitors, the scoreboard, the
coverage collector — **and a `uvm_tlm_fifo #(command_t)`** that
carries commands from the tester to the driver. The fifo is a
`uvm_component`, so it is constructed in `build_phase` like any
child, and wired in `connect_phase`.

```systemverilog
class env extends uvm_env;
    `uvm_component_utils(env)

    random_tester             random_tester_h;   // stimulus generator
    driver                    driver_h;          // stimulus applier
    uvm_tlm_fifo #(command_t) command_f;          // ← stimulus-path channel
    coverage                  coverage_h;
    scoreboard                scoreboard_h;
    command_monitor           command_monitor_h;
    result_monitor            result_monitor_h;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        command_f         = new("command_f", this);                       // fifo: new()
        random_tester_h   = random_tester::type_id::create("random_tester_h", this);
        driver_h          = driver        ::type_id::create("driver_h",        this);
        coverage_h        = coverage      ::type_id::create("coverage_h",       this);
        scoreboard_h      = scoreboard    ::type_id::create("scoreboard_h",     this);
        command_monitor_h = command_monitor::type_id::create("command_monitor_h", this);
        result_monitor_h  = result_monitor ::type_id::create("result_monitor_h",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // --- STIMULUS PATH: tester --put--> fifo --get--> driver ---
        random_tester_h.command_port.connect(command_f.put_export);   // put port → put_export
        driver_h.command_port.connect(command_f.get_export);          // get port → get_export

        // --- ANALYSIS PATH: monitors broadcast to scoreboard + coverage ---
        result_monitor_h.ap.connect(scoreboard_h.analysis_export);          // result stream
        command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);   // cmd → SB's fifo
        command_monitor_h.ap.connect(coverage_h.analysis_export);           // cmd → coverage
    endfunction
endclass
```

The env's `connect_phase` is doing **two distinct kinds of wiring**:

1. **The stimulus path** — a `uvm_tlm_fifo` joining a `uvm_put_port`
   (on the tester) to a `uvm_get_port` (on the driver). This is
   *interthread* communication; `put`/`get` block. Note the rule
   **"ports connect to exports"** — the tester's put port connects to
   the fifo's `put_export`, the driver's get port to `get_export`.
   See `[[uvm_put_get_tlm_fifo]]`.
2. **The analysis path** — `uvm_analysis_port`s from the two monitors
   fanning out to the scoreboard and coverage. This is *intrathread*
   broadcast; `write()` is a synchronous call. Note the asymmetry:
   the result stream connects to the scoreboard's own
   `analysis_export`, but the command stream connects to the
   scoreboard's internal `cmd_f.analysis_export` (a
   `uvm_tlm_analysis_fifo`) — see `[[uvm_tlm_analysis_fifo]]`.

Mixing both wiring kinds in one `connect_phase` is exactly what ch.18
asks you to do. The `uvm_tlm_fifo` for *stimulus* and the
`uvm_tlm_analysis_fifo` inside the scoreboard for *analysis* are
different classes solving different problems — don't conflate them.

### Style B — Industry: env owns *agents*, not loose components

A production env does **not** instantiate drivers, monitors, and
sequencers directly. It instantiates **agents** — each agent
encapsulates one protocol's driver + monitor + sequencer behind one
handle (see `[[uvm_agent]]`). The env then owns agents, the
scoreboard, the coverage collector, and (for multi-protocol DUTs) a
virtual sequencer.

```systemverilog
class alu_env extends uvm_env;
    `uvm_component_utils(alu_env)
    alu_agent      agent;        // driver + monitor + sequencer inside
    alu_scoreboard sb;
    alu_coverage   cov;

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(sb.cmd_export);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction
endclass
```

There is **no stimulus `uvm_tlm_fifo` in the env** — the
sequencer↔driver handshake (`seq_item_port`) lives *inside* the
agent and is wired by the agent's own `connect_phase`. The env only
wires the *analysis* path. That is the structural payoff of agents:
the env shrinks to "agents + analysis wiring."

### Why Salemi uses Style A
- **Agents arrive later (ch.22).** Ch.18 cannot use an agent because
  the reader hasn't met one. The flat env makes every connection
  visible in one place.
- **It shows the wiring honestly.** Putting the stimulus fifo and the
  analysis ports side by side in one `connect_phase` is the whole
  point of the chapter — you *see* interthread vs intrathread.
- **TinyALU is single-protocol.** With one interface there is nothing
  for an agent to encapsulate yet; the flat env is not wrong, just
  un-scaled.

### Why industry uses Style B
- **Agents are the reuse unit.** A UART agent drops into any env that
  has a UART. A flat env hard-codes its components and cannot be
  reused across projects.
- **The stimulus path is the agent's business.** Sequencer↔driver
  wiring belongs inside the agent, not exposed in the env. Style A's
  env-level stimulus fifo leaks an internal detail upward.
- **Multi-protocol DUTs need multiple agents.** Real SoCs have AXI +
  UART + SPI; the env owns one agent each plus a virtual sequencer.
  A flat env with loose components does not compose.

### When to use which

| Context | Style |
|---|---|
| Salemi ch.18 homework (HW2 `env.svh`) | A — flat env, stimulus `uvm_tlm_fifo`, match the book |
| W6 first agent-based env | **B** — env owns an agent |
| W11 SPI/AXI-Lite, W12+ portfolio | **B, always** |
| W14 / W20 multi-UVC capstone | **B** — multiple agents + virtual sequencer (below) |

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
- Salemi ch.18 (Put and Get Ports in Action — the env owning a
  stimulus `uvm_tlm_fifo`, Figure 126), pp. 123–129.
- Rosenberg & Meade ch.5 — env composition patterns.
- IEEE 1800.2-2020 §F.5 — `uvm_env` class.

## Cross-links

- `[[uvm_test]]` · `[[uvm_agent]]` · `[[uvm_scoreboard]]`
  · `[[uvm_subscriber_coverage]]` · `[[uvm_phases]]`
  · `[[uvm_testbench_skeleton]]`
- `[[uvm_put_get_tlm_fifo]]` — the stimulus-path `uvm_tlm_fifo` the
  ch.18 env owns and wires.
- `[[uvm_tlm_analysis_fifo]]` — the analysis-path fifo *inside* the
  scoreboard; not the same class.
- `[[uvm_tester_component]]` · `[[uvm_driver]]` — the two ends of the
  stimulus fifo the env joins.
- `[[uvm_analysis_ports]]` — the analysis-path wiring.
