# Timing Constraints — SDC and `.xdc`

**Category**: Synthesis · **Used in**: W15, W20 · **Type**: authored

Without timing constraints, synthesis has no idea what your design
is supposed to run at. The constraint file tells the tool: clock
periods, false paths, multi-cycle paths, I/O delays. SDC (Synopsys
Design Constraints) is the format; Xilinx `.xdc` is a subset.

## Minimum constraints for any design

```tcl
# 100 MHz clock, 50/50 duty
create_clock -name clk -period 10.0 [get_ports clk]

# Async reset — exclude from timing analysis to that pin
set_false_path -from [get_ports rst_n]
```

For multi-clock designs, declare each clock and tell the tool which
pairs are asynchronous to each other:

```tcl
create_clock -name clk_a -period 10.0 [get_ports clk_a]
create_clock -name clk_b -period 30.0 [get_ports clk_b]   # 33 MHz
set_clock_groups -asynchronous \
    -group [get_clocks clk_a] \
    -group [get_clocks clk_b]
```

## False paths

Paths that exist topologically but never actually run at the clock
rate. Don't analyse them for timing.

```tcl
# CDC handshake — req synchroniser path is not single-cycle
set_false_path -from [get_pins handshake/req_a_reg/Q] \
               -to   [get_pins handshake/req_b_meta_reg/D]
```

Be careful: every `set_false_path` is a promise. If you mis-mark a
path that actually does need to be timed, you ship silicon with
metastability or hold violations.

## Multi-cycle paths

Path that takes >1 cycle to settle but is sampled less often than
every cycle. Common in slow finite-state machines or debug paths.

```tcl
set_multicycle_path 2 -setup -from [get_pins state_reg/Q] -to [get_pins out_reg/D]
set_multicycle_path 1 -hold  -from [get_pins state_reg/Q] -to [get_pins out_reg/D]
```

The hold rule is the gotcha — multi-cycle setup must be paired with
a hold adjustment or you get spurious hold violations.

## I/O delays

For external interfaces, the tool needs to know how much delay is on
the board between the FPGA pin and whatever it talks to.

```tcl
set_input_delay  -clock clk -max 3.0 [get_ports din]
set_input_delay  -clock clk -min 0.5 [get_ports din]
set_output_delay -clock clk -max 2.0 [get_ports dout]
```

These numbers come from the connected device's datasheet plus a board
trace estimate.

## Reading the report

After synthesis, read the timing report top-down: WNS (worst
negative slack), TNS (total negative slack), per-path lists. The
critical path is the one with WNS; that's where you focus.

| Symptom | Likely fix |
|---|---|
| Setup violation, big slack negative | pipeline stage; restructure logic; raise clock period |
| Hold violation | buffer insertion (tool-level fix); check skew |
| WNS is fine, but design fails on board | check `.xdc` covers all I/O; check clock constraints reflect actual board |

## Reading

- Xilinx *UltraFast Design Methodology* (UG949) — SDC/XDC patterns.
- Xilinx UG903 — *Using Constraints* — the canonical Xilinx reference.
- Synopsys SDC manual (Verification Academy hosts excerpts).

## Cross-links

- `[[static_timing_analysis]]` — what the constraints feed into.
- `[[synthesis_basics]]`
- `[[ppa_tradeoffs]]`
