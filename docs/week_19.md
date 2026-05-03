# Week 19: Advanced CDC & Multi-Bit Handshake 🆕

> Phase 4 · Builds on W7 (basic CDC) + W3 (SVA). Anchor for
> [[concepts/multibit_handshake_cdc]] and
> [[concepts/metastability_mtbf]].

## Why This Matters

Every modern SoC crosses clock domains, and CDC bugs survive RTL
simulation that doesn't model metastability. NVIDIA-tier interviewers
expect you to write the MTBF equation, derive its sensitivity to
each parameter, and know when 2-FF synchroniser is enough vs when
gray-code or handshake is required. This week ties the math, the
RTL idioms, and the SVA together.

## What to Study

### Reading — Verification

- **Cummings SVA SNUG-2009** — bind-file pattern + SVA bundles for
  handshakes (already in `cheatsheets/` references).
- **IEEE 1800-2017 §16** — concurrent assertions reference.

### Reading — Design

- **Cummings *CDC Design & Verification Techniques Using SystemVerilog***
  — SNUG-2008. **TO VERIFY**: confirm PDF is local; if not, fetch
  from cummings.com.
- **Sutherland *SystemVerilog for Design* — Clocking blocks chapter**
  (relevant for TB-side CDC).
- **Dally & Harting ch.28 — Synchronous to Asynchronous**: thin
  treatment but has the metastability picture.

### Concept notes

- [[concepts/metastability_mtbf]] (anchor) ·
  [[concepts/multibit_handshake_cdc]] (anchor)
- [[concepts/two_ff_synchronizer]] · [[concepts/gray_code_pointers]]
- [[concepts/clocking_resets]] · [[concepts/sva_assertions]]

### Tool setup

Native arm64 + Vivado Docker fallback for any UVM-style sequence.
For deeper CDC tooling: SymbiYosys (open-source formal) is overkill
this week; use targeted SVA + multi-clock TB instead.

---

## Verification Homework

### Drill — 2-FF synchroniser SVA bundle

*File:* `homework/verif/per_chapter/hw_2ff_sva/sync_sva.sv`
Three assertions on a 2-FF synchroniser block:
- Output stable for ≥1 cycle after first sample.
- No glitches in steady state.
- Reset propagates within 2 cycles.

### Drill — pulse synchroniser

*File:* `homework/verif/per_chapter/hw_pulse_sync/pulse_tb.sv`
Verify the W7 pulse synchroniser: every input pulse on `clk_a`
produces exactly one output pulse on `clk_b`. SVA covers
"pulse propagated" + "no spurious pulse".

### Connector — req/ack handshake exhaustive

*Folder:* `homework/verif/connector/hw_handshake_4phase/`
Drive a 4-phase req/ack handshake at clock ratios 1:1, 2:1, 5:1,
1:2, 1:5. SVA bundle:
- `req` rises before `ack` rises.
- `ack` rises before `req` falls.
- `req` falls before `ack` falls.
- Data on the bus is stable from `req` rise until `ack` fall.

Coverage on `(clock_ratio × req_width × ack_latency)`.

### Big-picture — MTBF write-up

*File:* `notes.md` (this week's notes)
Compute MTBF for three scenarios using the equation in
[[concepts/metastability_mtbf]]:
- 2-FF sync at 1 GHz, τ=50 ps, T_window=100 ps.
- Same with 3-FF sync.
- Same with 2-FF sync at 100 MHz.

Document each in `notes.md` with the substitutions and
implications.

---

## Design Homework

### Drill — 4-phase handshake module

*Folder:* `homework/design/per_chapter/hw_handshake/`
Two clock domains, single multi-bit data bus, req/ack signals
synchronised both directions.

### Drill — pulse stretcher

*Folder:* `homework/design/per_chapter/hw_pulse_stretcher/`
Single-cycle pulse on `clk_a` → multi-cycle pulse on `clk_b` (slower
domain), guaranteed wide enough to be sampled.

### Connector — multi-ratio async FIFO bank ⭐

*Folder:* `homework/design/connector/hw_async_fifo_multi/`
Two async FIFOs:
- 100 MHz ↔ 33 MHz (slow consumer)
- 100 MHz ↔ 250 MHz (fast consumer)

Both built on the W7 async FIFO RTL (or a refactored shared
implementation). Verify with multi-clock TB driving bursty writes.

### Big-picture — glitch-free clock multiplexer

*Folder:* `homework/design/big_picture/hw_clock_mux/`
Stretch — design a glitch-free clock mux (always select the new
clock only after both old and new clocks have a low edge). SVA
bundle proving no clock pulse is shorter than min(period_a/2,
period_b/2).

---

## Self-Check Questions

1. Why is a 2-FF synchroniser sufficient for single-bit CDC but
   wrong for multi-bit?
2. Derive: MTBF doubling when you add a third synchroniser flop —
   why is the improvement *exponential* in the number of flops?
3. What does "async-assert / sync-deassert" reset achieve? What
   would happen if you used pure sync reset across two clock
   domains?
4. In a 4-phase handshake, what determines max throughput? How
   would you go to 2-phase for higher throughput, and what's the
   cost?
5. Gray-code FIFO pointer — exactly which bit operations are needed
   to compare full/empty when the pointers live in different
   domains?

---

## Checklist

### Verification Track

- [ ] Read Cummings CDC SNUG-2008 (TO VERIFY local)
- [ ] Read Cummings SVA SNUG-2009 (refresh)
- [ ] Drill — 2-FF SVA bundle
- [ ] Drill — pulse synchroniser
- [ ] Connector — 4-phase handshake exhaustive (5 ratios)
- [ ] Big-picture — MTBF computation in `notes.md`
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] Drill — 4-phase handshake module
- [ ] Drill — pulse stretcher
- [ ] Connector — multi-ratio async FIFO bank (3 ratios)
- [ ] Big-picture — glitch-free clock mux (stretch)
- [ ] Iron Rule (a)/(b)/(c) ✓

### Cross-cutting

- [ ] AI task — RTL style review on your CDC handshake RTL
- [ ] Power task — Mock interview #2 (CDC depth, 40 min self-mock)
- [ ] `notes.md` updated with MTBF write-up

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_19_advanced_cdc/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 19 — Week 19: Advanced CDC & Multi-Bit Handshake 🆕

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_19.md`](../docs/week_19.md) · ⬜ Not started

Every modern SoC crosses clock domains, and CDC bugs survive RTL
simulation that doesn't model metastability. NVIDIA-tier interviewers
expect you to write the MTBF equation, derive its sensitivity to
each parameter, and know when 2-FF synchroniser is enough vs when
gray-code or handshake is required. This week ties the math, the
RTL idioms, and the SVA together.

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

Canonical syllabus: [`docs/week_19.md`](../docs/week_19.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 19 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_19.md`](../docs/week_19.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 3 — RTL style review (your CDC handshake RTL)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

Mock interview #2 — CDC depth (40 min self-mock)

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 19 — Homework

The canonical homework list lives at
[`docs/week_19.md`](../docs/week_19.md). When you start
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
cd week_19_*

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

# Week 19 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_19.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_19.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 3 — RTL style review (your CDC handshake RTL)
- [ ] **Power-skill task** — Mock interview #2 — CDC depth (40 min self-mock)
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 19 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

