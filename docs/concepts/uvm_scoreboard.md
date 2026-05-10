# UVM Scoreboard

**Category**: UVM · **Used in**: W7, W12, W13, W20 · **Type**: authored

The scoreboard is where verdict happens. It receives observed
transactions (from the monitor's analysis port) and compares them
against expected behaviour (from a reference model). On mismatch, it
fails the test.

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
  → scoreboard.imp), pp. 106–114.
- Rosenberg & Meade ch.6 — production scoreboard patterns.
- Verification Academy UVM Cookbook — scoreboard recipes:
  https://verificationacademy.com/cookbook/scoreboards

## Cross-links

- `[[uvm_sequences_sequencers]]`
- `[[coverage_functional_vs_code]]`
- `[[uvm_phases]]` — scoreboard's `write()` runs during `run_phase`;
  final compare in `check_phase`.
