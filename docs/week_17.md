# Week 17: DSP I — 1D FIR Filter 🆕

> Phase 4 · Builds on W16 (qmac) + W2 (sync FIFO) + W5 (valid/ready
> streaming). Anchor for [[concepts/fir_filters]].

## Why This Matters

FIR filters are the entry point into hardware DSP. Once you can stream
samples through an 8-tap symmetric FIR with Q1.15 coefficients and
verify the result against `scipy.signal.lfilter`, you have the muscle
to do imaging (W18) and to discuss DSP-on-FPGA fluently in an
interview. Filters are also where pipelining decisions become real:
do you pay one extra cycle for a faster Fmax, or hold latency tight?

## What to Study

### Reading — Verification

- **Spear ch.9 §9.7–end** — coverage on streaming pipelines (sample
  index, value bins, edge cases).
- **Cummings SVA SNUG-2009** — assertion patterns for streaming
  ready/valid.

### Reading — Design

- **Dally & Harting ch.12 — Fast Arithmetic** — pipelined adder/multiplier
  scaffold. **TO VERIFY** which sections specifically cover pipelined
  arith vs single-cycle.
- **Smith *Scientist & Engineer's Guide to DSP*** ([dspguide.com](https://www.dspguide.com)):
  - ch.14 — Introduction to digital filters
  - ch.15 — Moving average filters
  - ch.16 — Windowed-sinc filters

  **TO VERIFY by Yuval**: confirm Smith ch.14–16 are acceptable as the
  primary DSP reference. No local DSP book covers this.

### Concept notes

- [[concepts/fir_filters]] (anchor) · [[concepts/fixed_point_qformat]]
- [[concepts/multipliers]] · [[concepts/ready_valid_handshake]]
- [[concepts/sync_fifo]]

### Tool setup

Native arm64. Add scipy:

```bash
pip3 install numpy scipy
```

---

## Verification Homework

### Drill — Impulse response check

*File:* `homework/verif/per_chapter/hw_impulse_response/impulse_tb.sv`
Drive an impulse `x[0]=1, x[1..]=0` into the W17 FIR. Read out N
samples. Assert `y[k] == h[k]` (the coefficients themselves) for
`k = 0..N-1`. Generate the golden `h.hex` from a numpy script and
load via `$readmemh`.

### Connector — golden-vector regression

*Folder:* `homework/verif/connector/hw_fir_golden/`
Generate 10 input signals (impulse, step, square wave, sine,
two-tone, white noise, ramp, dirac comb, gaussian pulse, step+sine).
Run `scipy.signal.lfilter` to produce golden output for each. TB
plays each input through the DUT and compares output sample-by-
sample with Q1.15 tolerance (~1 LSB).

Acceptance: all 10 signals PASS within tolerance.

### Big-picture — frequency response sanity

*Folder:* `homework/verif/big_picture/hw_freq_response/`
Drive 100 random sine frequencies; for each, `np.fft.fft` the DUT
output and confirm the magnitude matches the FIR's expected
frequency response (also computed via `np.fft.fft(coefficients)`).

---

## Design Homework

### Drill — single FIR tap

*Folder:* `homework/design/per_chapter/hw_fir_tap/`
Single tap: 1 multiply + 1 accumulator + 1 valid/ready FIFO slot.
Reuses W16 qmac as the multiplier. Spec only — Yuval implements.

### Connector — 8-tap symmetric FIR ⭐

*Folder:* `homework/design/connector/hw_fir_8tap_sym/`

```systemverilog
module fir_8tap_sym #(
    parameter int W = 16,
    parameter logic signed [W-1:0] H [4] = '{default: '0}
) (
    input  logic                  clk, rst_n,
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic signed [W-1:0]   in_data,
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic signed [W-1:0]   out_data
);
    // Spec only — Yuval implements:
    //  - 8-stage shift register (or two halves for symmetric pre-add)
    //  - 4 multipliers (symmetric optimisation)
    //  - tree adder
    //  - valid/ready handshake from input through output (skid buffer
    //    if pipeline > 1 stage)
endmodule
```

### Big-picture — pipelined retiming

*Folder:* `homework/design/big_picture/hw_fir_pipelined/`
Add 2 pipeline stages to the FIR. Yosys synth before/after; compare
LUT/FF/Fmax. Document trade-off in `notes.md`.

---

## Self-Check Questions

1. Why is the symmetric optimisation valid only for symmetric coefs?
2. Group delay = (N-1)/2 — derive this from the linear-phase property.
3. Q1.15 × Q1.15 = ? — and why do you need 32 bits in the accumulator
   even for an 8-tap filter?
4. What does scipy.signal.lfilter `'direct'` form II give you that
   direct form I doesn't?
5. Streaming valid/ready — what happens in your FIR when downstream
   stalls for 100 cycles mid-burst? Does the shift register keep
   shifting?

---

## Checklist

### Verification Track

- [ ] Read Spear ch.9 §9.7+ (streaming coverage)
- [ ] Read Smith DSP ch.14–16 (online) — TO VERIFY accepted
- [ ] Drill — impulse response
- [ ] Connector — golden-vector regression (10 signals)
- [ ] Big-picture — frequency response sanity
- [ ] Functional coverage closed
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] Read Dally ch.12 (pipelined arithmetic) — TO VERIFY pp.
- [ ] Drill — single FIR tap
- [ ] Connector — 8-tap symmetric FIR
- [ ] Big-picture — pipelined retiming + Yosys before/after
- [ ] Iron Rule (a)/(b)/(c) ✓

### Cross-cutting

- [ ] AI task — Flashcards on FIR design parameters
- [ ] Power task — Demo video draft (FIR impulse visualisation)
- [ ] `notes.md` updated
