# UVM Agent (`uvm_agent`)

**Category**: UVM · **Used in**: W7, W12, W14 (per-UVC), W20 · **Type**: authored

An agent bundles together everything needed to interact with one
**interface protocol**: a driver, a monitor, and (when active) a
sequencer. Agents are the unit of reuse — one AXI agent class
handles every AXI bus in the env, regardless of which test runs
or how many instances exist.

## Active vs passive

```
Active agent (drives + observes):                Passive agent (observes only):

┌──────────────────────────┐                     ┌──────────────────┐
│ uvm_sequencer            │                     │  uvm_monitor     │
│ uvm_driver  ── vif ──────┼──→ DUT              │   ── vif ────────┼── DUT.observe.bus
│ uvm_monitor ── vif ──────┘                     │                  │
└──────────────────────────┘                     └──────────────────┘
```

The `is_active` field (`UVM_ACTIVE` / `UVM_PASSIVE`) selects at
build time. A production env on a chip with N AXI masters typically
has one active agent driving the unit under test and N−1 passive
agents that just observe surrounding traffic for the scoreboard.

## Mandatory skeleton

```systemverilog
class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    my_sequencer sequencer;
    my_driver    driver;
    my_monitor   monitor;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // allow test/env to flip active/passive per-instance
        void'(uvm_config_db#(uvm_active_passive_enum)::get(
              this, "", "is_active", is_active));

        monitor = my_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            sequencer = my_sequencer::type_id::create("sequencer", this);
            driver    = my_driver   ::type_id::create("driver",    this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
```

## What goes where

| Override | Purpose |
|---|---|
| `new()` | super only |
| `build_phase` | check `is_active`; create monitor always; create driver+sequencer only if active |
| `connect_phase` | wire `driver.seq_item_port` ↔ `sequencer.seq_item_export` (active only) |
| no `run_phase` | agent is structural |

## Why monitor is always built

The monitor exists in *every* configuration — even passive agents
need to publish observed transactions to the scoreboard / coverage
collector in the env. Driver + sequencer only exist when actively
driving the bus.

## Sequencer type

`my_sequencer` is almost always just `typedef uvm_sequencer #(my_seq_item) my_sequencer;`
— you rarely subclass it unless you need custom arbitration or a
virtual sequencer that holds handles to other sequencers.

## Common gotchas

- **Forgetting to register the sequencer typedef with the
  factory** — typedefs of parameterised classes don't always
  factory-register cleanly. Best practice: `typedef` it inside the
  package, then `create()` works because `uvm_sequencer` is already
  registered.
- **Hard-coding `is_active = UVM_ACTIVE`** — defeats reuse. Always
  allow override via `uvm_config_db`.
- **Wiring `driver.seq_item_port` for passive agents** — null
  pointer crash. The `if (is_active)` guard in `connect_phase` is
  not optional.

## Reading

- Salemi *UVM Primer* ch.22 (UVM Agents), pp. 154–164.
- Rosenberg & Meade ch.4 — agent design patterns.
- IEEE 1800.2-2020 §F.4 — `uvm_agent` class.

## Cross-links

- `[[uvm_driver]]` · `[[uvm_monitor]]` · `[[uvm_sequences_sequencers]]`
  · `[[uvm_env]]` · `[[uvm_factory_config_db]]`
  · `[[uvm_testbench_skeleton]]`
