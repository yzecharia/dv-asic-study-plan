# Metastability and MTBF

**Category**: CDC · **Used in**: W7 (intro), W19 (anchor — back-of-envelope numbers in `notes.md`) · **Type**: authored

Mean Time Between Failures for a synchroniser is the
question every senior asks during CDC interviews. You need to be
able to write the equation, plug in plausible numbers, and explain
what each term implies for design decisions.

## The equation

```
MTBF = e^(t_resolve / τ) / (f_clk × f_data × T_window)
```

| Term | Meaning | Typical value |
|---|---|---|
| `t_resolve` | Available settling time before next sample | ≈ 1 clock period for 2-FF, ≈ 2 for 3-FF |
| `τ` | Process recovery constant — how fast a metastable flop returns to a definite state | 20–100 ps in modern CMOS (TSMC 7nm ~30 ps; older nodes higher) |
| `f_clk` | Destination clock frequency | e.g. 1 GHz |
| `f_data` | Asynchronous data event rate | could equal source clock rate |
| `T_window` | Setup + hold sampling window where input must be stable | ≈ 50–200 ps |

## Worked example

Assume:
- 2-FF synchroniser at 1 GHz destination clock → `t_resolve ≈ 1 ns`.
- `τ = 50 ps` → `t_resolve / τ = 20`.
- `e^20 ≈ 4.85 × 10^8`.
- `f_clk × f_data × T_window = 10^9 × 10^9 × 100×10^-12 = 10^8`.

```
MTBF ≈ 4.85e8 / 1e8 = 4.85 seconds
```

That's terrifying — failures every 5 seconds. **A 2-FF synchroniser
at 1 GHz with conservative τ is not enough.** Need either a 3-FF
synchroniser (`t_resolve ≈ 2 ns` → `e^40 / 10^8` ≈ huge MTBF, ~10^9
seconds = ~30 years) or a slower destination clock for the
synchroniser stage.

## Implications for design

- **τ** is fixed by silicon. You don't get to change it.
- **t_resolve** is your lever — adding flops scales MTBF
  exponentially.
- **f_clk** and **f_data** make MTBF worse linearly. Faster clocks =
  faster CDC failures.
- **T_window** is process-fixed; smaller process node ≠ smaller
  T_window — the relationship is non-trivial.

## Verification implications

You **cannot** simulate MTBF — your TB sees infinite-precision
values, not real metastability. Instead:

1. Verify protocol correctness (handshake completes, FIFO stays
   coherent).
2. Verify CDC paths are limited to known patterns (synchroniser,
   gray-FIFO, handshake) — use a CDC tool (Cadence Conformal CDC,
   Synopsys SpyGlass CDC, or open-source Sigasi CDC).
3. Document the MTBF calc for each crossing in
   `verification_report.md`.

## Reading

- Cummings *CDC Design & Verification Techniques Using SystemVerilog*,
  SNUG-2008 — the equation derivation and worked numbers.
- For more depth: Ginosar's "Metastability and Synchronizers: A
  Tutorial" (free online, IEEE Design & Test 2011).

## Cross-links

- `[[setup_hold_metastability]]`
- `[[two_ff_synchronizer]]`
- `[[multibit_handshake_cdc]]`
