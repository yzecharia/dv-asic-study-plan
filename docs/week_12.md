# Week 12: Portfolio Project #1 — UART with Full UVM Testbench

## Why This Matters

This is your first GitHub portfolio piece. It demonstrates: RTL
design (W10), UVM verification (W4-W6), coverage-driven
methodology, and professional documentation. This is what hiring
managers click on first.

The DUT is the W10 UART; the TB is built top-to-bottom in UVM
using the components and patterns Salemi taught in ch.20-23 and
Rosenberg structures in ch.4-9.

## What to Study

### Reading — Verification

- **Salemi *UVM Primer*** — refresher on what you've already
  built up:
  - **ch.20-23** ⭐ — transactions, agents, sequences (your W6
    material).
  - **ch.24** — final wrap-up / patterns.
- **Rosenberg & Meade *A Practical Guide to Adopting the UVM*
  (2nd ed)**:
  - **ch.4-5** ⭐ — sequences, sequence libraries, virtual
    sequences. More structured treatment than Salemi.
  - **ch.6** — driver/sequencer pattern.
  - **ch.8** — scoreboards (reference-model + comparator
    architecture).
  - **ch.9** — stimulus generation patterns.
  - **ch.10** — reporting, end-of-test, drain time.
- **Spear & Tumbush ch.9 — Functional Coverage**: covergroups
  inside the UVM coverage component.
- **Verification Academy** UVM Cookbook — *Sequences*,
  *Scoreboards*, *Coverage* chapters.

### Tool Setup

- xsim with `-L uvm` (same as W4-W6).
- `+UVM_TESTNAME=...` to pick a test.

---

## Verification Homework

### Drills (per-component warmups)

> Each drill is a small standalone build of one UVM component for
> the UART. Code it, simulate it on its own with a stub interface,
> then drop into the main UVM env in HW1.

- **Drill — `uart_seq_item` (Salemi ch.21)**
  *File:* `homework/verif/per_chapter/hw_uart_seq_item/uart_item.sv`
  ```systemverilog
  class uart_seq_item extends uvm_sequence_item;
      `uvm_object_utils(uart_seq_item)
      rand bit [7:0]    data;
      rand int unsigned delay_cycles;
      rand bit          inject_framing_error;
      constraint c_delay { delay_cycles inside {[0:100]}; }
      constraint c_err   { inject_framing_error dist {0:=95, 1:=5}; }
      // implement do_copy, do_compare, convert2string per Salemi ch.20
  endclass
  ```

- **Drill — `uart_driver` (Salemi ch.23, Rosenberg ch.6)**
  *File:* `homework/verif/per_chapter/hw_uart_driver/uart_driver.sv`
  Extends `uvm_driver #(uart_seq_item)`. `run_phase`:
  `forever begin seq_item_port.get_next_item(item); drive_tx(item);
  seq_item_port.item_done(); end`. `drive_tx` pulses `tx_start`,
  loads `tx_data`, waits for `tx_done`.

- **Drill — `uart_monitor` (Salemi ch.16, ch.22)**
  *File:* `homework/verif/per_chapter/hw_uart_monitor/uart_monitor.sv`
  Two analysis ports: `tx_ap` (samples `tx_data` when `tx_start`
  fires) and `rx_ap` (samples `rx_data` when `rx_valid` pulses).
  Both write `uart_seq_item`s.

- **Drill — `uart_scoreboard` (Salemi ch.16, Rosenberg ch.8)**
  *File:* `homework/verif/per_chapter/hw_uart_scoreboard/uart_scb.sv`
  Two `uvm_subscriber`s (one per analysis port). On TX write,
  push to a `uart_seq_item q[$]` queue. On RX write, pop the
  oldest TX item and `compare()`.

- **Drill — `uart_coverage` (Spear ch.9)**
  *File:* `homework/verif/per_chapter/hw_uart_coverage/uart_cov.sv`
  `uvm_subscriber` of TX transactions. Covergroup with bins:
  every byte value (256 bins), `inject_framing_error` toggle,
  `delay_cycles` ranges.

- **Drill — `uart_agent` (Salemi ch.22)**
  *File:* `homework/verif/per_chapter/hw_uart_agent/uart_agent.sv`
  Active or passive (config object with `is_active`). Active:
  builds sequencer + driver + monitor. Passive: monitor only.
  Exposes `tx_ap`, `rx_ap` upward.

- **Drill — `uart_random_seq` (Salemi ch.23, Rosenberg ch.4-5)**
  *File:* `homework/verif/per_chapter/hw_uart_random_seq/uart_seq.sv`
  ```systemverilog
  class uart_random_seq extends uvm_sequence #(uart_seq_item);
      rand int unsigned n_items;
      constraint c_n { n_items inside {[10:1000]}; }
      task body();
          repeat (n_items) `uvm_do(req)
      endtask
  endclass
  ```

### Main HWs

#### HW1: Build the full UART UVM environment
*Folder:* `homework/verif/connector/hw1_uart_uvm_env/`

Project layout (this is the layout you'll push to GitHub):
```
uart-uvm-verification/
    rtl/        ← copy from W10 (uart_top, tx, rx, baud_gen)
    tb/
        uart_pkg.sv
        uart_if.sv         ← from W10 DHW (Sutherland ch.10)
        uart_seq_item.sv   ← drill
        uart_driver.sv     ← drill
        uart_monitor.sv    ← drill
        uart_agent.sv      ← drill
        uart_scoreboard.sv ← drill
        uart_coverage.sv   ← drill
        uart_env.sv
        uart_base_test.sv
        uart_tests.sv
        uart_sequences.sv
        tb_top.sv
    sim/Makefile
    docs/architecture.png
    README.md
```

Wire it all up in `uart_env`. Five sequences:
- `uart_single_byte_seq` — directed.
- `uart_random_seq` — N random bytes.
- `uart_all_bytes_seq` — walks 0x00..0xFF.
- `uart_stress_seq` — back-to-back, 0 delay.
- `uart_error_seq` — `inject_framing_error = 1`.

Five tests (all extend `uart_base_test`):
- `uart_directed_test`, `uart_random_test`, `uart_coverage_test`,
  `uart_stress_test`, `uart_error_test`.

#### HW2: Regression + coverage closure
*Folder:* `homework/verif/connector/hw2_regression/`

Regression script that runs all 5 tests sequentially and prints a
pass/fail/coverage table. If coverage < 100%:
- Identify uncovered bins.
- Add a directed sequence targeting that bin.
- Rerun until coverage = 100%.

#### HW3: README + architecture diagram
*Folder:* `homework/verif/connector/hw3_readme/`

Professional README per the template in this file's appendix.
Block diagram of the UVM testbench (PNG or ASCII), instruction
table, "how to run" section, results table.

#### HW4: Push to GitHub
Initialize a new repo `uart-uvm-verification` in your GitHub
account; push. This is your first portfolio piece — make the
README good.

### Stretch (optional)

- **Stretch — RAL preview (Rosenberg ch.7)**
  Add a simple register block for "configure baud rate" via the
  TB. Just a frontdoor write through a generated `uvm_reg`. Full
  RAL exploration is W14.

---

## Design Homework

This week is verification-heavy. The "design" homework is just RTL
hygiene on the W10 UART before you publish it.

### Drills

- **Drill — RTL lint pass**
  *Folder:* `homework/design/per_chapter/hw_uart_lint/`
  Re-read **Sutherland ch.6** (procedural blocks). Sweep your W10
  RTL: every always block is `always_ff` or `always_comb`; no
  latches; all signals declared `logic`; constants `localparam`.
  Document anything you fixed.

- **Drill — Synthesis check (preview of W15)**
  *Folder:* `homework/design/per_chapter/hw_uart_yosys/`
  Run `yosys -p "read_verilog ...; synth -top uart_top; stat"` on
  your UART RTL. Note FF count and LUT count. Outside W12's
  textbook scope — pure preview.

### Main HW

#### HW1: README + block diagram for the RTL
*Folder:* `homework/design/connector/hw1_uart_doc/`

Block diagram of the UART (baud-gen → TX → wire → RX, FIFO
buffer if you have it). 1-page-per-module documentation. Goes in
the same `docs/` folder as the UVM TB diagram.

---

## Self-Check Questions

1. What's the role of `is_active` in a `uvm_agent`?
2. Where does the scoreboard's reference model live, and why?
3. What's the difference between a `uvm_subscriber` and a
   `uvm_analysis_imp`? When does each appear?
4. How does `+UVM_TESTNAME` select a test?
5. What's the right place to set/get `virtual uart_if` — top, env,
   agent, or driver?
6. How do you measure coverage closure in your TB?

---

## Checklist

### Verification Track
- [ ] Read Salemi ch.20-24 (refresher)
- [ ] Read Rosenberg ch.4-5 (sequences)
- [ ] Read Rosenberg ch.6 (driver/sequencer)
- [ ] Read Rosenberg ch.8 (scoreboards)
- [ ] Read Rosenberg ch.9 (stimulus)
- [ ] Read Rosenberg ch.10 (reporting / end-of-test)
- [ ] Drill: uart_seq_item
- [ ] Drill: uart_driver
- [ ] Drill: uart_monitor
- [ ] Drill: uart_scoreboard
- [ ] Drill: uart_coverage
- [ ] Drill: uart_agent
- [ ] Drill: uart_random_seq
- [ ] HW1: full UVM env + 5 sequences + 5 tests
- [ ] HW2: regression + coverage closure (100%)
- [ ] HW3: README + architecture diagram
- [ ] HW4: pushed to GitHub
- [ ] Can answer all self-check questions

### Design Track
- [ ] RTL lint pass (Sutherland ch.6)
- [ ] Yosys synth-stat preview
- [ ] Block diagram + per-module docs
- [ ] **MILESTONE: First portfolio project live on GitHub.**

---

## Appendix: README template

```markdown
# UART with UVM Verification Environment

## Overview
Fully verified UART (TX + RX) IP core with a complete UVM testbench.

## Architecture
![Testbench Architecture](docs/architecture.png)

## Features
- Configurable baud rate (9600, 115200, ...)
- 16x oversampling RX
- Framing error detection
- UVM testbench: constrained-random, coverage-driven, ref-model
  scoreboard

## Results
| Test            | Transactions | Result |
|-----------------|--------------|--------|
| Directed        |   10         | PASS   |
| Random          | 1000         | PASS   |
| Stress          | 5000         | PASS   |
| Error           |  500         | PASS   |
| Coverage        |  N/A         | 100%   |

## How to run
make compile
make run TEST=uart_random_test
make regression

## Tools
SystemVerilog + UVM 1.2 / xsim (or Questa/VCS)
```

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_12_uart_uvm_project/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 12 — Week 12: Portfolio Project #1 — UART with Full UVM Testbench

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_12.md`](../docs/week_12.md) · ⬜ Not started

This is your first GitHub portfolio piece. It demonstrates: RTL
design (W10), UVM verification (W4-W6), coverage-driven
methodology, and professional documentation. This is what hiring
managers click on first.

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

Canonical syllabus: [`docs/week_12.md`](../docs/week_12.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 12 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_12.md`](../docs/week_12.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 1 — Verify (UVM coverage closure methodology)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

Demo video script draft for UART-UVM

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 12 — Homework

The canonical homework list lives at
[`docs/week_12.md`](../docs/week_12.md). When you start
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
cd week_12_*

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

# Week 12 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_12.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_12.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 1 — Verify (UVM coverage closure methodology)
- [ ] **Power-skill task** — Demo video script draft for UART-UVM
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 12 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

