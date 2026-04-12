# DV / ASIC Study Plan — 12 Weeks

> **Work in progress.** This is my personal self-study plan — I am actively working through it and committing as I go.

This repository contains my structured **12-week Digital Verification / ASIC self-study curriculum** together with all the code I write along the way. The goal: take my HDLBits-level Verilog foundation and grow into a solid Junior DV / RTL engineer with portfolio projects in **SystemVerilog**, **UVM**, **RISC-V CPU design**, and **communication protocols**.

I am doing this on my own as an autodidact alongside my job search, building in the open.

---

## Progress

| Week | Topic | Status |
|------|-------|--------|
| 1 | SystemVerilog OOP (Classes, Inheritance, Polymorphism) | Done |
| 2 | Constrained Random Verification | Not started |
| 3 | Functional Coverage & SVA | Not started |
| 4 | UVM Architecture & Components | Not started |
| 5 | UVM Sequences & Config DB | Not started |
| 6 | UVM Full Testbench | Not started |
| 7 | RISC-V Single-Cycle CPU | Not started |
| 8 | RISC-V Pipelined CPU | Not started |
| 9 | UART Protocol | Not started |
| 10 | SPI & AXI-Lite | Not started |
| 11 | UART + UVM Project | Not started |
| 12 | RISC-V & FIFO UVM Projects | Not started |

---

## Repository Layout

```
.
├── week_01_sv_oop/
├── week_02_constrained_random/
├── ...
├── week_12_riscv_fifo_projects/
├── run_xsim.sh            # Vivado xsim run helper
├── run_xsim_auto.sh       # Auto-includes *_pkg.sv files
└── xvlog_lint.sh           # Lint helper
```

Each `week_XX_*/` folder follows a consistent structure:

```
week_XX_topic/
├── .vscode/      # VSCode tasks and settings
├── rtl/          # SystemVerilog RTL / classes
├── tb/           # Testbenches, homework, UVM components
├── scripts/      # Run / lint helpers
└── schematics/   # Optional diagrams or notes
```

Build output (`build/`, `waves/`, `*.out`, `*.jou`, `*.log`, `.Xil/`, `xsim.dir/`) is `.gitignore`d.

---

## The Plan at a Glance

| Phase | Weeks | Focus |
|-------|-------|-------|
| **1 — SystemVerilog for Verification** | 1-3 | OOP, constrained-random, functional coverage, assertions (SVA) |
| **2 — UVM** | 4-6 | UVM architecture, sequences, config DB, full scoreboard testbench |
| **3 — Computer Architecture** | 7-8 | RV32I ISA, single-cycle then 5-stage pipelined RISC-V CPU in SV |
| **4 — Protocols** | 9-10 | UART, SPI, AXI-Lite |
| **5 — Portfolio Projects** | 11-12 | UART + UVM, RISC-V CPU cleanup, FIFO + UVM |

---

## Books

| Book | Used For |
|------|----------|
| *SystemVerilog for Verification* — Spear & Tumbush (3rd ed) | SV for verification (weeks 1-3) |
| *A Practical Guide to Adopting the UVM* — Rosenberg & Meade (2nd ed) | UVM (weeks 4-6) |
| *Digital Design and Computer Architecture: RISC-V* — Harris & Harris | CPU design (weeks 7-8) |

Plus free online resources: **Verification Academy**, **ChipVerify**, **EDA Playground**, **Nandland**, and the **RISC-V spec**.

---

## Toolchain

- **Xilinx Vivado / xsim** (via Docker on Apple Silicon) for local simulation
- **EDA Playground** (with commercial simulators) for UVM runs
- **VSCode** with SystemVerilog extensions for editing

---

## Status

This repo grows week by week. If you're a recruiter or engineer — thanks for taking a look!
