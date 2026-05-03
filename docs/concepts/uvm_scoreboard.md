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

## Two flavours

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

- Salemi ch.24 — scoreboard chapter.
- Rosenberg ch.6 — production scoreboard patterns.
- Verification Academy UVM Cookbook — scoreboard recipes (free).

## Cross-links

- `[[uvm_sequences_sequencers]]`
- `[[coverage_functional_vs_code]]`
- `[[uvm_phases]]` — scoreboard's `write()` runs during `run_phase`;
  final compare in `check_phase`.
