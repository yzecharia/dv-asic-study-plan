# Static Timing Analysis (STA)

**Category**: Synthesis · **Used in**: W15, W19, W20 · **Type**: auto-stub

> ⚠️ **TO VERIFY**: Bhasker's *STA for Nanometer Designs* (the canonical
> reference) is **not in the local library**. This stub uses Xilinx
> UG949 / UG903 + Cummings SNUG-2008 (for the metastability angle).
> Acquire Bhasker if STA depth is needed in interview prep.

Static timing analysis verifies that every flop-to-flop path in the
design meets setup and hold timing under worst-case process,
voltage, and temperature corners. "Static" means it does not run a
simulation; it walks the netlist and checks each path's delay
against the clock period.

## Setup-time check (per path)

```
T_clk >= T_clk2q + T_logic + T_setup + T_skew(launch→capture)
```

If this is violated, you can:

- Lower the clock frequency (the simplest fix).
- Pipeline (split `T_logic` across two flops).
- Restructure logic (replace ripple adder with CLA, etc.).
- Re-place / retime (synthesis tool can move flops).

## Hold-time check

```
T_clk2q + T_logic >= T_hold + T_skew(launch→capture)
```

Hold violations don't depend on clock period. Fixing them requires
buffer insertion or re-routing.

## Reading

- Xilinx UG903, UG949 — practical SDC and timing-closure rules.
- Cummings CDC SNUG-2008 — covers async metastability paths that STA
  treats specially.
- (If acquired later) Bhasker *Static Timing Analysis for Nanometer
  Designs*.

## Cross-links

- `[[setup_hold_metastability]]`
- `[[timing_constraints_sdc]]`
- `[[ppa_tradeoffs]]`
