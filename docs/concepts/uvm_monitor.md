# UVM Monitor (`uvm_monitor`)

**Category**: UVM · **Used in**: every UVM week from W4 onward · **Type**: authored

The monitor watches the interface, reconstructs **abstract
transactions** from pin activity, and publishes them on a
`uvm_analysis_port`. Multiple subscribers (scoreboard, coverage,
logger) attach to the same port and each gets an independent copy.
The monitor must be **passive** — it never drives a signal.

## Position

```
       DUT pins
         │
         ▼ (sample on clocking event)
    uvm_monitor  ← THIS
         │ analysis_port.write(txn)
   ┌─────┼─────────┐
   ▼     ▼         ▼
 scoreboard cov   logger / waveform tagger
```

## Mandatory skeleton

```systemverilog
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    virtual my_if vif;
    uvm_analysis_port#(my_seq_item) ap;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);              // analysis port created in new()
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "vif not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        my_seq_item txn;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.valid && vif.monitor_cb.ready) begin
                txn = my_seq_item::type_id::create("txn");
                txn.payload = vif.monitor_cb.payload;
                ap.write(txn);             // broadcasts to every subscriber
            end
        end
    endtask
endclass
```

## What goes where

| Override | Purpose |
|---|---|
| `new()` | super + **construct the analysis port** (Salemi convention) |
| `build_phase` | get `vif` from config_db |
| `run_phase` | sample the bus, build txn, `ap.write(txn)` |

## Active vs passive monitor in the agent

Both active and passive agents instantiate the monitor — see
`[[uvm_agent]]`. The same monitor class works in both
configurations because it never asserts any signal.

## Sampling at the right edge

Always sample through a `clocking block` configured for **input**
skew (e.g. `default input #1step`). Sampling combinationally on
the DUT clock can grab a value mid-transition and produce false
mismatches in the scoreboard.

```systemverilog
interface my_if(input logic clk);
    logic        valid, ready;
    logic [31:0] payload;

    clocking monitor_cb @(posedge clk);
        default input #1step;            // sample 1 timestep before clock edge
        input valid, ready, payload;
    endclocking

    modport monitor (clocking monitor_cb);
endinterface
```

## Common gotchas

- **Constructing `ap` in `build_phase`** — works, but Salemi style
  puts it in `new()`. Either is legal; pick one and be consistent
  across the env.
- **Driving from a monitor** — never. If you need to drive, you
  want a driver, not a monitor.
- **Missing `vif` config_db get** — silently runs with null vif and
  every `vif.monitor_cb` is X. Always `uvm_fatal` on miss.
- **Reusing the same `txn` handle across iterations** — every
  subscriber holds a reference. Mutating `txn` after `ap.write()`
  corrupts the scoreboard's data. Always `create()` a fresh item.

## Reading

- Salemi *UVM Primer* ch.16 (Using Analysis Ports in a Testbench),
  pp. 106–114.
- Salemi ch.22 (UVM Agents — monitor section), pp. 154–164.
- IEEE 1800.2-2020 §F.7 — `uvm_monitor` class.

## Cross-links

- `[[uvm_subscriber_coverage]]` · `[[uvm_scoreboard]]` · `[[uvm_agent]]`
  · `[[interfaces_modports]]` · `[[clocking_resets]]`
  · `[[uvm_testbench_skeleton]]`
