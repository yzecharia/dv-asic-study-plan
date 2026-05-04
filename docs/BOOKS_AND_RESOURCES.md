# Books and Resources

Two tables: (1) the nine books I own locally, and (2) the curated
online resources I lean on when no local book covers the topic.
Below them: which weeks each resource feeds, and the explicit gaps
that don't have a primary book.

Library path: `/Users/yuval/Documents/Books for study plan/`.

---

## 1. Local books (verified from title pages)

| Book | Author(s) | Edition | Best used for | Weeks |
|---|---|---|---|---|
| *SystemVerilog for Verification* | Spear & Tumbush | 3rd | SV testbench fundamentals — classes, randomization, coverage, SVA | W1 (ch.2,5,8 §1–5), W2 (ch.6,7,8 §6–end), W3 (ch.9) |
| *The UVM Primer* | Ray Salemi | 1st | UVM ground-up — factory, tests, components, env, TLM, sequences | W4 (ch.9–14), W5 (ch.15–19), W6 (ch.20–23), W7 (ch.24) |
| *A Practical Guide to Adopting the UVM* | Rosenberg & Meade | 2nd | UVM production patterns + RAL chapter | W7 (ch.5–8), W14 + W20 (RAL) |
| *SystemVerilog for Design* | Sutherland, Davidmann, Flake, Moorby | 2nd | RTL canonical — interfaces, modports, packed/unpacked, `always_comb`/`always_ff` | W4 (interfaces), W5–W11 (RTL coding), W19 (clocking blocks) |
| *RTL Modeling with SystemVerilog* | Sutherland | — | Synthesisable coding patterns, FSM styles, arithmetic operators | W3 (FSM coding), W6–W11 (RTL), W16 (signed) |
| *Digital Design: A Systems Approach* | Dally & Harting | — | Primary design textbook — combinational, arithmetic, sequential, timing, CDC, memory, pipelines | W3 (sequential), W4 (ch.10 adders, ch.11 multipliers), W5–W7 (memory, pipelines, CDC), W12 (pipelined arith for FIR) |
| *Digital Design and Computer Architecture: RISC-V* | Harris & Harris | RISC-V Edition | RV32I CPU design — single-cycle, pipeline, hazards | W8 (ch.7 §7.1–§7.4), W9 (ch.7 §7.5–§7.6) |
| *FPGA Prototyping by Verilog Examples* | Pong P. Chu | Spartan-3 | UART, FPGA flow examples | W2 (small FIFO/counter), W10 (UART), W15 (FPGA) |
| *SVA Design Tricks and Bind Files* (SNUG-2009) | Clifford E. Cummings | paper, Rev 1.0 | SVA design patterns + bind-file separation | W3, W19 |

> ⚠️ Note on Dally & Harting: the PDF is >100 MB and exceeds direct
> text extraction by tooling. Cite by chapter and page numbers you
> have read in the viewer — never invent page ranges.

---

## 2. Online resources (free, primary)

### Cliff Cummings papers (cummings.com)
The industry-gold short papers. Read all of these.

| Paper | Year | Used in |
|---|---|---|
| Synthesizable FSM Design Techniques (3.0 enhancements) | SNUG-2003 | W3, W10 |
| Nonblocking Assignments — Coding Styles That Kill | SNUG-2000 | W3 (referenced) |
| Clock Domain Crossing (CDC) Design & Verification | SNUG-2008 | W7, **W19** anchor |
| Simulation and Synthesis Techniques for Async FIFO | SNUG-2002 | W6, W7 |
| Full Case / Parallel Case Pragmas | SNUG-1999 | W8 |
| FSM Outputs — Coding & Scripting for Glitch-Free | SNUG-2010 | W10 |
| SystemVerilog Synthesis Coding Styles for Efficient Designs | SNUG-2012 | W15 |

### Verification Academy — UVM Cookbook
[verificationacademy.com/cookbook](https://verificationacademy.com/cookbook)
(free signup). Reference throughout W4–W7, W12, W14, W20.

### ChipVerify
[chipverify.com](https://chipverify.com) — quick-reference SV/UVM/UART/SPI tutorials. W1–W3, W10, W11.

### Smith — *Scientist & Engineer's Guide to DSP*
[dspguide.com](https://www.dspguide.com) — Chapters 14–16 cover FIR filter design and impulse response. **W17 anchor** (no local DSP book).

### Bailey — *Design for Embedded Image Processing on FPGAs* (or Xilinx XAPP933)
For 2D convolution + line-buffer architecture. **W18 anchor** (no local imaging book). XAPP933 is the free Xilinx app-note alternative on line-buffer architecture.

### ARM AMBA AXI Specification (IHI0022E)
Free PDF from arm.com. W11 (AXI-Lite slave), W14 + W20 (RAL adapter).

### RISC-V ISA Specification — Volume I, Unprivileged
[riscv.org/specifications](https://riscv.org/specifications) — V20191213 base. W8 (RV32I instruction set), W9 (privileged spec only if needed).

### Xilinx UG901 (Vivado Synthesis) + UG949 (UltraFast Design Methodology)
[xilinx.com](https://www.xilinx.com) — STA / synthesis pragmas / timing closure rules of thumb. W15 (synthesis), and the
**static_timing_analysis** concept note (since Bhasker is not in the local library).

### Yosys manual
[yosyshq.net/yosys/documentation.html](https://yosyshq.net/yosys/documentation.html) — passes, Verilog frontend caveats. W15.

### Nandland (UART, SPI, FPGA tutorials)
[nandland.com](https://nandland.com) — secondary UART reference. W10, W11.

### EDA Playground
[edaplayground.com](https://edaplayground.com) — UVM fallback when local Vivado xsim Docker is down. W4–W7, W12, W14, W20.

### ZipCPU blog
[zipcpu.com/blog.html](https://zipcpu.com/blog.html) — Verilator-friendly RTL tips, AXI walkthroughs. Optional sidecar reading throughout Phase 3 / Phase 4.

---

## 3. Coverage gaps (no primary book locally)

| Topic | Status | Plan |
|---|---|---|
| Static Timing Analysis (Bhasker) | No local book | Use Xilinx UG949 + tool reports for W15. Concept note `static_timing_analysis.md` documents the gap. |
| 1D/2D DSP filters | No local book | Smith DSP (W17), Bailey or XAPP933 (W18). Both online-only. |
| CDC depth (metastability MTBF math) | Beta cited Dally ch.28 — thin | Cummings SNUG-2008 paper is the deeper reference, applied in W19. |
| AMBA AXI4 (full burst, multi-master) | Out of scope | AXI-Lite only (W11, W20). Stretch: AXI-Full noted in `INTERVIEW_PREP.md` as a topic to study post-graduation. |
| Formal verification | Out of scope | Mentioned in `INTERVIEW_PREP.md` only. SymbiYosys is the open-source path if needed later. |

---

## 4. Resource-to-week matrix (quick scan)

| Wk | Primary | Secondary |
|---|---|---|
| W1 | Spear ch.2,5,8 §1–5 | Verification Academy SV intro, ChipVerify OOP |
| W2 | Spear ch.6,7,8 §6–end | Verification Academy CRV |
| W3 | Spear ch.9 + Cummings SNUG-2009 | Dally ch.14 sequential, Sutherland RTL Modeling FSM ch. |
| W4 | Salemi ch.9–14 + Sutherland Design (interfaces ch.) | Dally ch.10–11, UVM Cookbook |
| W5 | Salemi ch.15–19 | Rosenberg ch.4 |
| W6 | Salemi ch.20–23 + Rosenberg ch.4 | Cummings async-FIFO SNUG-2002 |
| W7 | Salemi ch.24 + Rosenberg ch.5–8 + Cummings CDC SNUG-2008 | UVM Cookbook scoreboard, Dally ch.28 |
| W8 | Harris & Harris ch.7 §7.1–§7.4 | RISC-V ISA spec V20191213 |
| W9 | Harris & Harris ch.7 §7.5–§7.6 | Patterson & Hennessy (online ch. on hazards) |
| W10 | Chu ch.7–9 + Cummings FSM SNUG-2003 | Nandland UART tutorial |
| W11 | ARM AMBA AXI spec ch.B + Nandland SPI | Cummings FSM-outputs SNUG-2010 |
| W12 | Salemi + Rosenberg refresh | Verification Academy UVM Cookbook |
| W13 | Same as W12 + Harris ch.7 | — |
| W14 | Rosenberg RAL chapter | UVM Cookbook RAL section |
| W15 | Cummings synth-coding SNUG-2012 + Yosys manual + Xilinx UG901/UG949 | — |
| W16 | Dally ch.10 + ch.11 + Sutherland RTL Modeling arith ch. | — |
| W17 | Smith DSP ch.14–16 (online) + Dally ch.12 | — |
| W18 | Bailey ch.7 / Xilinx XAPP933 (online) + W17 reuse | — |
| W19 | Cummings CDC SNUG-2008 + SVA SNUG-2009 + Sutherland Design clocking ch. | — |
| W20 | Rosenberg RAL + UVM Cookbook RAL + ARM AMBA AXI | — |

