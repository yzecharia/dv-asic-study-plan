# Virtual Interface in UVM (modports + clocking blocks + config_db handoff)

**Category**: UVM · **Used in**: every UVM week with a pin-level DUT (W4 HW2, W7, W11, W12, W14, W20) · **Type**: authored

When the DUT has a real pin-level interface (not just a Salemi-style wrapper BFM with embedded tasks), the testbench must navigate four interlocking SystemVerilog features at once: the **interface** itself, **modports** that restrict who can touch which signals, **clocking blocks** that prevent driver-vs-DUT races, and the **virtual interface** handle that lets dynamic-world classes reach into the static-world hardware. Salemi's UVM Primer skips this combination because his `tinyalu_bfm` is a procedural wrapper, not a pin-level interface — but every real silicon project hits all four. This note is the missing chapter.

## The four pieces and what each one solves

```
┌──────────────── interface dut_if ─────────────────┐
│                                                    │
│  raw signals: addr, data_in, data_out, valid, ...  │ ← bundles the pin list once
│                                                    │
│  ┌── clocking driver_cb @(posedge clk) ───┐       │
│  │   default input #1step output #1;         │       │ ← race-free TB-side access
│  │   output addr, data_in, valid;            │       │   (drives + samples through this)
│  │   input  data_out, ready;                 │       │
│  └────────────────────────────────────────┘       │
│                                                    │
│  ┌── clocking monitor_cb @(posedge clk) ──┐       │
│  │   default input #1step;                   │       │ ← passive read-only view
│  │   input  addr, data_in, data_out, ...;    │       │
│  └────────────────────────────────────────┘       │
│                                                    │
│  modport dut     (input ..., output ...);          │ ← view from the DUT's perspective
│  modport tb      (clocking driver_cb);             │ ← view for the driver / tester
│  modport monitor (clocking monitor_cb);            │ ← view for the monitor / scoreboard
│                                                    │
└────────────────────────────────────────────────────┘
```

| Piece | What it is | What it solves |
|---|---|---|
| **interface signals** | `logic` / `wire` declarations | bundles the pin list once; one place to change |
| **modport** | a *named view* of the signals | tells the compiler "this consumer can only read/write these signals" |
| **clocking block** | signals tied to a clock edge with input/output skew rules | prevents driver-vs-DUT race conditions on the same clock edge |
| **virtual interface** | a class-side handle to an interface instance | lets dynamic-world classes (UVM components) reach into static-world hardware |

## The static-vs-dynamic world model (revisit from `[[abstract_classes_sv]]`)

Two worlds, two lifetimes:

```
┌──────────────────────────────┐    ┌──────────────────────────────┐
│   STATIC WORLD               │    │   DYNAMIC WORLD              │
│   modules / interfaces       │    │   classes / objects           │
│                              │    │                              │
│   elaborated at compile time │    │   constructed at runtime via │
│   wired with .signal(...)    │    │   new() / factory create()   │
│                              │    │                              │
│   dut_if  vif (.clk(clk));   │    │   my_test test_h;             │
└──────────────────────────────┘    └──────────────────────────────┘
              ▲                                ▲
              │                                │ holds a "phone number" to
              └────────────────────────────────┘ the static interface
                  via   `virtual dut_if vif;`
```

A class can't directly bind to a static-world interface. The bridge is **the virtual handle**, set into `uvm_config_db` by the top module and retrieved by every component that needs it.

## The full data flow (top → config_db → component → drive/sample)

```
1. top.sv  (static world):
       dut_if vif (.clk(clk), .rst_n(rst_n));        ← real interface instance
       my_dut DUT (.dif(vif), ...);                   ← DUT wired to interface

       initial begin
           uvm_config_db#(virtual dut_if)::set(null, "*", "vif", vif);
           run_test();
       end

2. driver::build_phase  (dynamic world, configuration time):
       virtual dut_if vif;
       if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
           `uvm_fatal("NOVIF", "vif not set in config_db")

3. driver::run_phase  (dynamic world, simulation time):
       @(vif.driver_cb);                              ← align to clock edge
       vif.driver_cb.addr     <= 32'h1000;             ← drive THROUGH the clocking block
       vif.driver_cb.data_in  <= 32'hCAFE;
       vif.driver_cb.valid    <= 1'b1;
       @(vif.driver_cb iff vif.driver_cb.ready);       ← wait for handshake
       result_observed = vif.driver_cb.data_out;        ← sample THROUGH the clocking block
```

Three rules that fall out of this flow:

1. **Top sets, components get.** Always — you never `set` from inside a component (config_db is a one-way handoff).
2. **Get in `build_phase`.** UVM's phase machine guarantees all `set()`s happen before any component's `build_phase` runs (per `[[uvm_factory_config_db]]`).
3. **Drive and sample through the clocking block.** Direct `vif.signal = value` from a class is a race-condition trap — the clocking block exists to fix exactly that.

## Modports — restricting access at compile time

Modports are the compiler's way of saying "this consumer is an X-side participant; it only sees X-side signals." Defined inside the interface:

```systemverilog
modport tb      (clocking driver_cb);            // driver / tester — can only use driver_cb
modport monitor (clocking monitor_cb);           // monitor — read-only view
modport dut     (input ..., output ...);         // DUT side — directly drives outputs, reads inputs
```

Used in classes by appending the modport name to `virtual <if_name>`:

```systemverilog
class my_driver extends uvm_driver;
    virtual dut_if.tb       vif;     // restricted to driver_cb only
endclass

class my_monitor extends uvm_monitor;
    virtual dut_if.monitor  vif;     // restricted to monitor_cb (read-only)
endclass
```

If the monitor accidentally tries to drive a signal:

```systemverilog
vif.monitor_cb.valid <= 1'b1;  // compile error: monitor_cb has no output declaration for valid
```

The compile-time check is the win — production envs always use modport-restricted handles. **Don't store unrestricted `virtual dut_if` in production code if a modport view exists.**

## Clocking blocks — what they actually solve

Without a clocking block, both DUT and TB drive on `posedge clk`. They race in the simulator's event-scheduling order, and the result depends on which side is scheduled first. Symptom: **"the test passes 9 out of 10 runs."** Classic non-determinism.

The clocking block fixes this with **input and output skew**:

```systemverilog
clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output addr, data_in, valid;
    input  data_out, ready;
endclocking
```

What the skews mean:

| Direction | Skew | Effect |
|---|---|---|
| `output #1` | TB's writes happen **1 time-unit after** `posedge clk` | DUT samples its inputs cleanly **before** TB updates them |
| `input #1step` | TB's reads happen **1 step before** `posedge clk` | TB reads the value **just before** DUT changes it |

Practical consequence: every TB-side signal access becomes deterministic. **Always drive and sample through the clocking block from a class.** Bare `vif.signal = value` is only OK from inside the DUT module itself.

## The set / get type-matching gotcha

`uvm_config_db` is keyed by `(scope, field_name)` **and parameterised by the type**. The type must match exactly — otherwise the get returns 0 silently.

This means `set` of `virtual dut_if` and `get` of `virtual dut_if.tb` **don't match**. Two ways to handle:

| Option | What top sets | What components get | Trade-off |
|---|---|---|---|
| **A** (recommended) | `set#(virtual dut_if)::(...)` — no modport | `get#(virtual dut_if)::(...)`, then access via `vif.driver_cb.signal` | one set, modports applied at use site (still compile-checked at the use site since the clocking block has its own direction declarations) |
| **B** | `set` separately for each modport: `virtual dut_if.tb`, `virtual dut_if.monitor`, ... | each component gets its specific modport-typed handle | stronger compile-time check on the handle itself, but more boilerplate |

**Default to Option A.** The clocking block already enforces direction at the access site, so you get the same protection without duplicating sets.

## Common gotchas

- **`get` returns 0 silently.** Always wrap in `if (!uvm_config_db#(...)::get(...)) `uvm_fatal(...)`. Using a null vif is a runtime crash with a confusing trace.
- **Type mismatch between set and get.** If top sets `virtual dut_if` and component gets `virtual dut_if.tb`, the lookup fails. See Option A above.
- **Driving without a clocking block.** Race against the DUT. Don't.
- **Component declares `dut_if vif;` instead of `virtual dut_if vif;`.** Compile error — classes can't hold a non-virtual interface (static vs dynamic world).
- **Sampling immediately after driving.** `vif.driver_cb.signal = X; observed = vif.driver_cb.signal;` won't see the new value the same cycle — clocking block writes happen *after* the edge. Use `@(vif.driver_cb);` to advance one clock first.
- **Clocking block direction confusion.** Inside `clocking driver_cb`, `output` means "TB drives this signal" — i.e. signals the TB outputs *to the DUT*. From the DUT's perspective those are inputs. Always read clocking blocks from the **TB side's** point of view.
- **Monitor accidentally drives.** Caught at compile time *only if* the monitor uses `virtual dut_if.monitor` and the monitor_cb has no `output` declarations. Use modport restriction, not just clocking-block discipline.
- **Storing the vif at module scope inside a class.** Always class member, retrieved in `build_phase`. Never declare it as a global at package scope.

## Concrete skeleton (drop-in template)

```systemverilog
// dut_if.sv
interface dut_if #(parameter int AW = 32, DW = 32) (input logic clk, input logic rst_n);
    logic [AW-1:0] addr;
    logic [DW-1:0] data_in, data_out;
    logic          valid, ready;

    clocking driver_cb @(posedge clk);
        default input #1step output #1;
        output addr, data_in, valid;
        input  data_out, ready;
    endclocking

    clocking monitor_cb @(posedge clk);
        default input #1step;
        input  addr, data_in, data_out, valid, ready;
    endclocking

    modport dut     (input  addr, data_in, valid, output data_out, ready, input clk, rst_n);
    modport tb      (clocking driver_cb,  input clk, rst_n);
    modport monitor (clocking monitor_cb, input clk, rst_n);
endinterface : dut_if
```

```systemverilog
// top.sv
module top;
    import my_pkg::*;
    `include "uvm_macros.svh"

    bit clk = 0;  always #5 clk = ~clk;
    bit rst_n = 0; initial begin #20 rst_n = 1; end

    dut_if  vif (.clk(clk), .rst_n(rst_n));
    my_dut  DUT (.dif(vif), ...);

    initial begin
        uvm_config_db#(virtual dut_if)::set(null, "*", "vif", vif);
        run_test();
    end
endmodule
```

```systemverilog
// my_driver.svh — inside the package
class my_driver extends uvm_driver;
    `uvm_component_utils(my_driver)
    virtual dut_if vif;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "vif not set in config_db")
    endfunction

    task drive_one(int unsigned addr_v, int unsigned data_v);
        @(vif.driver_cb);
        vif.driver_cb.addr    <= addr_v;
        vif.driver_cb.data_in <= data_v;
        vif.driver_cb.valid   <= 1'b1;
        @(vif.driver_cb iff vif.driver_cb.ready);
        vif.driver_cb.valid   <= 1'b0;
    endtask
endclass
```

```systemverilog
// my_monitor.svh — inside the package
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)
    virtual dut_if vif;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "vif not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.valid && vif.monitor_cb.ready) begin
                // build txn from vif.monitor_cb.* and publish (or check directly)
            end
        end
    endtask
endclass
```

## Reading

- IEEE 1800-2017 §25 — interfaces and modports.
- IEEE 1800-2017 §14 — clocking blocks.
- Sutherland *SystemVerilog for Design* (2e) ch.10 — interfaces, modports, clocking.
- Spear *SystemVerilog for Verification* (3e) ch.4 — clocking blocks and virtual interfaces in TB context.
- Verification Academy — virtual interfaces cookbook entry: https://verificationacademy.com/cookbook/uvm/uvm_virtual_interface

## Cross-links

- `[[interfaces_modports]]` — the prerequisite "what is an interface and a modport" note.
- `[[uvm_factory_config_db]]` — the `uvm_config_db::set/get` mechanism this note relies on.
- `[[uvm_driver]]` · `[[uvm_monitor]]` — the canonical consumers of a vif.
- `[[abstract_classes_sv]]` — the static-vs-dynamic world distinction at the heart of why `virtual` is needed.
- `[[bfm_pattern]]` — Salemi's procedural-BFM alternative (no pin-level interface, no modports, no clocking blocks).
- `[[clocking_resets]]` — deeper detail on clocking block skew semantics.
- `[[ready_valid_handshake]]` — the protocol shape `drive_one` typically wraps.
