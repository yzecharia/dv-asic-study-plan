# Setup, Hold, and Metastability

**Category**: Sequential · **Used in**: W7, W19 (anchor) · **Type**: authored

Three timing concepts that every senior assumes you understand
intuitively.

## Setup time

The minimum interval before the active clock edge during which the D
input must be stable for the flop to capture it correctly. Violating
setup means the launching path was too slow; you fix it by lowering
clock frequency, optimising the critical path, or adding a pipeline
stage.

## Hold time

The minimum interval **after** the active clock edge during which D
must remain stable. Violating hold means the launching path was too
fast (a "race"); you cannot fix it by slowing the clock. Fixes are
buffer insertion, layout-aware routing, or design-time clock skew
adjustment. This is why hold violations are scary — they survive
clock-frequency reduction.

## Metastability

If a flop's D input changes within the setup/hold window (commonly,
because D came from another clock domain), the flop's output may
linger between `0` and `1` for an unbounded time before resolving.
The probability of resolving in any given clock period is governed
by the **MTBF** equation:

```
MTBF = e^(t_resolve / τ) / (f_clk × f_data × T_window)
```

where:
- `t_resolve` = time available for the metastable signal to settle
- `τ` = process-dependent recovery constant (~tens of ps)
- `f_clk`, `f_data` = clock and asynchronous-data frequencies
- `T_window` = setup+hold window where the input is sampled

## Why a 2-FF synchroniser

A single flop on the receiving side has poor MTBF for typical
process and frequency points. Adding a second flop in series gives
a full clock period of `t_resolve` for the first flop's output to
settle before the second samples it. For most CMOS processes at
modern frequencies, 2 flops give MTBF of millions of years.

```systemverilog
always_ff @(posedge dst_clk) begin
    sync_meta <= async_in;       // first flop — may be metastable
    sync_q    <= sync_meta;      // second flop — clean, with high MTBF
end
```

## When 2 FFs are not enough

- Very high frequency targets (>1 GHz) — may need 3 FFs.
- Multi-bit data — 2-FF on each bit can desynchronise. Use a gray-
  code crossing (`[[gray_code_pointers]]`) or a handshake
  (`[[multibit_handshake_cdc]]`).

## Reading

- Cummings *Clock Domain Crossing (CDC) Design & Verification
  Techniques Using SystemVerilog*, SNUG-2008 — the canonical paper.
- Harris & Harris ch.3 §3.5, pp. 154–166.

## Cross-links

- `[[two_ff_synchronizer]]` — the simplest CDC pattern.
- `[[metastability_mtbf]]` — the math in more depth.
- `[[clocking_resets]]` — reset is also a CDC problem.
