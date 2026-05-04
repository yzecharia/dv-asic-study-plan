# Week 16: Signed and Fixed-Point Arithmetic 🆕

> Phase 4 — Portfolio + Advanced + Career · Anchor for Yuval's
> [[concepts/signed_arithmetic]] and [[concepts/fixed_point_qformat]]
> deep dive. Preferred week to follow W15 (synthesis closure) so you
> have the toolchain warm before W17/W18 build on the qmac module.

## Why This Matters

Signed arithmetic is where junior bugs cluster (sign extension across
mixed widths, overflow flag wrong, SLT vs SLTU mistake in RV32I).
Fixed-point arithmetic — Q-format with explicit binary point, rounding
modes, saturation — is the lingua franca of DSP-on-FPGA / DSP-on-ASIC.
By the end of this week you can design a saturating MAC, write a
class-based TB whose golden reference comes from Python numpy, and
explain Q-format rounding modes in an interview without slipping
into hand-waving.

## What to Study

### Reading — Verification

- **Spear ch.6 + ch.7 refresh** — randomization with `signed`
  constraints; `solve…before` to bias rounding-boundary cases.
- **Spear ch.9 §9.1–9.6** — covergroups & cross coverage on the
  `{sign × saturation × rounding}` model.

### Reading — Design

- **Dally & Harting ch.10 — Number Systems** ⭐ — two's complement,
  signed addition with overflow detection, sign extension semantics.
- **Dally & Harting ch.11 — Multipliers** — partial products,
  Wallace/Dadda trees, Booth encoding.
- **Sutherland *RTL Modeling with SystemVerilog* — Arithmetic
  operators chapter** — synthesis behaviour of `*`, `+`, `-`,
  `signed` casts.

### Online supplements

- TI TMS320C6000 *Q-Format Application Note* — the canonical Q-format
  reference. Search "Q-format TI application note".

### Concept notes

- [[concepts/signed_arithmetic]] · [[concepts/fixed_point_qformat]]
- [[concepts/multipliers]] · [[concepts/adders_carry_chain]]

### Tool setup

Native arm64 sim (Verilator + Icarus). No UVM this week —
class-based TB is enough.

```bash
brew install verilator icarus-verilog
pip3 install numpy
```

---

## Verification Homework

### Drills (per-chapter warmups)

- **Drill 1 — Two's-complement overflow detection** (~30 lines)
  *File:* `homework/verif/per_chapter/hw_overflow_detect/overflow_tb.sv`
  Drive an N-bit signed adder TB with vectors that hit each of the 4
  overflow corners (pos+pos→neg, neg+neg→pos, plus 2 no-overflow
  controls). Assert the overflow flag matches the textbook formula
  `(a[N-1] == b[N-1]) && (sum[N-1] != a[N-1])`.

- **Drill 2 — Q-format rounding modes** (~50 lines)
  *File:* `homework/verif/per_chapter/hw_rounding_modes/round_tb.sv`
  Build a small TB that pushes hand-picked Q4.12 values through a
  reusable `round_q4_12()` SV function in three rounding modes
  (truncate, round-half-up, convergent). Compare against a Python
  numpy golden vector saved to `golden_round.hex`.

### Connector — Verification

- **HW1 — qmac UVM-lite TB** ⭐
  *Folder:* `homework/verif/connector/hw_qmac_tb/`
  Class-based TB (no UVM) for the W16 design connector (qmac). 1000
  random Q4.12 × Q4.12 multiplications; `solve…before` constraints
  to bias 10% of stimulus toward saturation boundaries. Compare
  against numpy fixed-point golden via `$readmemh`. Functional
  coverage on `{sign(a) × sign(b) × saturated × rounding_mode}`.
  Acceptance: 100% functional coverage.

### Big-picture — Verification

- **HW2 — Booth multiplier exhaustive (signed 8-bit)**
  *Folder:* `homework/verif/big_picture/hw_booth_exhaustive/`
  Stretch — only if you implemented the Booth multiplier on the
  design side. Exhaustively sweep all 256×256 = 65,536 signed-byte
  pairs. Compare against `$signed(a) * $signed(b)`.

---

## Design Homework

### Drills (per-chapter warmups)

- **Drill 1 — Signed adder with overflow flag**
  *Folder:* `homework/design/per_chapter/hw_signed_adder/`
  N-bit signed adder; output `ovf` matches the textbook formula.
  Lint-clean with `verilator --lint-only -Wall`.

- **Drill 2 — Q4.12 round-and-saturate function module**
  *Folder:* `homework/design/per_chapter/hw_round_saturate/`
  Combinational module with parameterised rounding mode (enum
  TRUNC / ROUND_UP / CONVERGENT) and saturation to Q4.12 range.

### Connector — Design

- **HW1 — `qmac` saturating MAC** ⭐
  *Folder:* `homework/design/connector/hw_qmac/`
  Synchronous Q4.12 MAC: `result_qN_n <= sat_round(acc + a*b)`. Two
  parameters (`QI=4`, `QF=12`); selectable rounding mode via input
  port. Registered output, valid/ready streaming interface (preview
  of W17). Lint-clean.

  **Spec only — do not write the solution from this doc. The Iron
  Rules require Yuval to author this RTL.**

### Big-picture — Design

- **HW2 — Booth radix-4 signed multiplier** (stretch)
  *Folder:* `homework/design/big_picture/hw_booth/`
  Combinational signed × signed multiplier using Booth radix-4
  encoding to halve the partial-product count vs naïve shift-add.
  Compare gate count via Yosys vs the W4 shift-add multiplier.

---

## Self-Check Questions

1. Why is `signed(a) + signed(b)` not the same as `unsigned(a) +
   unsigned(b)` *bit pattern*? (Trick — it is. Only the *interpretation*
   differs. Articulate why.)
2. Q4.12 × Q4.12 = Q?.?  Why?
3. Round-half-up vs convergent rounding — when does convergent win?
4. What's the worst-case error of a Q4.12 truncate-on-multiply?
5. Why does Booth radix-4 halve partial products even on signed inputs
   without a separate sign-correction step?
6. In RV32I, why is `SLT` not `SLTU` for negative comparisons?
   What's the subtle bit-level reason?

---

## Checklist

### Verification Track

- [ ] Read Spear ch.6/7 (CRV refresh) + ch.9 §9.1–9.6 (coverage)
- [ ] Drill 1 — overflow detection
- [ ] Drill 2 — Q-format rounding modes
- [ ] HW1 — qmac UVM-lite TB with numpy golden
- [ ] HW2 — Booth exhaustive (stretch)
- [ ] Functional coverage 100% on the {sign × sat × round} cross
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] Read Dally ch.10 (numbers)
- [ ] Read Dally ch.11 (multipliers)
- [ ] Read Sutherland RTL Modeling — arithmetic operators ch.
- [ ] Drill 1 — signed adder with overflow flag
- [ ] Drill 2 — Q4.12 round-and-saturate function module
- [ ] HW1 — qmac saturating MAC (the connector)
- [ ] HW2 — Booth multiplier (stretch)
- [ ] Yosys synth on qmac; capture LUT/FF/Fmax to `notes.md`
- [ ] Iron Rule (a)/(b)/(c) ✓

### Cross-cutting

- [ ] AI productivity task — Verify Q-format saturation/rounding
      semantics
- [ ] Power-skill task — LinkedIn post: fixed-point arithmetic deep
      dive
- [ ] `notes.md` updated

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_16_signed_fixed_point/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 16 — Week 16: Signed and Fixed-Point Arithmetic 🆕

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_16.md`](../docs/week_16.md) · ⬜ Not started

Signed arithmetic is where junior bugs cluster (sign extension across
mixed widths, overflow flag wrong, SLT vs SLTU mistake in RV32I).
Fixed-point arithmetic — Q-format with explicit binary point, rounding
modes, saturation — is the lingua franca of DSP-on-FPGA / DSP-on-ASIC.
By the end of this week you can design a saturating MAC, write a
class-based TB whose golden reference comes from Python numpy, and
explain Q-format rounding modes in an interview without slipping
into hand-waving.

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

Canonical syllabus: [`docs/week_16.md`](../docs/week_16.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 16 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_16.md`](../docs/week_16.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 1 — Verify (Q-format saturation/rounding semantics)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

LinkedIn post — fixed-point arithmetic deep dive

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 16 — Homework

The canonical homework list lives at
[`docs/week_16.md`](../docs/week_16.md). When you start
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
cd week_16_*

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

# Week 16 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_16.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_16.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 1 — Verify (Q-format saturation/rounding semantics)
- [ ] **Power-skill task** — LinkedIn post — fixed-point arithmetic deep dive
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 16 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

