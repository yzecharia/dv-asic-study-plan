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
  scaffold.
- **Smith *Scientist & Engineer's Guide to DSP*** ([dspguide.com](https://www.dspguide.com)):
  - ch.14 — Introduction to digital filters
  - ch.15 — Moving average filters
  - ch.16 — Windowed-sinc filters

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
- [ ] Read Smith DSP ch.14–16 (online)
- [ ] Drill — impulse response
- [ ] Connector — golden-vector regression (10 signals)
- [ ] Big-picture — frequency response sanity
- [ ] Functional coverage closed
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] Read Dally ch.12 (pipelined arithmetic)
- [ ] Drill — single FIR tap
- [ ] Connector — 8-tap symmetric FIR
- [ ] Big-picture — pipelined retiming + Yosys before/after
- [ ] Iron Rule (a)/(b)/(c) ✓

### Cross-cutting

- [ ] AI task — Flashcards on FIR design parameters
- [ ] Power task — Demo video draft (FIR impulse visualisation)
- [ ] `notes.md` updated

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_17_dsp_fir/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 17 — Week 17: DSP I — 1D FIR Filter 🆕

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_17.md`](../docs/week_17.md) · ⬜ Not started

FIR filters are the entry point into hardware DSP. Once you can stream
samples through an 8-tap symmetric FIR with Q1.15 coefficients and
verify the result against `scipy.signal.lfilter`, you have the muscle
to do imaging (W18) and to discuss DSP-on-FPGA fluently in an
interview. Filters are also where pipelining decisions become real:
do you pay one extra cycle for a faster Fmax, or hold latency tight?

## Prerequisites

See [`docs/ROADMAP.md`](../docs/ROADMAP.md) §"Hard prerequisites" for
the dependency list. Refresh the relevant concept notes in
[`docs/concepts/`](../docs/concepts/) before starting.

## Estimated time split (24h total)

```
Reading        6h
Design         8h
Verification   8h
AI + Power     2h
```

(Adjust per week — UVM-heavy weeks shift hours into Verification;
RTL-heavy weeks shift into Design.)

## Portfolio value (what this week proves)

> Fill in 2–3 bullets when you start the week. The rule of thumb:
> what could you put on your CV after this week that you couldn't
> the week before?

## Iron-Rule deliverables

- [ ] **(a)** RTL committed and lint-clean.
- [ ] **(b)** Gold-TB PASS log captured to `sim/<topic>_pass.log`.
- [ ] **(c)** `verification_report.md` written.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_17.md`](../docs/week_17.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 17 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_17.md`](../docs/week_17.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 2 — Flashcards (FIR filter design parameters)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

Demo video — FIR impulse response visualisation

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 17 — Homework

The canonical homework list lives at
[`docs/week_17.md`](../docs/week_17.md). When you start
the week, port the **Drills**, **Main HWs**, and **Stretch** sections
here — but with explicit file paths, acceptance criteria, and run
commands using the `homework/` folder structure that already exists
in this repo.

## Per-chapter drills (TODO)

> Table: chapter → file path → 3-line spec → acceptance criteria.

## Connector exercise (TODO)

> Tie design + verif. Same DUT, both sides.

## Big-picture exercise (TODO)

> Mini-project within this week's scope only.

## Self-check questions (TODO)

> 5–8 questions answerable without looking. Answer keys at the
> bottom of this file once written.

## Run commands

```bash
cd week_17_*

# Native arm64 sim (Phase 1/2 default)
verilator --lint-only -Wall <rtl_file>.sv
iverilog -g2012 -o /tmp/sim <tb_file>.sv && vvp /tmp/sim

# UVM (Phase 3, when needed)
bash ../run_xsim.sh -L uvm <files>

# Yosys schematic
bash ../run_yosys_rtl.sh <rtl_file>.sv
```

> ℹ️ Auto-generated stub. Replace with concrete homework content
> when you start the week.


---

### `checklist.md`

# Week 17 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_17.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_17.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 2 — Flashcards (FIR filter design parameters)
- [ ] **Power-skill task** — Demo video — FIR impulse response visualisation
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 17 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

