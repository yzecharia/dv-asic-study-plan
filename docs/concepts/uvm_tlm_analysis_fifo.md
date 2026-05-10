# UVM TLM Analysis FIFO (`uvm_tlm_analysis_fifo`)

**Category**: UVM · **Used in**: W5 (anchor — Salemi ch.16 scoreboard), W7+, W11 (multi-stream agents), W14 (RAL + multi-UVC), W20 · **Type**: authored

`uvm_tlm_analysis_fifo #(T)` is the "queue between an analysis port and a consumer that can't keep up — or that needs to consume on its own schedule." It's a `uvm_component` that exposes both an **`analysis_export`** (so any `uvm_analysis_port#(T)` can push into it) and a **`get_export` / `try_get` API** (so a downstream consumer can pull from it whenever it wants). It is the answer to two problems that pure `uvm_subscriber` can't solve.

## The two problems it solves

### Problem 1 — A consumer that needs two input streams of different types

`uvm_subscriber#(T)` locks you to one type. The Salemi ch.16 scoreboard needs both `command_s` (from the command monitor) and `shortint` (the result, from the result monitor) in order to compare predicted vs actual. It can't extend `uvm_subscriber` *twice*. The fix:

- Pick the "primary" stream — typically the one whose arrival drives the compare. Extend `uvm_subscriber#(T_primary)`; that stream flows into the scoreboard's inherited `analysis_export` and triggers the inherited `write(T_primary)`.
- Put the "secondary" stream in a `uvm_tlm_analysis_fifo#(T_secondary)`; it queues incoming items for later consumption.
- Inside the inherited `write()`, the scoreboard pulls from the fifo with `try_get()` to pair the secondary item with the primary item it just received.

### Problem 2 — A consumer that does long-running work and shouldn't stall the publisher

A pure subscriber's `write()` is called *synchronously* from the publisher's `analysis_port.write()`. If `write()` is slow (large reference model, file I/O, network call), the publisher blocks. Putting a `uvm_tlm_analysis_fifo` between the publisher and the consumer decouples them — the publisher pushes and returns immediately; the consumer pulls in its own `run_phase` task at its own pace.

## What the primitive actually exposes

```systemverilog
class uvm_tlm_analysis_fifo #(type T) extends uvm_component;
    // Inbound — analysis ports connect to this
    uvm_analysis_imp_<...> analysis_export;

    // Outbound — consumers pull via these
    function bit try_get(output T t);          // returns 1 if got an item, 0 if empty (non-blocking)
    function bit try_peek(output T t);         // same but doesn't remove
    task         get(output T t);              // BLOCKS until an item arrives
    task         peek(output T t);             // blocks; doesn't remove
    function int size();                       // number of items currently queued
    function void flush();                     // drop everything
    ...
endclass
```

Key facts:
- **Unbounded depth** by default. It will queue forever; if you don't drain, you leak memory and never see backpressure. Bounded version is `uvm_tlm_fifo#(T, depth)`.
- The exposed `analysis_export` is what `analysis_port.connect(...)` connects to. The fifo itself is the *destination* of the broadcast.
- `try_get` is a **function** (zero time); `get` is a **task** (can block). The choice depends on where you're calling from.

## Standard usage — the Salemi ch.16 scoreboard pattern

```systemverilog
class scoreboard extends uvm_subscriber #(shortint);     // primary stream: result
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(command_s) cmd_f;             // secondary stream: command

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cmd_f = new("cmd_f", this);                       // construct the fifo
    endfunction : build_phase

    function void write(shortint actual_result);          // inherited contract
        command_s  cmd;
        shortint   predicted;

        // Pull the matching command from the queue
        if (!cmd_f.try_get(cmd))
            `uvm_fatal("SCB", "Result arrived without a queued command")

        // Run the predictor
        case (cmd.op)
            add_op: predicted = cmd.A + cmd.B;
            and_op: predicted = cmd.A & cmd.B;
            xor_op: predicted = cmd.A ^ cmd.B;
            mul_op: predicted = cmd.A * cmd.B;
            default: return;                              // no_op / rst_op — skip compare
        endcase

        if (predicted !== actual_result)
            `uvm_error("SCB",
                $sformatf("MISMATCH op=%s A=%h B=%h actual=%h predicted=%h",
                          cmd.op.name(), cmd.A, cmd.B, actual_result, predicted))
    endfunction : write

endclass : scoreboard
```

And in the env's `connect_phase`:

```systemverilog
function void env::connect_phase(uvm_phase phase);
    // result stream → scoreboard's inherited analysis_export
    result_monitor_h.ap.connect(scoreboard_h.analysis_export);

    // command stream → fifo's analysis_export (NOT the scoreboard's)
    command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);

    // command stream also fans out to coverage
    command_monitor_h.ap.connect(coverage_h.analysis_export);
endfunction
```

Note the asymmetry — the result stream connects to the scoreboard *directly* (because the scoreboard *is* a subscriber), but the command stream connects to **the fifo's `analysis_export`**, not the scoreboard's.

## `try_get` vs `get` — when to use which

| API | Returns | Blocks? | Call from |
|---|---|---|---|
| `try_get(out)` | `bit` (1 = got, 0 = empty) | no (function) | `function void` callbacks like `write()` — anywhere zero-time |
| `try_peek(out)` | `bit` | no | same — when you want to inspect without consuming |
| `get(out)` | void | **yes** (task) | `task` contexts like `run_phase`, when blocking until item arrives is acceptable |
| `peek(out)` | void | yes | same |

**Rule of thumb:**
- Inside a subscriber's `write()` callback (a function): **must be `try_get`**. Functions can't block; calling `get()` is a compile error.
- Inside a `run_phase` `forever` loop pulling from the fifo: use `get()` — block until next item.

## When to use a tlm_analysis_fifo (and when not to)

### Use it when…
- A consumer needs two-or-more analysis-port inputs of *different types* (the ch.16 scoreboard).
- A consumer's processing is slow enough that you don't want to stall the publisher (reference model, file logging at every transaction, network egress).
- You want **explicit ordering control** — pull in your own task at your own pace, possibly draining the queue in batches.
- You want to **inspect queue depth** as a sanity check (`size()` reveals if a producer is outrunning the consumer — a real bug indicator).

### Don't use it when…
- The consumer needs one stream and processing is fast — plain `uvm_subscriber#(T)` is simpler.
- You need bounded backpressure — use `uvm_tlm_fifo#(T, DEPTH)` or a `put_export`/`get_export` pair instead. Analysis fifos are *unbounded* by spec.
- The two streams need to be *correlated by something other than arrival order* (e.g. transaction ID with out-of-order responses) — you want an **associative array indexed by ID**, not a FIFO.

## Industry-standard generalisations

### Producer–consumer rate matching
A monitor that produces 100 transactions in a tight `run_phase` loop, paired with a scoreboard that runs a slow reference model. Without the fifo, the monitor blocks on every `ap.write()` until the scoreboard's `write()` returns. With the fifo, the monitor races ahead; the scoreboard catches up later. Queue depth becomes a *measurement* of model latency.

### Multi-stream consumers in protocol envs
A protocol scoreboard often takes `(addr, write_data, response)` from three separate monitors. The pattern generalises to N fifos — one per non-primary stream. The primary stream typically picks the one whose arrival means "transaction complete, run compare now."

### Replacing `uvm_subscriber` entirely with a queue
For consumers whose `write()` would just enqueue and process later anyway, skip the subscriber: have *every* input go through its own analysis fifo, and run the consumer logic in a `run_phase` task that pulls from each fifo in whatever order it wants. This is the pattern used in heavy-weight scoreboards and any consumer that needs explicit `fork`/`join_any` control.

### As a logical "tap"
A logger or wave annotator can subscribe via an analysis fifo, batch up items, and flush periodically. Decouples logging cadence from transaction cadence.

## Pitfalls

| Pitfall | Symptom |
|---|---|
| Calling `get()` from inside a `function` (e.g. `write()`) | Compile error: "task called from function" |
| Forgetting to drain the fifo | Memory grows unbounded; if your simulation runs long enough, swap death |
| Using `try_get`'s return value but not checking it | You silently process whatever junk was in `cmd` (uninitialised). Always `if (!cmd_f.try_get(cmd)) <handle empty>` |
| Connecting publisher's port directly to the *scoreboard*'s `analysis_export` for the secondary stream | Nothing ever queues; scoreboard's `write()` fires for both streams; types don't match → compile error or runtime mayhem |
| Two streams arrive interleaved in unexpected ways | The fifo is FIFO-ordered. If the spec doesn't guarantee 1-cmd-then-1-result ordering, you need an associative array, not a fifo |
| Forgetting to construct the fifo in `build_phase` | Null pointer on first `ap.connect(...)` or first `try_get` |

## Position in the analysis hierarchy

```
                 uvm_analysis_port#(T)        (publisher)
                          │
                          ▼
   ┌─────────────────────────────────────────┐
   │  Three valid destinations:              │
   │                                         │
   │  1. uvm_subscriber#(T).analysis_export  │  ← synchronous write() callback
   │  2. uvm_analysis_imp#(T,parent)         │  ← custom write() in arbitrary class
   │  3. uvm_tlm_analysis_fifo#(T)           │  ← buffered, pulled by consumer
   │     .analysis_export                    │
   └─────────────────────────────────────────┘
```

All three are valid `connect()` targets for a `uvm_analysis_port`. The choice is about consumer semantics, not publisher syntax.

## Reading

- Salemi *The UVM Primer* ch.16 (Analysis Ports in the Testbench), pp. ~106–114 — TinyALU two-port scoreboard via `uvm_tlm_analysis_fifo`.
- IEEE 1800.2-2020 §12.2.8 — `uvm_tlm_analysis_fifo` class spec.
- Verification Academy UVM Cookbook — Analysis FIFO recipes:
  https://verificationacademy.com/cookbook/analysis_fifo

## Cross-links

- `[[uvm_analysis_ports]]` — the publisher side; this note is the canonical destination for one of its `connect()` flavors.
- `[[uvm_scoreboard]]` — the canonical consumer in this pattern.
- `[[uvm_subscriber_coverage]]` — alternate (one-stream, function-callback) consumer.
- `[[uvm_phases]]` — `connect_phase` ordering for the wiring.
