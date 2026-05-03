# Syllabus Coverage Matrix

Audit document: every topic from the canonical syllabus mapped to the week
that covers it, with the primary reading reference and the homework
that exercises it. The "Week" column shows the **first** week the topic
is taught; deeper treatment is noted in parentheses.

Status legend: ✅ Covered · 🟡 Partial · ⬜ Not yet · ↗ Stretch / outside scope

---

## A. Introduction to Digital Design

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| Unsigned and signed binary numbers and fractions | W2 (intro) → **W16** (depth) | Spear ch.6 + Dally ch.10 | W2 constraints + W16 Q-format MAC | ⬜ |
| Logical operators and Boolean algebra | Prereq (HDLBits) | Harris ch.2 §2.1–2.4 | — | ✅ Prereq |
| Gates and timing of gates | Prereq (HDLBits) | Harris ch.2 + Dally ch.5 | — | ✅ Prereq |
| Combinational designs (decoders, mux, adders) | W3 + W4 | Dally ch.10 (adders) | W3 arbiter, W4 ripple+CLA | 🟡 W4 in progress |
| Sequential designs (master-slave D-FF and timing) | W3 (impl), W19 (timing) | Dally ch.14 + Cummings CDC paper | W3 shift register; W19 metastability discussion | 🟡 |
| Types of registers | W3 + W7 | Dally ch.14, Sutherland Design ch. on registers | W3 shift register; W7 register file | ⬜ |
| Sequential circuits and state machines | W3 | Cummings FSM SNUG-2003 + Sutherland RTL Modeling FSM ch. | W3 traffic light, handshake, arbiter | ✅ |
| Pipelined circuits | W9 + W17 | Harris ch.7 §7.5 + Dally ch.12 | W9 5-stage pipeline; W17 FIR pipelining | ⬜ |
| Busses, memories, and FIFOs | W2 + W6 + W7 | Spear ch.7 + Dally ch.16 + Cummings async FIFO SNUG-2002 | W2 sync FIFO; W6 register file; W7 async FIFO | 🟡 (W2 done) |
| Signal and image processing — 1D and 2D filters | **W17** + **W18** 🆕 | Smith DSP ch.14–16 (online); Bailey ch.7 / XAPP933 | W17 8-tap FIR; W18 3×3 conv | ⬜ |
| Clock synchronisation | W7 | Dally ch.28 + Cummings CDC SNUG-2008 | W7 pulse synchroniser | ⬜ |
| Clock Domain Crossing | W7 (intro) → **W19** (depth) 🆕 | Cummings CDC SNUG-2008 | W7 2-FF + gray code; W19 multi-bit handshake | ⬜ |
| Top-down design | W12 + W20 | UVM Cookbook + Rosenberg ch.5 | W12 UART-UVM env decomposition; W20 SoC-lite | ⬜ |

## B. Hardware Design using Verilog/SystemVerilog

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| Introduction to Verilog and design flow | Prereq | Chu ch.1 | — | ✅ Prereq |
| Verilog syntax and data types | W1 | Spear ch.2 | W1 ch.2 drills | ✅ |
| Combinational logic | Prereq → W4 | Sutherland Design ch. on `always_comb` | W4 ALU, adders | 🟡 |
| Sequential logic | Prereq → W7 | Sutherland Design `always_ff` ch. | W7 register file | ✅ Prereq |
| Finite State Machines | W3 + W10 + W11 | Cummings FSM SNUG-2003 | W3 FSMs; W10 UART FSM; W11 SPI FSM | ✅ (W3) |
| Introduction to SystemVerilog | W1 | Spear ch.1 | — | ✅ |
| Modular, scalable, parametric design | W2 + W6 | Sutherland Design parameter ch. | W2 sync FIFO param; W6 reg file param | ✅ (W2) |
| Multi-clock and multi-reset domain systems | W7 + **W19** | Sutherland Design clocking ch. + Cummings CDC | W7 pulse sync; W19 multi-ratio async FIFOs | ⬜ |
| Memories, redundancy, and ECC | W6 (memory) ↗ ECC | Sutherland Design memory ch.; ECC ↗ stretch | W6 dual-port RAM | 🟡 ECC stretch only |
| FIFOs, advanced sync, flow control | W2 + W6 + W7 | Cummings async FIFO SNUG-2002 | W2 sync FIFO; W7 async FIFO RTL | 🟡 (W2 done) |
| High-speed bus protocols and interfaces | W11 (AXI-Lite, SPI) + ↗ AXI-Full | ARM AMBA AXI ch.B; Nandland SPI | W11 AXI-Lite slave + SPI master | ⬜ |
| Timing concepts and synthesis constraints | W15 | Cummings synth-coding SNUG-2012 + Xilinx UG949 | W15 timing report + `.xdc` | ⬜ |
| Signed and fixed-point arithmetic | **W16** 🆕 | Dally ch.10 + Sutherland RTL Modeling arith ch. | W16 Q4.12 MAC | ⬜ |
| Synthesis and PPA analysis | W15 | Yosys manual + Xilinx UG901 | W15 LUT/FF/Fmax report | ⬜ |
| FPGA implementation flow and debug | W15 | Chu ch.6 + Vivado UG949 | W15 Basys3 flow | ⬜ |
| Final design project | W12, W13, W20 | Per-project | UART-UVM, FIFO-UVM, RISC-V-CPU, capstone | ⬜ |

## C. Verification using SystemVerilog

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| SystemVerilog for verification | W1 | Spear ch.1–2 | W1 packet drills | ✅ |
| Procedural programming constructs | W1 | Spear ch.2 | W1 ch.2 drills | ✅ |
| Data structures and control mechanisms | W1 | Spear ch.2 + ch.4 (queues, dyn arrays) | W1 ch.2 drills | ✅ |
| Interfaces and synchronisation | W4 | Spear ch.4 + Sutherland Design interfaces ch. | W4 ALU interfaces | 🟡 |
| OOP in SystemVerilog | W1 + W2 | Spear ch.5 + ch.8 | W1 hierarchy; W2 ConstrainedPacket | ✅ |
| Verification concepts in SystemVerilog | W1–W3 | Spear ch.5–9 | W1–W3 HWs | ✅ |
| UVM verification environment | W4 → W7 | Salemi ch.9–24 | W4–W7 drills | 🟡 (W4 in progress) |

## D. UVM

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| Introduction to UVM | W4 | Salemi ch.9–10 | W4 drill ch.9 (factory) | ✅ |
| Testbench architecture and simulation flow | W4 | Salemi ch.10–11 | W4 OO TB | ✅ |
| Building a UVM environment | W4 | Salemi ch.13 | W4 env demo | ✅ |
| Configuration and overrides | W4 + W6 | Salemi ch.14 + Rosenberg ch.4 | W4 factory override | 🟡 |
| UVM sequences and sequencers | W6 | Salemi ch.20–22 | W6 sequence-driven TB | ⬜ |
| Simulation control and objection mechanism | W4 | Salemi ch.12 (phases) | W4 phases demo | ✅ |
| Connecting to the DUT | W4 + W5 | Salemi ch.13 + Sutherland interfaces | W4 ALU connector | 🟡 |
| Integrating multiple UVCs | W14 + **W20** 🆕 | Rosenberg multi-UVC ch. | W14 multi-UVC; W20 capstone | ⬜ |
| Building a scoreboard | W7 | Salemi ch.24 + Rosenberg ch.6 | W7 scoreboard | ⬜ |
| Advanced UVM and functional coverage | W7 | Rosenberg ch.7–8 | W7 coverage closure | ⬜ |
| Functional coverage and CDV | W3 + W7 + W12 | Spear ch.9 + Rosenberg ch.7 | W3 covergroups; W12 closure | ✅ (W3) |
| Register modeling in UVM (RAL) | W14 + **W20** | Rosenberg RAL ch. | W14 4-reg block; W20 8-reg auto-gen | ⬜ |
| Final UVM project | W12 + W13 + **W20** | All UVM refs | UART-UVM, FIFO-UVM, capstone | ⬜ |

## E. AI Productivity (woven weekly)

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| AI concepts and main models | W1 (intro) | `docs/AI_LEARNING_GUIDE.md` | W1 verify-AI task | ⬜ |
| Generative AI to summarise / learn / develop / visualise | Weekly | `docs/prompts/` | Each week's AI task | ⬜ |
| Prompt engineering and human-in-the-loop | Weekly | `docs/AI_LEARNING_GUIDE.md` §3 | Each week's AI task | ⬜ |
| Using Gemini in Gmail / Docs | W12 + W20 | (recruiter outreach) | W12/W20 power-skill task | ⬜ |
| Principles for effective learning with AI | Weekly | `docs/AI_LEARNING_GUIDE.md` §1 | All weeks | ⬜ |

## F. Power Skills (woven weekly)

| Topic | Week | Reading | Homework | Status |
|---|---|---|---|---|
| Public speaking | W4 + W12 + W20 | `docs/POWER_SKILLS.md` §elevator-pitch | Record 2-min explanations | ⬜ |
| Time and task management | W1 (intro) | `docs/POWER_SKILLS.md` §weekly-cadence | Daily checklist habit | ⬜ |
| Teamwork | W12 + W20 | (project decomposition) | Document handoffs in README | ⬜ |
| Decision making | W19 + W20 | (architecture trade-offs) | `verification_report.md` self-critique | ⬜ |
| Interviewing | W14 + W19 + W20 | `docs/INTERVIEW_PREP.md` | Mock answers per category | ⬜ |
| LinkedIn profile | W2, W6, W10, W14, W18 | `docs/POWER_SKILLS.md` §linkedin | Headline iterations | ⬜ |
| Resume | W3, W7, W11, W15, W19 | `docs/POWER_SKILLS.md` §resume | One bullet per portfolio repo | ⬜ |
| Career-readiness for junior RTL/DV | W20 | `docs/INTERVIEW_PREP.md` + `PORTFOLIO_PROJECTS.md` | Final job-search sprint | ⬜ |

---

## Cross-checks

- Every required syllabus topic above has a Week column. No orphan rows.
- Topics marked **🆕** are net-new in plan 2.0 vs the beta.
- Topics marked ↗ are stretches noted in `INTERVIEW_PREP.md` for after graduation.
- The `tools/check_week_structure.py` script does not yet parse this matrix; that's a polish-PR enhancement.

If you change a week's coverage, **update this matrix in the same
commit**. It is the audit doc that proves the curriculum closes the
syllabus — drift here means stale claims in the repo.
