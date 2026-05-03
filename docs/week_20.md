# Week 20: Capstone — RAL + Multi-UVC + System 🆕

> Phase 4 · Graduation. Pulls W12 (UART-UVM), W13 (FIFO-UVM, RISC-V),
> W14 (RAL hand-write), W15 (synth flow), W19 (CDC bridge) into one
> top-level SoC-lite repo.

## Why This Matters

This is the project a recruiter from NVIDIA / Apple / AMD will spend
30 seconds on. It must demonstrate, in one repo:
- A multi-UVC UVM environment.
- A RAL model that's *generated* (not hand-typed) from a
  human-readable register description — production-realistic.
- A virtual sequencer coordinating across UVCs.
- A synthesis report (Yosys + nextpnr or Vivado Docker).
- Self-aware verification (`verification_report.md` with what didn't
  work and what you'd change next).

End-to-end, on your GitHub, with a 5-minute demo video script.

## What to Study

### Reading — Verification

- **Rosenberg & Meade *Practical UVM* — RAL chapter**. **TO VERIFY**
  exact chapter number (referenced from W14 too).
- **UVM Cookbook — RAL section** ([verificationacademy.com/cookbook/registers](https://verificationacademy.com/cookbook/registers))
  — adapter patterns, frontdoor vs backdoor.
- **Rosenberg ch. on multi-UVC environments** — virtual sequencer
  patterns.

### Reading — Design

- **ARM AMBA AXI specification (IHI0022E)** — refresh for the
  AXI-Lite slave on the reg block.
- **Yosys + nextpnr manuals** for the open-source synth path on the
  W17 FIR / W12 UART cores.

### Concept notes

- [[concepts/uvm_ral]] (anchor) · [[concepts/uvm_sequences_sequencers]]
- [[concepts/axi_lite]] · [[concepts/multibit_handshake_cdc]]
- [[concepts/synthesis_basics]] · [[concepts/ppa_tradeoffs]]

### Tool setup

```bash
# RAL auto-generation: Python + PyYAML
pip3 install pyyaml jinja2

# Open-source synthesis flow (already installed)
brew install yosys nextpnr-ice40

# UVM via Vivado Docker for the multi-UVC run
bash run_xsim.sh -L uvm <files>
```

---

## DUT (top-level SoC-lite)

```
                ┌──────────────────────────────────┐
                │  AXI-Lite Slave (reg block, 8 regs)│
                │   • CTRL, STAT, BAUD, DATA_TX,    │
                │     DATA_RX, IRQ_EN, IRQ_STAT,    │
                │     SCRATCH                        │
                └─────────┬───────────┬─────────────┘
                          │           │
                  CDC bridge (W19)    │
                  100 MHz ↔ 50 MHz    │
                          │           │
                ┌─────────┴────┐  ┌───┴────────────┐
                │ UART (W12)   │  │ FIFO (W13)     │
                └──────────────┘  └────────────────┘
```

Spec only — Yuval implements + integrates per Iron Rule.

---

## Verification Homework

### HW1 — RAL auto-gen pipeline

*Folder:* `homework/verif/connector/hw_ral_autogen/`

`reg_block.yaml` defines the 8 registers human-readably. A Python
script `gen_ral.py` (using Jinja2) emits `reg_block_pkg.sv`
containing `uvm_reg`, `uvm_reg_field`, and `uvm_reg_block` classes
matching `[[concepts/uvm_ral]]`. The generator is a portfolio
artifact in itself.

### HW2 — AXI-Lite UVC + UART UVC + virtual sequencer

*Folder:* `homework/verif/connector/hw_multiuvc_env/`

Full UVM env:
- AXI-Lite UVC (driver + monitor + agent + analysis port)
- UART UVC (reuses W12 verified UVC)
- Virtual sequencer holding handles to both
- Scoreboard cross-checking RAL writes propagate to UART config

### HW3 — Capstone regression

*Folder:* `homework/verif/big_picture/hw_capstone_regression/`

Five orchestrated scenarios run from the virtual sequencer:
1. Configure baud via AXI register → TX a payload → check UART
   line.
2. Same in reverse for RX.
3. Concurrent FIFO push/pull while UART traffic happens.
4. CDC bridge stress: AXI bursts at 100 MHz vs UART at 50 MHz.
5. Reset mid-traffic; verify clean recovery.

Coverage closure target: 100% on the cross-DUT functional model.

---

## Design Homework

### HW1 — Reg block AXI-Lite slave

*Folder:* `homework/design/connector/hw_reg_block/`
8-register AXI-Lite slave with read/write FSM. Spec from RAL YAML.

### HW2 — Top-level integration

*Folder:* `homework/design/connector/hw_soc_lite_top/`
Wire UART (W12), FIFO (W13), reg block (HW1 above), CDC bridge
(W19) into one top module. Two clocks: 100 MHz primary, 50 MHz
peripheral.

### HW3 — Synthesis report

*Folder:* `homework/design/big_picture/hw_synth_report/`
Yosys + nextpnr on the SoC-lite top (or on individual cores if
nextpnr can't fit the whole thing on iCE40 HX8K). Capture LUT/FF/
Fmax in `synth_report.md`. Stretch: timing-driven retiming pass.

---

## Self-Check Questions

1. Walk through the cycle-by-cycle sequence when the AXI-Lite UVC
   writes to the BAUD register and the UART starts transmitting.
2. RAL backdoor write to BAUD vs frontdoor — what's different
   downstream in the UART FSM?
3. Virtual sequencer sequence vs running sequences in parallel via
   `fork-join` directly — what does the virtual sequencer give you?
4. Synth report shows critical path through the CDC bridge. Walk
   through how to interpret it and what to consider before
   "fixing" it.
5. If you had to ship this to NVIDIA tomorrow, what would you tell
   the senior engineer is *not done*?

---

## Checklist

### Verification Track

- [ ] Read Rosenberg RAL chapter (TO VERIFY ch. number)
- [ ] Read UVM Cookbook RAL section
- [ ] HW1 — RAL auto-gen pipeline (YAML → SV)
- [ ] HW2 — Multi-UVC env with virtual sequencer
- [ ] HW3 — 5-scenario capstone regression
- [ ] Coverage closure 100%
- [ ] Iron Rule (a)/(b)/(c) ✓

### Design Track

- [ ] HW1 — Reg block AXI-Lite slave
- [ ] HW2 — SoC-lite top integration
- [ ] HW3 — Synthesis report (Yosys + nextpnr)
- [ ] `synth_report.md` published
- [ ] Iron Rule (a)/(b)/(c) ✓

### Capstone deliverables (your portfolio)

- [ ] `PORTFOLIO.md` updated with capstone link + summary
- [ ] 5-minute demo video script written (and ideally recorded)
- [ ] `verification_report.md` with self-critique paragraph
- [ ] GitHub repo for the capstone published
- [ ] LinkedIn announcement post (Power-skill task)
- [ ] "Open to opportunities" toggle ON on LinkedIn

### Cross-cutting

- [ ] AI task — Interview Qs covering capstone walk-through
- [ ] Power task — Mock interview #3, full portfolio walk-through
- [ ] `notes.md` final retrospective entry across all 20 weeks

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_20_capstone_multiuvc_ral/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 20 — Week 20: Capstone — RAL + Multi-UVC + System 🆕

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_20.md`](../docs/week_20.md) · ⬜ Not started

This is the project a recruiter from NVIDIA / Apple / AMD will spend
30 seconds on. It must demonstrate, in one repo:
- A multi-UVC UVM environment.
- A RAL model that's *generated* (not hand-typed) from a
  human-readable register description — production-realistic.
- A virtual sequencer coordinating across UVCs.
- A synthesis report (Yosys + nextpnr or Vivado Docker).
- Self-aware verification (`verification_report.md` with what didn't
  work and what you'd change next).

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

Canonical syllabus: [`docs/week_20.md`](../docs/week_20.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 20 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_20.md`](../docs/week_20.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 4 — Interview Qs (capstone walkthrough — every layer)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

Final About refresh + 'Open to opportunities' toggle on; mock #3 full portfolio

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 20 — Homework

The canonical homework list lives at
[`docs/week_20.md`](../docs/week_20.md). When you start
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
cd week_20_*

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

# Week 20 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_20.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_20.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 4 — Interview Qs (capstone walkthrough — every layer)
- [ ] **Power-skill task** — Final About refresh + 'Open to opportunities' toggle on; mock #3 full portfolio
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 20 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

