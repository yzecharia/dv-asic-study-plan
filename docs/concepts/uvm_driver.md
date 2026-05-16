# UVM Driver (`uvm_driver`)

**Category**: UVM · **Used in**: W4 (Salemi tester-style), W5 ch.18 (`driver.svh` — get-port variant), W6+, W12, W14, W20 · **Type**: authored

The driver converts **abstract transactions** (`uvm_sequence_item`)
into pin-level activity on the interface. It's the *only*
component that touches the DUT through clocking blocks and signal
assignments. A junior who buries protocol logic anywhere else
ends up with unmaintainable code that no one else can extend.

## Three driver styles

| Style | When | Stimulus source |
|---|---|---|
| Salemi ch.13 "tester" | first UVM weeks, no sequencer, no fifo | self-randomised inside `run_phase` |
| Salemi ch.18 get-port driver | tester/driver split (HW2) | `uvm_get_port` pulling from a `uvm_tlm_fifo` |
| Production `uvm_driver` | from ch.22+, every real env | `seq_item_port.get_next_item(req)` |

W4 HW1 uses the ch.13 style; W5 HW2 uses the ch.18 get-port style;
W6 onwards uses production. All three apply transactions to the
DUT; they differ only in *where the transaction comes from*.

## Production skeleton (sequencer-driven)

```systemverilog
class my_driver extends uvm_driver #(my_seq_item);
    `uvm_component_utils(my_driver)

    virtual my_if vif;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "vif not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        my_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);
            drive_one(req);
            seq_item_port.item_done();   // unblocks sequencer's next start_item
        end
    endtask

    task drive_one(my_seq_item req);
        @(vif.driver_cb);
        vif.driver_cb.valid   <= 1'b1;
        vif.driver_cb.payload <= req.payload;
        @(vif.driver_cb iff vif.driver_cb.ready);
        vif.driver_cb.valid   <= 1'b0;
    endtask
endclass
```

## Salemi ch.13 "tester" style (no sequencer)

```systemverilog
class my_tester extends uvm_component;
    `uvm_component_utils(my_tester)
    virtual my_if vif;

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat (NUM_TXNS) begin
            my_seq_item req = my_seq_item::type_id::create("req");
            if (!req.randomize())
                `uvm_fatal("RAND", "randomize failed")
            drive_one(req);
        end
        phase.drop_objection(this);
    endtask

    // drive_one() identical to production version
endclass
```

This is exactly the W4 HW1 shape. Note the **objection is raised
in the tester's `run_phase`**, not the test's. The Salemi pattern
makes the tester self-contained.

## Salemi ch.18 "get-port" driver (tester/driver split)

W5 HW2 (`driver.svh`) introduces a **third** style that sits between
the ch.13 tester and the production `uvm_driver`. The stimulus
*generator* (the `base_tester`, see `[[uvm_tester_component]]`) is now
a separate component; this driver's only job is to **pull commands
across a thread boundary and apply them**. It is a plain
`uvm_component` that owns a `uvm_get_port` instead of inheriting
`uvm_driver`'s `seq_item_port`.

```systemverilog
class driver extends uvm_component;
    `uvm_component_utils(driver)

    virtual alu_if            aluif;            // or virtual tinyalu_bfm in Salemi's code
    uvm_get_port #(command_t) get_port_h;       // get port — pulls from a uvm_tlm_fifo

    function new(string name = "driver", uvm_component parent = null);
        super.new(name, parent);
        get_port_h = new("get_port_h", this);   // port: new(), NOT the factory
    endfunction

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_fatal("NOVIF", "aluif not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        command_t cmd;
        forever begin
            get_port_h.get(cmd);                // BLOCKS until the tester puts a command
            aluif.send_op(cmd);                 // apply it — BFM task drives the pins
        end
        // NOTE: no raise/drop_objection here — the tester owns the objection
    endtask
endclass
```

Three things distinguish it from the production driver:

1. **`extends uvm_component`, not `uvm_driver #(T)`.** There is no
   sequencer, so there is no `seq_item_port`. The driver instantiates
   its own `uvm_get_port` and the env wires it to a `uvm_tlm_fifo`'s
   `get_export` — see `[[uvm_put_get_tlm_fifo]]`.
2. **`get_port_h.get(cmd)` blocks, then the BFM task applies it.**
   When the fifo is empty the `get()` suspends the driver thread;
   the tester's `put()` on the other end wakes it. Salemi's driver
   then calls `bfm.send_op(...)`, a procedural BFM task that drives
   the pin sequence — no clocking block in the driver itself.
3. **No objection.** The driver runs a bare `forever` loop and would
   never end the phase on its own. The *tester* raises and drops the
   objection; once the tester drains, the phase ends and the driver's
   `forever` loop is torn down. See `[[uvm_run_workflow]]`.

This is structurally a producer/consumer pair: the tester is the
producer, this driver is the consumer, the `uvm_tlm_fifo` is the
buffered channel. It is the ch.13 tester split cleanly in two.

## Required overrides

| Phase | Override | What |
|---|---|---|
| `new()` | yes | super only |
| `build_phase` | yes | get `vif` from config_db with `uvm_fatal` on miss |
| `run_phase` | yes (task) | the get / drive / item_done loop (production) or the randomize-and-drive loop (Salemi) |
| `report_phase` | optional | tally driven transactions |

## Common gotchas

- **Driving signals outside a clocking block** — causes race
  conditions with the monitor and the DUT. Always go through
  `vif.driver_cb`, never bare `vif.signal`.
- **Forgetting `seq_item_port.item_done()`** — sequencer blocks
  forever on the next `start_item`; sim hangs.
- **Calling `randomize()` on `req` inside the production driver** —
  that's the sequence's job. The driver receives an
  already-randomised item and must not mutate it.
- **Skipping `super.new(name, parent)`** — driver doesn't register
  with the factory; `create()` returns null.

## Reading

- Salemi *UVM Primer* ch.18 (Put and Get Ports in Action — the
  get-port driver), pp. 123–129. The driver-with-get-port is
  Figure 129.
- Salemi *UVM Primer* ch.22 (Agents — driver section), pp. 154–164.
- Salemi ch.23 (Sequences — driver-sequencer handshake), pp. 165–179.
- Rosenberg & Meade ch.4.
- IEEE 1800.2-2020 §F.6 — `uvm_driver` class.

## Cross-links

- `[[uvm_sequences_sequencers]]` · `[[uvm_monitor]]` · `[[uvm_agent]]`
  · `[[interfaces_modports]]` · `[[ready_valid_handshake]]`
  · `[[uvm_testbench_skeleton]]`
- `[[uvm_put_get_tlm_fifo]]` — the get-port + `uvm_tlm_fifo` the
  ch.18 driver consumes from.
- `[[uvm_tester_component]]` — the producer-side counterpart in the
  ch.18 split.
- `[[uvm_run_workflow]]` — why the ch.18 driver raises no objection.
