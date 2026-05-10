# DV / RTL Study Plan 2.0 — 20 Weeks, 4 Phases

![Progress](https://img.shields.io/badge/progress-4%2F20_weeks-brightgreen)
![Current Week](https://img.shields.io/badge/current_week-5-blue)
![Week 5 Progress](https://img.shields.io/badge/week_5_progress-9%25-red)
![Phase](https://img.shields.io/badge/phase-2_UVM_Methodology-blue)
![Toolchain](https://img.shields.io/badge/toolchain-arm64_native_+_Vivado_Docker_for_UVM-lightgrey)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

> **Work in progress.** Personal self-study curriculum aimed at
> top-tier Junior RTL Design / Design Verification roles. I build in
> the open and commit as I go.

This is the **2.0 rewrite** of my earlier 15-week beta plan. It
preserves all the working code and per-week syllabi from the beta and
adds: an Obsidian-first daily-driver file template per week, weekly AI
productivity and power-skills tasks, page-precise reading citations,
and five new advanced-track weeks (signed/fixed-point arithmetic, 1D
FIR, 2D image convolution, advanced CDC, and a multi-UVC RAL
capstone).

The plan has two parallel tracks — **Verification** (SV OOP, CRV,
coverage, SVA, UVM) and **Design** (industry-style RTL, FSMs,
protocols, RISC-V CPU) — that build toward five portfolio projects
and a graduation capstone.

I am doing this on my own as an autodidact alongside my job search.

---

## Who this is for

- **Recruiters / hiring engineers** looking at my GitHub: jump to
  [`docs/PORTFOLIO_PROJECTS.md`](docs/PORTFOLIO_PROJECTS.md). The
  three flagship repos (UART-UVM, FIFO-UVM, RISC-V-CPU) and the
  multi-UVC RAL capstone live there.
- **Other students** wanting to follow along: every week is a
  self-contained module — clone, read `week_NN_*/README.md`, do the
  homework, run the testbench. Books in
  [`docs/BOOKS_AND_RESOURCES.md`](docs/BOOKS_AND_RESOURCES.md).
- **Me, six months from now**: the full study log, design decisions,
  and self-critique notes.

---

## The Plan at a Glance

| Phase | Weeks | Verification | Design |
|---|---|---|---|
| **1 — SV Fundamentals** | W1–W3 | OOP, CRV, coverage, SVA | Counter, FIFO, FSMs, handshake, arbiter, shift register |
| **2 — UVM Methodology** | W4–W7 | Salemi ch.9–23 split: arch (W4) → TLM/reporting (W5) → stimulus/sequences (W6) → full integration (W7) | ALU, interfaces, adders, multiplier, barrel shifter, dual-port RAM, RR arbiter, register file, CDC, async FIFO |
| **3 — RTL & Architecture** | W8–W11 | Self-check + ref-model TBs, framing-error injection, coverage closure | Single-cycle & pipelined RISC-V RV32I, UART, SPI master, AXI-Lite slave |
| **4 — Portfolio + Advanced + Career** | W12–W20 | Full UVM testbenches, RAL hand-write, multi-UVC env, regression with coverage, formal-style SVA bundle | UART/FIFO/CPU portfolio repos, synthesis/PPA, signed/fixed-point MAC, 1D FIR, 2D image conv, advanced CDC handshake, top-level SoC-lite capstone |

Full week-by-week breakdown: [`docs/ROADMAP.md`](docs/ROADMAP.md).
Status of every week: [`docs/PROGRESS.md`](docs/PROGRESS.md).

---

## Progress

| Week | Phase | Topic | Status |
|---|---|---|---|
| 1 | 1 | SV OOP | ✅ Done |
| 2 | 1 | Constrained Random | ✅ Done |
| 3 | 1 | Coverage & SVA | ✅ Done |
| 4 | 2 | UVM Architecture (Salemi 9–14) | ✅ Done |
| 5 | 2 | UVM Communication (15–19) | 🟡 In progress |
| 6 | 2 | UVM Stimulus (20–23) | ⬜ Not started |
| 7 | 2 | UVM Full Integration | ⬜ Not started |
| 8 | 3 | RISC-V Single-Cycle | ⬜ Not started |
| 9 | 3 | RISC-V Pipeline + Hazards | ⬜ Not started |
| 10 | 3 | UART | ⬜ Not started |
| 11 | 3 | SPI + AXI-Lite | ⬜ Not started |
| 12 | 4 | **Portfolio: UART-UVM** | ⬜ Not started |
| 13 | 4 | **Portfolio: FIFO-UVM + RISC-V CPU** | ⬜ Not started |
| 14 | 4 | Advanced UVM — RAL + Multi-UVC | ⬜ Not started |
| 15 | 4 | Design Closure — Synthesis / PPA / FPGA | ⬜ Not started |
| 16 | 4 | Signed & Fixed-Point Arithmetic 🆕 | ⬜ Not started |
| 17 | 4 | DSP I — 1D FIR Filter 🆕 | ⬜ Not started |
| 18 | 4 | DSP II — 2D Image Convolution 🆕 | ⬜ Not started |
| 19 | 4 | Advanced CDC & Multi-Bit Handshake 🆕 | ⬜ Not started |
| 20 | 4 | **Capstone: RAL + Multi-UVC + System** 🆕 | ⬜ Not started |
🆕 = new in plan 2.0 vs the 15-week beta.

---

## Repository Layout

```
study_plan_2.0/
├── CLAUDE.md                          # operating rules for AI sessions in this repo
├── README.md                          # this file
├── LICENSE
│
├── docs/                              # canonical week syllabi + curriculum docs
│   ├── week_01.md … week_15.md        # source-of-truth syllabi (preserved from beta)
│   ├── week_16.md … week_20.md        # syllabi for the new advanced-track weeks
│   ├── PROGRESS.md                    # 20-week master checklist
│   ├── ROADMAP.md                     # phase DAG + dependencies
│   ├── BOOKS_AND_RESOURCES.md         # 9 local books + curated online refs
│   ├── SYLLABUS_COVERAGE.md           # matrix: every syllabus topic → week
│   ├── OBSIDIAN_GUIDE.md              # how to use this repo as a vault
│   ├── AI_LEARNING_GUIDE.md           # 5 weekly AI task types + prompt templates
│   ├── POWER_SKILLS.md                # STAR, LinkedIn, elevator pitch, mock interview
│   ├── INTERVIEW_PREP.md              # junior RTL/DV question categories
│   ├── PORTFOLIO_PROJECTS.md          # the 3+2 flagship repos
│   ├── prompts/                       # reusable AI prompt templates
│   ├── concepts/                      # ~61 reusable [[wikilink]]-able concept notes
│   └── uvm_consolidation_salemi_ch9-15.pdf
│
├── cheatsheets/                       # runnable .sv reference snippets
│   ├── salemi_uvm_ch9-13.sv           # my own UVM cheatsheet — preserved
│   └── spear_ch4_interfaces.sv        # my own interfaces cheatsheet — preserved
│
├── tools/                             # repo-wide automation
│   ├── update_progress_badges.py      # README badges from week_NN.md checkboxes
│   ├── check_week_structure.py        # lint: every week has the 5 daily-driver files
│   └── check_concept_notes.py         # lint: every concept note meets minimum bar
│
├── week_01_sv_oop/                    # one folder per week
│   ├── README.md                      # 1-page overview (Phase, prereqs, deliverables)
│   ├── learning_assignment.md         # reading + AI task
│   ├── homework.md                    # exercises + acceptance criteria
│   ├── checklist.md                   # daily checkboxes
│   ├── notes.md                       # my freeform notes
│   ├── learning/                      # book-derived examples
│   ├── homework/{verif,design}/       # per_chapter / connector / big_picture
│   ├── rtl/  tb/  sim/  scripts/  .vscode/
│   └── verification_report.md         # Iron-Rule deliverable (c)
├── week_02_constrained_random/
├── …
├── week_20_capstone_multiuvc_ral/
│
├── archive/                           # obsolete artefacts (not deleted, just parked)
├── run_xsim.sh                        # Vivado xsim Docker runner (UVM weeks)
├── run_yosys_rtl.sh                   # Yosys synthesis + schematic generation
└── xvlog_lint.sh                      # Xilinx lint helper
```

Build artefacts (`build/`, `waves/`, `*.wdb`, `*.jou`, `*.log`,
`.Xil/`, `xsim.dir/`, `.yosys_tmp/`, `build_rtl/*.svg`,
`build_rtl/*.dot`) are `.gitignore`d.

---

## Books

The nine books in my local library are listed in
[`docs/BOOKS_AND_RESOURCES.md`](docs/BOOKS_AND_RESOURCES.md), with
each chapter mapped to the week that uses it. Highlights:

| Book | Used For |
|---|---|
| Spear & Tumbush — *SystemVerilog for Verification* (3e) | SV verif fundamentals (W1–3) |
| Salemi — *The UVM Primer* | UVM ch.9–23 across W4–W7 |
| Rosenberg & Meade — *A Practical Guide to Adopting the UVM* (2e) | UVM production patterns + RAL (W7+, W14, W20) |
| Sutherland/Davidmann/Flake — *SystemVerilog for Design* (2e) | RTL canonical reference (W4+) |
| Sutherland — *RTL Modeling with SystemVerilog* | Synthesisable coding patterns (W6–11) |
| Dally & Harting — *Digital Design: A Systems Approach* | Primary design textbook (W3–9) |
| Harris & Harris — *Digital Design and Computer Architecture: RISC-V* | CPU design (W8–9) |
| Chu — *FPGA Prototyping by Verilog Examples* | UART, FPGA flow (W2, W10) |
| Cummings — *SVA Design Tricks and Bind Files* (SNUG-2009) | SVA + bind-file patterns (W3, W19) |

Plus: Cummings papers (CDC SNUG-2008, async FIFO SNUG-2002, FSM coding,
nonblocking assignments), Verification Academy UVM Cookbook, Smith
*Scientist & Engineer's Guide to DSP* (online — W17), ARM AMBA AXI
spec, official RISC-V ISA spec.

---

## Toolchain

Default to **arm64-native open-source** tools. Vivado xsim via Docker
is reserved for UVM weeks where open-source UVM support is incomplete.

| Use | Tool | Path |
|---|---|---|
| Phase-1/2 sim | Icarus Verilog 13.0 | `/opt/homebrew/bin/iverilog -g2012` |
| Lint + fast sim | Verilator 5.046 | `verilator --lint-only -Wall` / `verilator --binary` |
| Waves | gtkwave | `/opt/homebrew/bin/gtkwave` |
| Synthesis / PPA | Yosys (+ nextpnr for FPGA flows) | `bash run_yosys_rtl.sh <file.sv>` |
| UVM (W4–W7, W12–14, W20) | Vivado xsim via Docker | `bash run_xsim.sh -L uvm <files>` |
| UVM fallback | EDA Playground | quick experiments only |

See `CLAUDE.md` §4 for the rule on open-source-equivalents.

---

## How to use this repo

### As a course
```
git clone <this-repo>
cd study_plan_2.0
open week_01_sv_oop/README.md       # your daily driver for the week
```

### As an Obsidian vault
```
# Open the repo root as an Obsidian vault.
# Recommended plugins: Dataview, Templater, Excalidraw.
# Wikilinks like [[concepts/sva_assertions]] resolve to docs/concepts/sva_assertions.md.
```
Setup details: [`docs/OBSIDIAN_GUIDE.md`](docs/OBSIDIAN_GUIDE.md).

### Running a sample sim (W1 baseline)

The W1 testbenches use class-based randomization (`obj.randomize()`),
which Icarus 13.0's class support doesn't yet implement. Use Vivado
xsim via Docker for class-based SV — the same path the UVM weeks
(W4–W7) take:

```
cd week_01_sv_oop/tb/HomeWork/HW1
bash ../../../../run_xsim.sh hw1_packet_tb.sv
```

Pure-RTL Phase-1/2 work (e.g. W2 Sync FIFO, W3 FSMs, W4+ design
side) runs natively on Icarus / Verilator without Docker.

### Running a UVM sim (W4)
```
cd week_04_uvm_architecture
bash ../run_xsim.sh -L uvm homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv
```

### Updating progress badges
```
python3 tools/update_progress_badges.py        # auto-detect current week
python3 tools/update_progress_badges.py 4      # explicit
```

---

## Iron Rules (Definition of Done per week)

A week is not done until ALL THREE exist on its branch:

1. **(a)** RTL committed, lint-clean.
2. **(b)** Gold-testbench PASS log captured to `week_NN_*/sim/<topic>_pass.log`.
3. **(c)** `verification_report.md` written.

See `CLAUDE.md` §2.

---

## AI Productivity (responsible use)

Each week includes a 30-minute AI task. Five rotated types:

1. **Verify** — ask AI to explain a concept, then check vs the book.
2. **Flashcards** — generate, then correct factual errors yourself.
3. **RTL style review** — paste your own RTL, ask AI to critique. Don't
   ask it to rewrite.
4. **Interview Qs** — generate Qs on the week's topic, write your own
   answers, then compare.
5. **Waveform debug summary** — paste a waveform observation, ask AI to
   articulate what it implies.

Full guidance: [`docs/AI_LEARNING_GUIDE.md`](docs/AI_LEARNING_GUIDE.md).
The rule: AI assists understanding; AI does not write the homework.

---

## Power skills (woven weekly)

Each week's `checklist.md` ends with a 30-minute career task — a
STAR story draft, a LinkedIn headline iteration, an elevator pitch
recording, a mock-interview answer, or a resume bullet refinement.
Templates in [`docs/POWER_SKILLS.md`](docs/POWER_SKILLS.md), Q bank
in [`docs/INTERVIEW_PREP.md`](docs/INTERVIEW_PREP.md).

---

## Status

Plan 2.0 bootstrapped 2026-05-03 from the
[beta StudyPlan](https://github.com/yzecharia/dv-asic-study-plan) at
SHA `43c98a1`. Currently on **Week 4 (Phase 2 — UVM Methodology)**:
verification side complete, design side in progress.

If you're a recruiter or engineer reading this — thanks for taking a
look.
