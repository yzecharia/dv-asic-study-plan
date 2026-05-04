# UVM Driver (`uvm_driver`)

**Category**: UVM · **Used in**: W4 (Salemi tester-style), W6+, W12, W14, W20 · **Type**: authored

The driver converts **abstract transactions** (`uvm_sequence_item`)
into pin-level activity on the interface. It's the *only*
component that touches the DUT through clocking blocks and signal
assignments. A junior who buries protocol logic anywhere else
ends up with unmaintainable code that no one else can extend.

## Two driver styles

| Style | When | Stimulus source |
|---|---|---|
| Salemi ch.13 "tester" | learning UVM, no sequencer yet | self-randomised inside `run_phase` |
| Production `uvm_driver` | from ch.22+, every real env | `seq_item_port.get_next_item(req)` |

W4 HW2 uses the ch.13 style; W6 onwards uses production.

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

This is exactly the W4 HW2 shape. Note the **objection is raised
in the tester's `run_phase`**, not the test's. The Salemi pattern
makes the tester self-contained.

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

- Salemi *UVM Primer* ch.22 (Agents — driver section), pp. 154–164.
- Salemi ch.23 (Sequences — driver-sequencer handshake), pp. 165–179.
- Rosenberg & Meade ch.4.
- IEEE 1800.2-2020 §F.6 — `uvm_driver` class.

## Cross-links

- `[[uvm_sequences_sequencers]]` · `[[uvm_monitor]]` · `[[uvm_agent]]`
  · `[[interfaces_modports]]` · `[[ready_valid_handshake]]`
  · `[[uvm_testbench_skeleton]]`
