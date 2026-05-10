# UVM Analysis Ports + `uvm_subscriber` (Observer Pattern)

**Category**: UVM · **Used in**: W5 (anchor — Salemi ch.15–16), W7+, W11, W12, W14, W20 · **Type**: authored

UVM's analysis port is the Observer pattern with `\`uvm_component_utils` macros bolted on. **One producer broadcasts a transaction; N consumers receive it, each in its own subclass.** The producer doesn't know how many consumers exist or what they do; consumers don't know about each other. That decoupling is the whole point — every monitor becomes a fan-out point, and adding a new coverage subscriber doesn't require touching the monitor.

This is W4's contrast: there your scoreboard *peeked* at the BFM directly (producer-knows-consumer). With analysis ports the relationship inverts.

## The pattern at a glance

```
                        ┌─→ uvm_subscriber #(T) — scoreboard
   monitor.ap           │
   uvm_analysis_port#T ─┼─→ uvm_subscriber #(T) — coverage
                        │
                        └─→ uvm_subscriber #(T) — logger / extra consumer
```

One `write(T t)` call on `monitor.ap` synchronously fans out to every connected subscriber's `write()` callback in connect order.

## The publisher (the one being observed)

The component that *broadcasts*. Three required steps.

```systemverilog
class command_monitor extends uvm_component;
    `uvm_component_utils(command_monitor)

    uvm_analysis_port #(command_t) ap;             // 1. declare the port

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);                      // 2. construct it
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        command_t cmd;
        forever begin
            // ... observe DUT, build cmd struct from sampled signals ...
            ap.write(cmd);                         // 3. broadcast — synchronous
        end
    endtask : run_phase

endclass : command_monitor
```

Three rules for the publisher:

1. **Declare** `uvm_analysis_port #(T) ap;` as a class field.
2. **Construct** it in `build_phase` — `ap = new("ap", this)`. Forgetting this gives a null-pointer on the first `write()`.
3. **Call** `ap.write(t)` whenever a transaction is ready. The call returns *after* every subscriber has consumed.

## The subscriber (the observer)

The component that *receives*. Inherits the `analysis_export` and the `write()` contract from `uvm_subscriber`.

```systemverilog
class scoreboard extends uvm_subscriber #(command_t);
    `uvm_component_utils(scoreboard)

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void write(command_t t);              // mandatory — called per broadcast
        // ... compare against reference model, accumulate stats, fire `uvm_error on miss ...
    endfunction : write

endclass : scoreboard
```

Three things to internalise:

1. **`extends uvm_subscriber #(T)`** — the parameter `T` binds the transaction type. A `uvm_subscriber#(int)` cannot connect to a `uvm_analysis_port#(command_t)` — UVM enforces type strictness.
2. **`analysis_export` is inherited** — you don't declare or construct it. The `uvm_subscriber` parent already did.
3. **`function void write(T t)` is pure virtual** — your subclass *must* implement it. The compiler enforces this; forgetting it is a build error, not a silent runtime bug.

## Wiring it together — `connect_phase` is mandatory

The env (or whoever owns both ends) wires the port to each subscriber's export:

```systemverilog
class env extends uvm_env;
    `uvm_component_utils(env)

    command_monitor mon_h;
    scoreboard      sb_h;
    coverage        cov_h;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_h = command_monitor::type_id::create("mon_h", this);
        sb_h  = scoreboard      ::type_id::create("sb_h",  this);
        cov_h = coverage        ::type_id::create("cov_h", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon_h.ap.connect(sb_h .analysis_export);   // wire monitor → scoreboard
        mon_h.ap.connect(cov_h.analysis_export);   // and monitor → coverage
    endfunction : connect_phase

endclass : env
```

**Why `connect_phase` and not `build_phase`?** Components must exist before you can wire them. `build_phase` runs top-down and recursively constructs child components; only after every `build_phase` returns does UVM start the bottom-up `connect_phase`. By that point, both sides of every `connect()` call are guaranteed to exist. Putting `connect()` calls in `build_phase` races the construction order and hits null pointers in deep hierarchies.

## Initialization checklist

| Component | What's needed |
|---|---|
| Publisher | declare `uvm_analysis_port #(T) ap`, **construct** with `ap = new("ap", this)` in `build_phase` |
| Subscriber | declare class as `extends uvm_subscriber #(T)`, implement `function void write(T t)`, register with factory via `\`uvm_component_utils` |
| Env (or owner) | construct both sides in `build_phase`, wire with `pub.ap.connect(sub.analysis_export)` in `connect_phase` |

## How the broadcast actually executes

1. Producer calls `ap.write(cmd)`.
2. UVM iterates the analysis port's internal subscriber list (built up by `connect()` calls).
3. For each connected `analysis_export`, UVM invokes that subscriber's `write(cmd)` — **synchronously**, in connect order.
4. After every subscriber has returned, control returns to the producer.

This is **synchronous fan-out**, not threaded. If any subscriber's `write()` does slow work (a long compare against a reference model, file I/O, etc.) the producer blocks. For decoupled producer/consumer with buffering, use `uvm_tlm_analysis_fifo` (Salemi ch.16) — its export queues incoming items and the consumer pulls with `try_get()` when ready.

## Industry-standard generalisations

### One producer → N consumers (the dice-roller / TinyALU pattern)
The textbook fan-out. Add a new subscriber by writing the class and adding one `.connect()` line in the env. The producer source is untouched.

### One subscriber needing two input streams (Salemi ch.16 scoreboard)
A scoreboard needs both *commands* (from `command_monitor`) and *results* (from `result_monitor`) to do its job. It can directly subclass `uvm_subscriber#(result_t)` for one stream, and hold a `uvm_tlm_analysis_fifo #(command_t)` field for the other. The fifo's `analysis_export` connects to the command monitor; the scoreboard's `write(result)` does `cmd_f.try_get(cmd)` to pair it with the matching command.

### Cross-env / cross-hierarchy connects
`uvm_analysis_port::connect()` doesn't care about the component tree — `env_a.mon_h.ap.connect(env_b.sb_h.analysis_export)` is legal and useful in multi-env testbenches (e.g. comparing two protocol layers).

### Stand-alone analysis ports without subscribers
You don't *have* to use `uvm_subscriber`. The lower-level form is `uvm_analysis_imp_decl(...)` — a macro that declares a custom `analysis_imp` you implement manually. Used when you need *multiple* incoming streams of *different types* into the same component (the imp_decl macro mangles the method name so each stream's `write()` is distinct). Salemi never uses this; it's industry-standard for complex agents.

### A subscriber that's also a publisher (predictor / pass-through pattern)

There's no exclusivity rule — a single component can be **both** a subscriber (extends `uvm_subscriber#(T_in)`, implements `write(T_in)`) **and** a publisher (declares its own `uvm_analysis_port #(T_out)`, calls `.write(T_out)` from inside the inherited `write()`). This is one of the most common industry patterns.

```systemverilog
class predictor extends uvm_subscriber #(command_t);   // observer side
    `uvm_component_utils(predictor)

    uvm_analysis_port #(predicted_t) ap;               // publisher side

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);                          // construct outgoing port
    endfunction : build_phase

    function void write(command_t t);                  // inherited contract
        predicted_t pred;
        pred = compute_expected(t);                    // run reference model
        ap.write(pred);                                // re-broadcast as publisher
    endfunction : write

endclass : predictor
```

Canonical use cases:

| Use case | What it does |
|---|---|
| **Reference model / predictor** | subscribes to commands, runs the spec model, publishes predicted results for the scoreboard to compare against actual results. The W7+ scoreboard pattern. |
| **Protocol-layer translator** | subscribes at one abstraction (e.g. byte-level), publishes at another (e.g. bit-level). Same component bridges two layers because they share internal state. |
| **Filter / decimator** | subscribes to a high-rate stream, drops or transforms each, publishes the decimated stream to coarse-grained downstream subscribers. |
| **Tap / pass-through logger** | subscribes, logs to file, re-publishes the same `t` unchanged. `write(t); ap.write(t);` — note `t` is by reference, so if you mutate it before re-broadcasting, downstream sees the mutation. Clone with `t.clone()` if you need an independent copy. |
| **Aggregator → escalator** | subscribes to per-event errors during the run, publishes a single `summary_t` in `report_phase` or `extract_phase`. |

If your component needs **multiple input streams *plus*** its own output (e.g. both `command_t` and `result_t` as inputs), `uvm_subscriber#(T)` locks you to one input type. Two ways out:

- **`uvm_analysis_imp_decl(...)`** — declares a custom imp type with a name-mangled `write_X()` per stream. The complex-agent industry default.
- **Hold a `uvm_tlm_analysis_fifo#(T_secondary)` field** — keep `uvm_subscriber#(T_main)` for the primary input, queue the second stream into the fifo, pull with `try_get()` inside the main `write()`. This is what Salemi reaches for in ch.16's scoreboard (already covered in the *two-input-streams* subsection above).

The graph stays acyclic by construction (analysis ports flow downstream only), so cycles aren't a concern.

## Pitfalls

| Pitfall | Symptom |
|---|---|
| Forgetting `ap = new(...)` in publisher's `build_phase` | null-pointer fatal on first `write()` |
| Putting `connect()` calls in `build_phase` | works for shallow envs, races and crashes in deep ones |
| Heavy work in subscriber's `write()` | producer blocks; throughput collapses |
| Mismatched parameter types between port and export | compile error (good) |
| Multiple subscribers, one mutates `t` in place | the next subscriber sees the mutation — `t` is by reference. Treat `t` as read-only or `clone()` before mutating. |
| Sub-class forgets to implement `write()` | compile error (`uvm_subscriber::write` is pure virtual) — caught early |

## Why analysis ports specifically (vs put/get)

| | Analysis port (broadcast) | Put/get port (interthread) |
|---|---|---|
| Topology | one producer, N consumers | one producer, one consumer |
| Mechanism | `write(t)` is a synchronous function call into every subscriber | `put(t)` / `get(t)` blocks; goes through a `uvm_tlm_fifo` |
| Threading | none — no thread switch | yes — producer and consumer can be on different processes |
| Buffering | none (or via `uvm_tlm_analysis_fifo`) | yes (the `uvm_tlm_fifo` itself queues items) |
| Use when | a monitor wants to inform the world about an event | a tester wants to hand stimulus to a driver across threads |

Salemi covers analysis ports in ch.15–16, then put/get in ch.17–18. They solve different problems; you'll typically see both in the same agent.

## Reading

- Salemi *The UVM Primer* ch.15 (Talking to Multiple Objects) — dice-roller anchor.
- Salemi *The UVM Primer* ch.16 (Analysis Ports in the Testbench) — TinyALU two-port scoreboard via `uvm_tlm_analysis_fifo`, pp. 106–114.
- IEEE 1800.2-2020 §12.2 — UVM analysis primitive specification.
- Verification Academy UVM Cookbook — Analysis Components:
  https://verificationacademy.com/cookbook/analysis_components

## Cross-links

- `[[uvm_subscriber_coverage]]` — subscriber-as-coverage-collector specialisation (W3 anchor).
- `[[uvm_monitor]]` — canonical publisher of an analysis port.
- `[[uvm_scoreboard]]` — canonical multi-port consumer.
- `[[uvm_phases]]` — `connect_phase` ordering guarantee.
- `[[uvm_factory_config_db]]` — how subscribers get factory-overridden per test.
