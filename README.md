# DV / ASIC Study Plan — 13 Weeks (+2 Bonus)

![Progress](https://img.shields.io/badge/progress-3%2F15_weeks-brightgreen)
![Current Week](https://img.shields.io/badge/current_week-4-blue)
![Week 4 Progress](https://img.shields.io/badge/week_4_progress-48%25-yellow)
![Language](https://img.shields.io/badge/language-SystemVerilog-blue)
![UVM](https://img.shields.io/badge/UVM-in_progress-yellow)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

> **Work in progress.** This is my personal self-study plan — I am actively working through it and committing as I go.

This repository contains my structured **13-week Digital Verification / ASIC self-study curriculum** (plus 2 bonus weeks) together with all the code I write along the way. The goal: take my HDLBits-level Verilog foundation and grow into a solid Junior DV / RTL engineer with portfolio projects in **SystemVerilog**, **UVM**, **RISC-V CPU design**, and **communication protocols**.

The plan has two parallel tracks: **Verification** (SV OOP, CRV, coverage, UVM) and **Design** (industry-style RTL, FSMs, protocols, CPU architecture). Both tracks build toward three portfolio projects.

Each week's homework is organized as **per-chapter exercises → connector → big-picture** so concepts are introduced one at a time, then tied together, then stretched.

I am doing this on my own as an autodidact alongside my job search, building in the open.

---

## Progress

| Week | Verification Track | Design Track | Status |
|------|-------------------|--------------|--------|
| 1 | SV OOP (Classes, Inheritance, Polymorphism) | — | Done |
| 2 | Constrained Random Verification | Counter, Sync FIFO, FSM coding | Done |
| 3 | Functional Coverage & SVA | FSM, Handshake, Arbiter, Shift Register | Done |
| 4 | UVM Architecture (Salemi ch.9-14: factory, test, components, env) | ALU, SV Interfaces, Adders, Multiplier, Barrel Shifter | In progress |
| 5 | UVM Communication (Salemi ch.15-19: TLM, analysis ports, reporting) | Shift register, valid/ready handshake, structs, dual-port RAM, RR arbiter | Not started |
| 6 | UVM Stimulus (Salemi ch.20-23: deep ops, transactions, agents, sequences) | Param register file, memory bank, async FIFO theory, direct-mapped cache | Not started |
| 7 | UVM Full Testbench Integration (project) | Register File, CDC synchronizer, Async FIFO RTL, Timing | Not started |
| 8 | — | RISC-V Single-Cycle CPU | Not started |
| 9 | — | RISC-V Pipelined CPU + Hazards | Not started |
| 10 | — | UART TX/RX Design | Not started |
| 11 | — | SPI Master, AXI-Lite Slave | Not started |
| 12 | UVM Testbench for UART | UART RTL cleanup | Not started |
| 13 | UVM Testbench for FIFO | RISC-V CPU cleanup | Not started |
| **14 (bonus)** | **Advanced UVM — RAL + Multi-UVC + Register Verification** | — | Not started |
| **15 (bonus)** | — | **Design Closure — Synthesis, PPA, FPGA Implementation** | Not started |

> The bonus weeks close gaps that academic DV/ASIC courses cover explicitly
> (UVM RAL, multi-UVC environments, synthesis/PPA, FPGA implementation flow)
> so the final portfolio is interview-grade across both verification and
> design closure.

> **History note:** Originally a 12-week plan; expanded to 13+2 in April 2026
> after realizing Salemi's UVM Primer ch.9-23 doesn't fit a single week.
> Old W4 (Salemi 1-14) split into W4 (ch.9-14) + W5 (ch.15-19) + W6 (ch.20-23).
> Subsequent weeks shifted +1.

---

## Repository Layout

```
.
├── docs/                  # Week-by-week study plans (week_01.md … week_15.md)
│                          # + PROGRESS.md tracking overall completion
├── cheatsheets/           # Topic cheatsheets — runnable .sv reference files
│                          # (oop_basics, advanced_oop, data_types, threads_and_ipc,
│                          #  assertions_sva, functional_coverage,
│                          #  salemi_uvm_ch9-13, spear_ch4_interfaces)
├── tools/                 # Repo-wide scripts
│   └── update_progress_badges.py    # auto-update README badges from week_NN.md
│
├── week_01_sv_oop/
├── week_02_constrained_random/
├── ...
├── week_13_riscv_fifo_projects/
├── week_14_advanced_uvm/        # bonus — UVM RAL + multi-UVC
├── week_15_design_closure/      # bonus — synthesis + PPA + FPGA
│
├── run_xsim.sh            # Vivado xsim run helper (Docker-backed)
├── run_xsim_auto.sh       # Same, auto-includes *_pkg.sv files
├── xvlog_lint.sh          # Lint helper
├── README.md
└── LICENSE                # MIT
```

Each `week_XX_*/` folder has its own `.vscode/tasks.json` wired for the
iverilog / xsim / Yosys flows. Recent weeks use a cleaner layout that
separates textbook exercises from portfolio deliverables:

```
week_XX_topic/
├── .vscode/                # Per-week build/sim/schematic tasks
├── learning/               # Textbook chapters — examples & exercises
│   └── <book_name>/<chapter>/
│       ├── examples/
│       └── exercises/
├── homework/               # Assignments from docs/week_XX.md
│   ├── verif/
│   │   ├── per_chapter/    # one small HW per book chapter (10-30 lines)
│   │   ├── connector/      # ties all the week's chapters together
│   │   └── big_picture/    # stretches concepts within the week's scope
│   └── design/             # same per_chapter / connector / big_picture for RTL
└── scripts/                # Optional per-week run helpers
```

Earlier weeks (1–2) use a flatter `rtl/` + `tb/` layout. All build output
(`build/`, `waves/`, `*.wdb`, `*.jou`, `*.log`, `.Xil/`, `xsim.dir/`,
`.yosys_tmp/`) is `.gitignore`d.

---

## The Plan at a Glance

| Phase | Weeks | Verification | Design |
|-------|-------|-------------|--------|
| **1 — SV Fundamentals** | 1-3 | OOP, CRV, coverage, SVA | Counter, FIFO, FSMs, handshake, arbiter, shift register |
| **2 — UVM (split into digestible chunks)** | 4-7 | W4: UVM arch (Salemi 9-14) → W5: TLM/reporting (15-19) → W6: stimulus/sequences (20-23) → W7: full TB integration | ALU, interfaces, adders, multiplier, barrel shifter, dual-port RAM, RR arbiter, cache, register file, CDC, async FIFO |
| **3 — CPU Architecture** | 8-9 | — | Single-cycle & pipelined RISC-V RV32I CPU |
| **4 — Protocols** | 10-11 | — | UART, SPI, AXI-Lite |
| **5 — Portfolio Projects** | 12-13 | Full UVM testbenches for UART & FIFO | RTL cleanup & documentation |
| **6 — Course-Coverage Bonus** | 14-15 | RAL + Multi-UVC + Register verification | Synthesis, PPA, FPGA implementation flow |

---

## Books

| Book | Used For |
|------|----------|
| *SystemVerilog for Verification* — Spear & Tumbush (3rd ed) | SV for verification (weeks 1-3) |
| *The UVM Primer* — Ray Salemi | UVM fundamentals — primary (weeks 4-7); covers ch.9-23 across W4-W6 |
| *A Practical Guide to Adopting the UVM* — Rosenberg & Meade (2nd ed) | UVM production patterns — reference (week 7) |
| [Verification Academy UVM Cookbook](https://verificationacademy.com/cookbook) (free) | UVM reference throughout weeks 4-7 |
| *Digital Design: A Systems Approach* — Dally & Harting | **Primary design textbook** — combinational blocks, arithmetic, sequential logic, timing, CDC, memory, pipelines, interconnect (weeks 3-9) |
| *Digital Design and Computer Architecture: RISC-V* — Harris & Harris | CPU design (weeks 8-9) |
| *FPGA Prototyping by SystemVerilog Examples* — Pong P. Chu | RTL design reference, UART (weeks 2, 10) |
| *SystemVerilog for Design* (2nd ed) — Sutherland, Davidmann, Flake, Moorby | SV-for-design canonical reference — interfaces, modports, packed/unpacked types, `always_comb`/`always_ff`, parameterized modules, RTL synthesis guidelines (used from week 4 onwards across the design track and the bonus weeks) |
| *RTL Modeling with SystemVerilog* — Sutherland | Practical synthesizable RTL coding patterns (companion to the above; design track weeks 6-11) |

Key papers (free): **Cliff Cummings** — FSM coding styles, nonblocking assignments, clock domain crossing (CDC), async FIFO design, synthesis coding styles, **SVA Design Tricks and Bind Files (SNUG-2009)**. These papers are industry gold — read all of them.

Plus free online resources: **Verification Academy**, **ChipVerify**, **EDA Playground**, **Nandland**, and the **RISC-V spec**.

---

## Toolchain

- **Xilinx Vivado / xsim** (via Docker on Apple Silicon) for local simulation — UVM-capable with `-L uvm`
- **EDA Playground** (with commercial simulators) — fallback for UVM edge cases
- **VSCode** with SystemVerilog extensions for editing

---

## Status

This repo grows week by week. If you're a recruiter or engineer — thanks for taking a look!
