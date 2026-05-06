# Vivado xsim Quirks — Parameterised Interfaces and Modport-Restricted Virtual Interfaces

**Category**: Toolchain / UVM · **Used in**: every UVM week using xsim (W4 HW2 anchor, W7, W12, W14, W20) · **Type**: authored

Vivado xsim 2024.1 has well-documented limitations around `parameter`ised SystemVerilog `interface`s and `virtual interface` references when used with modport restrictions. Code that compiles cleanly on Questa or Cadence Xcelium can fail elaboration on xsim with the cryptic error `'<iface>_default' is not an interface`. This note documents the limitation, the failure signature, and the two workarounds, so future-you doesn't lose an hour to it.

## The failure signature

```
ERROR: [VRFC 10-2984] '<interface_name>_default' is not an interface [<file>:<line>]
ERROR: [XSIM 43-3322] Static elaboration of top level Verilog design unit(s) in library work failed.
```

The `_default` suffix is xsim's **internal mangled name** for the unparameterised specialisation of an interface. When you write `virtual <iface>` in a class — without explicit parameter overrides — xsim creates a synthetic specialisation called `<iface>_default`. If anything goes wrong with this synthesis (parameterised interface + modport, or set/get type mismatch, or compile-order ambiguity), xelab fails to resolve the synthetic name back to the real interface and emits this error.

## Two combinations xsim breaks on

### 1. Parameterised interface + `virtual <iface>` reference

```systemverilog
// alu_if.sv
interface alu_if #(parameter int WIDTH = 8) (input logic clk, rst_n);
    logic [WIDTH-1:0] data;
    ...
endinterface

// component class (anywhere)
virtual alu_if aluif;        // ← xsim creates `alu_if_default`, fails to resolve
```

xsim treats the unparameterised reference as a request for the "default specialisation," but the underlying type-resolution stumbles on the parameter. **Even if every consumer uses the same default value, the parameter declaration alone is enough to trigger the bug.**

### 2. Modport restriction on a `virtual interface` handle

```systemverilog
virtual alu_if.tb      vif_drv;     // ← xsim 2024.1 may reject
virtual alu_if.monitor vif_mon;
```

Even with no parameters, **modport-restricted virtual interface declarations sometimes confuse xsim's elaborator**. Symptoms vary: sometimes it compiles but the `uvm_config_db::get` returns 0 silently (type-key mismatch), sometimes you see the `_default` error.

## Workaround A — drop the parameter (recommended for HW2 / single-config envs)

If your testbench only ever uses **one width / config** for the interface, drop the parameter and inline the constants. You lose theoretical reusability across widths but gain a clean compile.

```systemverilog
// alu_if.sv — no parameter, hardcoded width
interface alu_if (input logic clk, rst_n);
    logic [7:0] operand_a, operand_b;
    logic [8:0] result;
    ...
endinterface
```

Or, slightly cleaner, share the constant via a package:

```systemverilog
// alu_if.sv
interface alu_if (input logic clk, rst_n);
    localparam int WIDTH = 8;     // local to interface, no parameter override
    logic [WIDTH-1:0] data;
    ...
endinterface
```

Either form avoids the `<iface>_default` mangling because there's no parameter to specialise.

## Workaround B — drop modport restriction in `virtual` handles

Use **unrestricted** `virtual <iface>` in components, then access signals through the clocking block:

```systemverilog
// top.sv — set the unrestricted handle once
uvm_config_db #(virtual alu_if)::set(null, "*", "aluif", aluif);

// every consumer — get unrestricted, then access via clocking block
class my_driver extends uvm_component;
    virtual alu_if aluif;       // ← no .tb modport
    
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db #(virtual alu_if)::get(this, "", "aluif", aluif))
            `uvm_fatal("NOVIF", "aluif not in config_db")
    endfunction
    
    task drive_one(...);
        @(aluif.driver_cb);                       // direction protection from cb declaration
        aluif.driver_cb.operand_a <= a;
    endtask
endclass

class my_monitor extends uvm_component;
    virtual alu_if aluif;       // ← no .monitor modport
    ...
    task run_phase(uvm_phase phase);
        forever begin
            @(aluif.monitor_cb);
            ...
        end
    endtask
endclass
```

You **lose the compile-time guard** that modport restriction provides (a monitor *could* now write to `driver_cb.operand_a` if it wanted), but you gain a clean xsim compile. The clocking block's signal directions still enforce write/read at the access site (e.g. you can't read from a signal declared `output` in the cb), so it's not a free-for-all.

## Compile order matters

xsim is more sensitive than Questa to forward-references between packages and interfaces. If a package contains class files that reference `virtual <iface>`, **the interface should be compiled before the package**:

```bash
xvlog dut_if.sv         # 1. interface first — virtual references resolve to a real type
xvlog my_pkg.sv         # 2. then the package whose classes use `virtual dut_if`
xvlog dut.sv            # 3. then the DUT
xvlog top.sv            # 4. then the top
```

Reverse order (package first, then interface) sometimes works on xsim 2024.1 but is fragile. Always interface-first when in doubt.

## Trade-off table — Questa-portable vs xsim-portable

| Style | Questa | VCS | Xcelium | xsim 2024.1 |
|---|---|---|---|---|
| Parameterised interface | ✓ | ✓ | ✓ | ⚠ Triggers `_default` mangling |
| `virtual <iface>` (no modport) | ✓ | ✓ | ✓ | ✓ **Recommended for xsim** |
| `virtual <iface>.<modport>` | ✓ | ✓ | ✓ | ⚠ Sometimes fails |
| Multi-spec set/get with different modports | ✓ | ✓ | ✓ | ⚠ Often silent get failure |

If your code is meant to run on multiple simulators (e.g. Questa locally and xsim in CI), use the **most-restrictive simulator's safe pattern**. For this curriculum, that's xsim — so:

- **Always** unparameterised interface (or `localparam` inside, never `parameter`)
- **Always** unrestricted `virtual <iface>` in classes
- **Always** interface-first compile order

## Common gotchas

- **"It worked in iverilog/Questa, fails in xsim"** — most likely the `_default` issue. Check for parameters on the interface.
- **`get` returns 0 silently** — type mismatch between `set` and `get`. With xsim's modport quirks, this happens even when types *look* identical.
- **The error mentions a line in your top.sv that looks fine** — the error is in elaboration, not parsing. The line is where xsim *uses* the synthetic `_default`, not where the bug is. The actual cause is in the interface declaration or the `virtual` reference type.
- **Cleaning `xsim.dir/` doesn't fix it** — the error is from elaboration logic, not stale snapshot.

## How this differs from `[[virtual_interface_uvm]]`

`virtual_interface_uvm.md` documents the **idealised production-UVM pattern** — modport-restricted virtual interfaces, separate sets per modport, compile-time access guards. **That pattern is correct on every commercial simulator and on Verilator**. xsim 2024.1 is the outlier.

If you're writing UVM code that will run **only on xsim** (e.g. this curriculum's HW), use the workarounds above. If your code targets Questa/VCS/Xcelium **as well**, write the production pattern and accept that xsim runs need the workarounds applied locally.

## Reading

- Xilinx UG900 — Vivado Design Suite User Guide: Logic Simulation. Search for "virtual interface" and "modport limitations."
- AMD/Xilinx Answer Record AR # 76958 — UVM virtual interface limitations.
- Verification Academy forum threads on "xsim parameterised interface elaboration errors."

## Cross-links

- `[[virtual_interface_uvm]]` — the production-UVM pattern that xsim trips on; this note documents the workarounds.
- `[[uvm_factory_config_db]]` — the `uvm_config_db::set/get` mechanism whose type-matching xsim has trouble with.
- `[[uvm_run_workflow]]` — the wrapper-script workflow already adjusted for xsim.
