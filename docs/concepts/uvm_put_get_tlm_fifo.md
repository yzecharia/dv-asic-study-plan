# UVM Put/Get Ports + `uvm_tlm_fifo` (Interthread Communication)

**Category**: UVM · **Used in**: W5 ch.17 (Salemi anchor — producer/consumer), W5 ch.18 (tester→driver split), W6+, W11, W14 · **Type**: authored

A `uvm_put_port`/`uvm_get_port` pair joined by a `uvm_tlm_fifo #(T)` is UVM's mechanism for **passing a transaction from one thread to another and coordinating their timing**. One `uvm_component`'s `run_phase` calls `put(t)`; a different component's `run_phase` calls `get(t)`; the fifo in the middle queues the item and blocks whichever thread is ahead. This is *interthread* communication — distinct from the *intrathread* fan-out of `uvm_analysis_port` (covered in `[[uvm_analysis_ports]]`), where one synchronous `write()` call runs every subscriber's callback inside the caller's own thread with no thread switch.

This note covers the ch.17 building block. The ch.18 tester/driver split (`base_tester.svh` → `uvm_tlm_fifo` → `driver.svh`) is the same primitive applied to a real testbench — see `[[uvm_tester_component]]` and `[[uvm_driver]]`.

## The problem it solves

Object-oriented SystemVerilog has no equivalent of a module port. Two objects running in separate `run_phase` threads cannot pass data the way two `always` blocks pass data across a wire. The raw language tools are `semaphore` and `mailbox`; rolling your own thread-coordination layer on top of them means every testbench reinvents the wheel. UVM standardises that layer:

- **Ports** — `uvm_put_port #(T)` and `uvm_get_port #(T)`. A component instantiates one to let its `run_phase` talk to another thread.
- **TLM fifo** — `uvm_tlm_fifo #(T)`. A `uvm_component` that connects a put port to a get port and **buffers exactly the elements its depth allows** (default depth 1). TLM = Transaction-Level Modeling; the fifo moves any data type, not just transactions.

## Position

```
   producer (run_phase)              consumer (run_phase)
   ┌───────────────┐                 ┌───────────────┐
   │ uvm_put_port  │■──┐         ┌──■│ uvm_get_port  │
   └───────────────┘   │         │   └───────────────┘
                       ▼         ▼
              ┌──────────────────────────┐
              │  uvm_tlm_fifo #(T)        │
              │  put_export   get_export │
              │  (depth = 1 by default)  │
              └──────────────────────────┘
```

Squares are put/get ports; circles are the fifo's exports. **Ports connect to exports** — always pass an export to a port's `connect()`.

## The two architectural styles

Both styles use the *same* three UVM classes. The split is **where the port and fifo live** and **whether the consumer blocks or polls**.

### Style A — Salemi ch.17: blocking `put`/`get`, fifo owned by the test

Salemi's producer/consumer demo (ch.17 pp. 114–122, Figures 115–120) is the canonical introduction. The producer's `run_phase` calls **blocking** `put_port_h.put(++shared)`; the consumer's `run_phase` calls **blocking** `get_port_h.get(shared)`. The `communication_test` owns the fifo and wires both ports in `connect_phase`.

```systemverilog
class producer extends uvm_component;
    `uvm_component_utils(producer)
    int                shared;
    uvm_put_port #(int) put_port_h;

    function void build_phase(uvm_phase phase);
        put_port_h = new("put_port_h", this);   // ports: new(), NOT the factory
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat (3) begin
            put_port_h.put(++shared);            // blocks while fifo is full
            $display("Sent %0d", shared);
        end
        phase.drop_objection(this);
    endtask
endclass

class consumer extends uvm_component;
    `uvm_component_utils(consumer)
    uvm_get_port #(int) get_port_h;
    int                 shared;

    function void build_phase(uvm_phase phase);
        get_port_h = new("get_port_h", this);
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            get_port_h.get(shared);              // blocks while fifo is empty
            $display("Received: %0d", shared);
        end
    endtask
endclass
```

```systemverilog
class communication_test extends uvm_test;
    `uvm_component_utils(communication_test)
    producer            producer_h;
    consumer            consumer_h;
    uvm_tlm_fifo #(int) fifo_h;

    function void build_phase(uvm_phase phase);
        producer_h = new("producer_h", this);
        consumer_h = new("consumer_h", this);
        fifo_h     = new("fifo_h",     this);
    endfunction

    function void connect_phase(uvm_phase phase);
        producer_h.put_port_h.connect(fifo_h.put_export);   // port → export
        consumer_h.get_port_h.connect(fifo_h.get_export);
    endfunction
endclass
```

Because the fifo holds one element, the run is strictly ping-pong: producer fills the fifo and suspends, consumer drains it and suspends, repeat. No clock, no `virtual interface` — pure thread coordination.

Salemi's ch.17 also shows a **non-blocking** variant (pp. 119–122, Figures 122–123): the consumer blocks on a clock edge instead, and uses `try_get()` — a *function* that returns a `bit` (1 = got an item, 0 = empty) and never blocks. Use `try_get` when the consumer is already blocked on something else (a clock, a fork/join_any) and must not also block on the fifo.

### Style B — Industry production: same primitive, but `uvm_driver`'s built-in `seq_item_port`

In a production UVC you almost never hand-instantiate `uvm_put_port`/`uvm_get_port` for the stimulus path. The sequence/sequencer/driver subsystem already gives you the equivalent: a `uvm_sequencer #(T)` is the buffered producer side, and `uvm_driver #(T)` ships a built-in **`seq_item_port`** that the driver's `run_phase` pulls from with `get_next_item(req)` / `item_done()`. The TLM machinery is identical underneath — `seq_item_port` is a TLM port, the handshake is blocking — but it is wrapped in the sequence layer so you get randomisation, layering, arbitration, and `uvm_do` macros for free. See `[[uvm_sequences_sequencers]]`.

Raw `uvm_put_port`/`uvm_get_port` + `uvm_tlm_fifo` still appears in production code, but for **non-sequence** plumbing: passing predicted transactions from a predictor to a scoreboard, decoupling a slow consumer from a fast monitor, or moving data between two sub-environments. When you need *bounded backpressure* between two `run_phase` threads, `uvm_tlm_fifo #(T, DEPTH)` is the right tool; `uvm_tlm_analysis_fifo` (unbounded, analysis-export inbound) is for the *broadcast* side.

## Why Salemi uses Style A

- **Teaches the primitive directly.** Before sequences exist (his ch.23), the only way to show interthread communication is the bare port/fifo. The producer/consumer demo isolates the concept with zero sequence-layer noise.
- **The ch.18 tester/driver split needs it.** Salemi's `base_tester` (a plain `uvm_component`, not a `uvm_sequence`) `put`s commands; the `driver` `get`s them. With no sequencer in his methodology yet, a hand-wired `uvm_tlm_fifo` is the join.
- **Mirrors the module-port mental model.** Ch.17 opens by showing two Verilog modules talking over a `shared` bus with `put_it`/`get_it` strobes, then rebuilds it with objects. Put/get ports are the object-world version of that picture.

## Why industry uses Style B

- **Sequences are the stimulus contract.** Real stimulus is layered, randomised, and reused across tests. `uvm_sequence` + `uvm_sequencer` provide that; a hand-wired `uvm_put_port` does not. You would be rebuilding the sequence library by hand.
- **`seq_item_port` is already wired.** `uvm_driver #(T)` ships the get-side port. You write the `get_next_item`/`item_done` loop and nothing else — no `connect_phase` plumbing for the stimulus path.
- **Arbitration and priority.** A sequencer arbitrates between concurrent sequences. A raw fifo has one producer and one consumer with no priority knob.
- **Raw put/get is still right for non-stimulus plumbing.** Predictor→scoreboard handoff, rate-decoupling buffers, cross-env data paths — there is no sequence there, so the bare primitive is correct and idiomatic.

## When to use which

| Context | Style |
|---|---|
| Salemi ch.17 producer/consumer drill | A — match the book |
| Salemi ch.18 tester→driver split (HW2) | A — `base_tester` `put`s, `driver` `get`s through `uvm_tlm_fifo` |
| Production driver receiving stimulus | **B** — `uvm_driver` + `seq_item_port` + sequencer |
| Predictor → scoreboard handoff | A primitive, but for data not stimulus — bare put/get or analysis fifo |
| Bounded backpressure between two run_phase threads | `uvm_tlm_fifo #(T, DEPTH)` |
| Broadcast (one monitor → N consumers) | not put/get at all — `uvm_analysis_port`, see `[[uvm_analysis_ports]]` |

## `put`/`get` API surface

| Call | Kind | Blocks? | Returns |
|---|---|---|---|
| `put(t)` | task | yes — until fifo has room | void |
| `get(t)` | task | yes — until fifo has an item | void |
| `try_put(t)` | function | no | `bit` (1 = stored) |
| `try_get(t)` | function | no | `bit` (1 = got) |
| `peek(t)` | task | yes | void (item left in fifo) |
| `can_put()` / `can_get()` | function | no | `bit` |

A blocking `put`/`get` can only be called from a `task` context (`run_phase`). Calling `get()` from a `function` is a compile error — use `try_get` there.

## Common gotchas

- **Constructing a port with the factory** — ports are *not* factory-registered. Use `port = new("port", this)` in `build_phase` (or `new()`). `type_id::create` on a port does not compile.
- **Connecting a put port to a get port directly** — illegal. Both connect to the fifo's exports (`put_export`, `get_export`), never to each other.
- **Forgetting to construct the fifo** — null-pointer fatal on the first `connect()`.
- **Default depth is 1** — `uvm_tlm_fifo #(T)` buffers one element. If you expected a deep queue, pass the depth: `uvm_tlm_fifo #(T, 16)`.
- **`get()` in a clocked `forever` loop** — if the consumer also blocks on `@(posedge clk)`, a blocking `get()` can stall past the edge. Use `try_get()` and test the return bit (Salemi's ch.17 non-blocking consumer).
- **No objection on the consumer** — in the tester/driver split the *tester* raises the objection; the `driver`'s `forever get` loop must not, or the phase never ends. See `[[uvm_run_workflow]]`.

## Reading

- Salemi *The UVM Primer* ch.17 (Interthread Communication), pp. 114–122 — module producer/consumer, then `uvm_put_port`/`uvm_get_port` + `uvm_tlm_fifo`, blocking and non-blocking.
- Salemi *The UVM Primer* ch.18 (Put and Get Ports in Action), pp. 123–129 — the primitive applied to split the TinyALU tester from the driver.
- IEEE 1800.2-2020 §12.2 — TLM-1 port/export/fifo specification.
- Verification Academy UVM Cookbook — TLM connections:
  https://verificationacademy.com/cookbook/tlm

## Cross-links

- `[[uvm_analysis_ports]]` — the *intrathread* broadcast counterpart; contrast table lives there.
- `[[uvm_tlm_analysis_fifo]]` — the analysis-export-inbound, unbounded sibling of `uvm_tlm_fifo`.
- `[[uvm_tester_component]]` — the ch.18 `base_tester` that owns the `uvm_put_port`.
- `[[uvm_driver]]` — the ch.18 driver that owns the `uvm_get_port`; also the production `seq_item_port` form.
- `[[uvm_sequences_sequencers]]` — the production replacement for hand-wired stimulus put/get.
- `[[uvm_env]]` — owns the `uvm_tlm_fifo` and wires it in `connect_phase`.
- `[[uvm_run_workflow]]` · `[[uvm_phases]]` — objection ownership in the put/get split.
