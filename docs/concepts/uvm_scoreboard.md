# UVM Scoreboard

**Category**: UVM · **Used in**: W5 ch.18 (`scoreboard.svh`), W7, W12, W13, W20 · **Type**: authored

The scoreboard is where verdict happens. It receives observed
transactions (from the monitor's analysis port) and compares them
against expected behaviour (from a reference model). On mismatch, it
fails the test.

This note covers HW2's `scoreboard.svh` — a `uvm_subscriber #(result_t)`
that owns a `uvm_tlm_analysis_fifo #(command_t)`, pairs each result
with its command, and runs an inline predictor.

## Architecture pattern

```
Monitor ─analysis_port→ Scoreboard.actual_imp
                          │
Reference model ──────────► Scoreboard.expected_imp (or a SV queue)
                          │
                          ├── compare(actual, expected)
                          ├── log mismatch via `uvm_error`
                          └── update coverage
```

## Three flavours

### 1. In-order with SV queue

Simplest. The reference model produces expected items into a queue;
each observed item pops the head and compares.

```systemverilog
class fifo_scoreboard extends uvm_component;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp#(fifo_seq_item, fifo_scoreboard) actual_imp;
    fifo_seq_item expected_q[$];

    function void write(fifo_seq_item t);
        if (t.kind == FIFO_READ) begin
            if (expected_q.size() == 0) begin
                `uvm_error("SCB", "Read with empty expected queue")
                return;
            end
            fifo_seq_item exp = expected_q.pop_front();
            if (t.data != exp.data)
                `uvm_error("SCB", $sformatf("Mismatch: got %0h, exp %0h", t.data, exp.data))
        end
    endfunction
endclass
```

### 2. Out-of-order with associative array

For protocols where responses can come back out of order (e.g.
multiple outstanding AXI reads with IDs). Key the expected map by
transaction ID; lookup on each observed response.

### 3. Subscriber-with-internal-predictor (Salemi ch.16)

The simplest two-stream pattern when the predictor is small enough to
live *inside* the scoreboard. The scoreboard subscribes to one stream
directly (typically the *result*, the thing whose arrival triggers
the compare) and queues the other stream (the *command*) into a
`uvm_tlm_analysis_fifo`. On every result `write()`, pull the matching
command, run the predictor, compare.

```systemverilog
class scoreboard extends uvm_subscriber #(shortint);     // result stream
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(command_s) cmd_f;             // command stream

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cmd_f = new("cmd_f", this);
    endfunction

    function void write(shortint actual);
        command_s cmd;
        shortint  predicted;

        if (!cmd_f.try_get(cmd))
            `uvm_fatal("SCB", "result without queued command")

        case (cmd.op)                                    // predictor lives here
            add_op: predicted = cmd.A + cmd.B;
            and_op: predicted = cmd.A & cmd.B;
            xor_op: predicted = cmd.A ^ cmd.B;
            mul_op: predicted = cmd.A * cmd.B;
            default: return;                             // skip no_op / rst_op
        endcase

        if (predicted !== actual)
            `uvm_error("SCB",
                $sformatf("MISMATCH op=%s actual=%h predicted=%h",
                          cmd.op.name(), actual, predicted))
    endfunction
endclass
```

Env wires the two streams differently:
```systemverilog
result_monitor_h.ap.connect(scoreboard_h.analysis_export);          // direct
command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);   // through fifo
```

**When to use this flavour:**
- Predictor is small enough to express inline (combinational on operands, one-line per op).
- 1:1 ordering between commands and results — every command produces exactly one result, in arrival order.
- Single-test-class scope — you don't expect to reuse the predictor logic in coverage or other components.

**When to graduate to a separate predictor component (the W7+ pattern):**
- Predictor is stateful or multi-cycle (e.g. a model with internal pipelines, FIFOs, or memory).
- More than just the scoreboard wants the predicted value (e.g. coverage closure on prediction-vs-actual mismatch bins).
- You want to factory-override the predictor independently of the scoreboard.

The graduation move: extract the predictor into its own component that subscribes to the command stream and publishes a *predicted-result* stream on its own `uvm_analysis_port`. Now the scoreboard has two simpler streams (actual + predicted) and just compares them. See `[[uvm_analysis_ports]]` → "predictor / pass-through pattern" for the shape.

## Two architectural styles for the scoreboard

The three flavours above are implementation shapes. The deeper split
— the one a reviewer cares about — is **where the reference model
lives** and **how the scoreboard extends the class tree**.

### Style A — Salemi ch.16/18: `uvm_subscriber` with the predictor inlined

HW2's `scoreboard.svh` is flavour 3 verbatim. The scoreboard
`extends uvm_subscriber #(result_t)` — so the *result* stream is the
primary input and arrives via the inherited `write()`. The *command*
stream is queued into a `uvm_tlm_analysis_fifo #(command_t)` field.
On each result, `write()` pulls the matching command with
`try_get()`, runs a one-line-per-op predictor inline, and compares.

```systemverilog
class scoreboard extends uvm_subscriber #(result_t);    // primary: result
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(command_t) cmd_f;            // secondary: command

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cmd_f = new("cmd_f", this);
    endfunction

    function void write(result_t actual);                // inherited contract
        command_t cmd;
        result_t  predicted;
        do
            if (!cmd_f.try_get(cmd))                      // try_get — write() is a function
                `uvm_fatal("SCB", "result without a queued command")
        while (cmd.op == no_op || cmd.op == rst_op);      // skip non-producing ops
        case (cmd.op)                                     // predictor lives HERE
            add_op: predicted = cmd.A + cmd.B;
            and_op: predicted = cmd.A & cmd.B;
            xor_op: predicted = cmd.A ^ cmd.B;
            mul_op: predicted = cmd.A * cmd.B;
        endcase
        if (predicted !== actual)
            `uvm_error("SCB", $sformatf("MISMATCH op=%s exp=%h act=%h",
                                        cmd.op.name(), predicted, actual))
    endfunction
endclass
```

Salemi's scoreboard is deliberately small: the predictor *is* a
`case` statement, the verdict *is* a `!==` compare, and there is no
separate model component. For a combinational DUT with strict 1:1
command/result ordering, that is the right amount of structure.

### Style B — Industry: standalone predictor + a comparator scoreboard

A production scoreboard splits responsibilities the moment the
reference model stops being one line per op:

- **The reference model becomes its own component.** It subscribes
  to the command stream and publishes a *predicted* stream on its
  own `uvm_analysis_port` (the predictor / pass-through pattern in
  `[[uvm_analysis_ports]]`). Stateful, multi-cycle, memory-backed
  models belong here, not inside `write()`.
- **The scoreboard becomes a pure comparator.** It now takes two
  homogeneous streams — *actual* and *predicted* — and only
  compares. It typically does **not** extend `uvm_subscriber` at
  all; it uses two `uvm_analysis_imp_decl`-generated imps (one per
  stream, each with a name-mangled `write_actual()` /
  `write_predicted()`), or two `uvm_tlm_analysis_fifo`s pulled in a
  `run_phase` task.
- **Ordering is explicit.** In-order DUTs use queues; out-of-order
  protocols (multiple outstanding AXI IDs) key an associative array
  by transaction ID — flavour 2 above. The FIFO-pairing trick only
  holds when the spec guarantees 1-command-then-1-result.
- **The final verdict moves to `check_phase`.** `write()` accumulates
  per-transaction mismatches during `run_phase`; `check_phase` (or
  `report_phase`) asserts the queues are drained and emits one
  greppable PASS/FAIL line. An undrained expected-queue at end of
  test is itself a failure.

### Why Salemi uses Style A
- **The TinyALU model is one line per op.** A combinational ALU has
  no internal state — `cmd.A + cmd.B` is the entire "model." A
  separate predictor component would be ceremony with no payoff.
- **`uvm_subscriber` + one analysis fifo is the smallest correct
  shape.** It teaches "subscribe to the primary stream, queue the
  secondary, pair them" without an extra component to wire.
- **Ordering is trivially 1:1.** The TinyALU produces exactly one
  result per command in arrival order, so a FIFO *is* the correct
  correlation structure.

### Why industry uses Style B
- **Reference models are stateful and large.** A pipelined or
  memory-backed DUT needs a model with its own registers, FIFOs,
  and phases. That cannot live in a `write()` `case` statement —
  it is its own component, independently factory-overridable.
- **Separation of concerns.** "Predict" and "compare" are different
  jobs. A standalone predictor can also feed coverage
  (predicted-vs-actual mismatch bins) — fold it into the scoreboard
  and nothing else can reuse it.
- **Out-of-order is the norm.** Real protocols reorder responses;
  the scoreboard must correlate by ID, not arrival order. The FIFO
  pairing of Style A silently corrupts results the first time a
  response arrives early.
- **`check_phase` is the verdict contract.** Production regressions
  need a deterministic end-of-test check that the scoreboard is
  empty and balanced — not just per-transaction `uvm_error`s.

### When to use which

| Context | Style |
|---|---|
| Salemi ch.16/18 homework (HW2 `scoreboard.svh`) | A — `uvm_subscriber` + inline predictor, match the book |
| Combinational DUT, strict 1:1 ordering | A is acceptable beyond homework |
| Stateful / pipelined / memory DUT | **B** — standalone predictor component |
| Out-of-order protocol (AXI, multiple IDs) | **B** — associative-array correlation, never a FIFO |
| W11 SPI/AXI-Lite, W12+ portfolio | **B** — predictor + comparator, verdict in `check_phase` |

## Analysis port vs analysis FIFO

- `uvm_analysis_imp` — the scoreboard's `write()` is called
  synchronously from the monitor's `analysis_port.write()`. Fast,
  but if the scoreboard does any blocking work it stalls the
  monitor.
- `uvm_tlm_analysis_fifo` — buffers items; the scoreboard `get()`s
  them in its own task. Use this when the scoreboard does anything
  non-trivial.

## Coverage-driven scoreboard

A modern scoreboard also bumps a coverage model:

```systemverilog
covergroup cg @(posedge clk);
    cp_kind:    coverpoint t.kind { bins read = {FIFO_READ}; bins write = {FIFO_WRITE}; }
    cp_addr:    coverpoint t.addr { bins low = {[0:255]}; bins high = {[256:'hFFFF]}; }
    cp_concurrent: cross cp_kind, cp_addr;
endgroup
```

## Reading

- Salemi *UVM Primer* ch.10 (OO testbench — scoreboard as a class),
  pp. 59, 62–65.
- Salemi ch.12 (UVM Components — scoreboard as a `uvm_component`,
  `build_phase` / `connect_phase` overrides), pp. 76–79.
- Salemi ch.16 (Analysis Ports in a Testbench — wiring monitor.ap
  → scoreboard.imp, the two-port scoreboard via
  `uvm_tlm_analysis_fifo`, Figures 110–111), pp. 106–114.
- Salemi ch.18 (Put and Get Ports in Action — the same scoreboard,
  unchanged by the tester/driver split), pp. 123–129.
- Rosenberg & Meade ch.6 — production scoreboard patterns.
- Verification Academy UVM Cookbook — scoreboard recipes:
  https://verificationacademy.com/cookbook/scoreboards

## Cross-links

- `[[uvm_sequences_sequencers]]`
- `[[coverage_functional_vs_code]]`
- `[[uvm_phases]]` — scoreboard's `write()` runs during `run_phase`;
  final compare in `check_phase`.
- `[[uvm_tlm_analysis_fifo]]` — the `cmd_f` field that queues the
  secondary command stream.
- `[[uvm_analysis_ports]]` — the publisher side and the standalone
  predictor / pass-through pattern.
- `[[uvm_subscriber_coverage]]` — the one-stream sibling of the
  two-stream scoreboard.
