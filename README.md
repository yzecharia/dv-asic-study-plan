# DV / ASIC Study Plan — 12 Weeks

> ⚠️ **Work in progress.** This is my personal self-study plan — I am actively working through it and committing as I go. Weeks are at different stages of completion.

This repository contains my structured **12-week Digital Verification / ASIC self-study curriculum** together with all the code I write for it along the way. The goal: take my HDLBits-level Verilog foundation and grow into a solid Junior DV / RTL engineer with portfolio projects in **SystemVerilog**, **UVM**, **RISC-V CPU design**, and **communication protocols**.

I am doing this on my own as an autodidact alongside my job search, building in the open.

---

## Repository Layout

```
.
├── plans/      # The weekly study plan (what to read, watch, and do)
│   ├── README.md          # plan overview
│   ├── PROGRESS.md        # master progress checklist
│   └── week_01.md ... week_12.md
│
└── code/       # The actual homework / lab code for each week
    ├── week_01_sv_oop/
    ├── week_02_constrained_random/
    ├── ...
    ├── week_12_riscv_fifo_projects/
    ├── run_xsim.sh         # Vivado xsim run helper
    ├── run_xsim_auto.sh
    └── xvlog_lint.sh       # Lint helper
```

Each `code/week_XX_*/` folder follows a small, consistent structure:

```
week_XX_topic/
├── rtl/          # SystemVerilog RTL / classes
├── tb/           # Testbenches, UVM components
├── scripts/      # Run / lint helpers
└── schematics/   # Optional diagrams or notes
```

Build output (`build/`, `waves/`, `*.out`, `*.jou`, `*.log`, `.Xil/`, `xsim.dir/`, etc.) is `.gitignore`d.

---

## The Plan at a Glance

| Phase | Weeks | Focus |
|-------|-------|-------|
| **1 — SystemVerilog for Verification** | 1–3 | OOP, constrained-random, functional coverage, assertions (SVA) |
| **2 — UVM** | 4–6 | UVM architecture, sequences, config DB, full scoreboard testbench |
| **3 — Computer Architecture** | 7–8 | RV32I ISA, single-cycle then 5-stage pipelined RISC-V CPU in SV |
| **4 — Protocols** | 9–10 | UART, SPI, AXI-Lite |
| **5 — Portfolio Projects** | 11–12 | UART + UVM, RISC-V CPU cleanup, FIFO + UVM |

See [`plans/README.md`](plans/README.md) for the full plan and [`plans/PROGRESS.md`](plans/PROGRESS.md) for the master checklist.

---

## Books I'm Using

| Book | Used For |
|------|----------|
| *SystemVerilog for Verification* — Spear & Tumbush (3rd ed) | SV for verification (weeks 1–3) |
| *A Practical Guide to Adopting the UVM* — Rosenberg & Meade | UVM (weeks 4–6) |
| *Digital Design and Computer Architecture: RISC-V* — Harris & Harris | CPU design (weeks 7–8) |

Plus free online resources: **Verification Academy**, **ChipVerify**, **EDA Playground**, **Nandland**, and the **RISC-V spec**.

---

## Toolchain

- **Xilinx Vivado / xsim** for local simulation
- **EDA Playground** (with commercial simulators) for UVM runs
- Plain SystemVerilog — should be portable to Icarus / Verilator / Questa / VCS with minor tweaks

---

## Status

This repo will keep growing week by week. Expect incomplete weeks, in-progress homework, and occasional cleanup commits. If you're reading this and you're a recruiter or engineer — thanks for taking a look, and feel free to follow along!
