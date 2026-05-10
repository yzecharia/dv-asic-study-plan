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

## Two architectural styles for the actual sampling

The skeleton above is **Style A — clocking-block sampling in `run_phase`**, the modern industry default. There's a second pattern you'll meet in Salemi ch.16 ("Style B — BFM-callback architecture") that's worth recognising and *not* using in production code.

### Style A — Clocking-block sampling in `run_phase` (industry standard)

The monitor's `run_phase` runs a `forever` loop that blocks on the clocking event, samples signals, builds a transaction, and publishes via `ap.write(txn)`. **The interface is pin-level** — `valid`, `ready`, `payload`, etc. — so the monitor's contract with the DUT is exactly the RTL contract. The clocking block guards against driver/sample races.

This is the default for any real DUT, any production env, any UVC you'll write at NVIDIA-tier shops.

### Style B — BFM-callback architecture (Salemi ch.16, *not* industry-standard)

Salemi's BFM is a **procedural wrapper interface** — it has embedded tasks like `send_op(...)` that drive sequences of pin activity, plus `always` blocks that observe DUT events. Instead of the monitor sampling the bus, the BFM **calls back into the monitor** when an event happens:

```systemverilog
// In the BFM (interface):
command_monitor command_monitor_h;     // reverse handle

always @(posedge clk) begin : cmd_monitor
    if (start && new_command)
        command_monitor_h.write_to_monitor(A, B, op);   // BFM calls into UVM component
end
```

```systemverilog
// In the monitor (uvm_component):
class command_monitor extends uvm_component;
    uvm_analysis_port #(command_s) ap;

    function void build_phase(uvm_phase phase);
        virtual tinyalu_bfm bfm;
        if (!uvm_config_db#(virtual tinyalu_bfm)::get(null, "*", "bfm", bfm))
            `uvm_fatal("NOVIF", "")
        bfm.command_monitor_h = this;       // hand BFM the reverse pointer
        ap = new("ap", this);
    endfunction

    function void write_to_monitor(byte A, byte B, bit[2:0] op);
        command_s cmd;
        cmd.A = A; cmd.B = B; cmd.op = op2enum(op);
        ap.write(cmd);                      // re-publish on analysis port
    endfunction
endclass
```

The monitor here has **no `run_phase`**. The "sampling" happens in the BFM's `always` block; the monitor is just a callback target with an analysis port glued on top.

### Why Salemi uses Style B
- **Pedagogical simplification.** Students don't need to know clocking blocks or modports yet (those land in his ch.10 Sutherland material, not in his UVM Primer).
- **Procedural BFM is his teaching abstraction.** `bfm.send_op(...)` is friendlier than building a real driver/monitor pair against a pin-level interface — and observation by `always` block in the BFM matches the same procedural style.
- **Avoids the static-vs-dynamic-world handshake.** No `virtual interface` plumbing, no `clocking` mental load — the BFM just calls a function.

### Why industry uses Style A
- **Pin-level interfaces are the actual contract.** The DUT exposes signals, not procedural wrappers. Your monitor must match the silicon contract.
- **Clocking blocks prevent races.** Style B has no input-skew control — it samples on the edge, which can race the DUT's combinational outputs in mixed-language sims.
- **Decouples interface from methodology.** The same `interface` is reused by drivers, monitors, formal, and emulation. A BFM-with-callbacks ties the testbench code to the BFM's specific procedural API; you can't reuse it for emulation.
- **Scales to production.** Reverse handles (`bfm.command_monitor_h = this`) are 1:1 — you can't have two monitors observing the same BFM without rewriting the BFM. Style A's `connect()` topology is N:M out of the box.

### What you should write
| Context | Style |
|---|---|
| Salemi book homework verbatim | B (match the book) |
| The W4 ALU TB (already shipped) | hybrid — BFM with embedded `clocking_cb`, monitor sampling via vif. Closer to A. |
| W11 SPI/AXI-Lite, W12+ portfolio | **A, always.** Pin-level interface, clocking block, monitor's `forever @(vif.cb)` loop. |
| Any production / NVIDIA-tier code | **A, always.** Style B doesn't pass code review at any shop running real silicon. |

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
