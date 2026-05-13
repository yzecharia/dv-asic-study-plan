# Progress — 20-Week Master Checklist

Status legend: ⬜ Not started · 🟡 In progress · ✅ Done · 🔍 Needs review · 🚫 Blocked

Auto-regenerable via `python3 tools/update_progress_badges.py`.

**Last bootstrap:** 2026-05-03 (mirrored from StudyPlan beta SHA `43c98a1`).

---

## Phase 1 — SV Fundamentals (W1–W3)

### ✅ Week 1 — SV OOP
- [x] Reading: Spear ch.2 + ch.5 + ch.8 §1–5
- [x] Per-chapter drills (ch.2, ch.5, ch.8)
- [x] HW1 Packet class
- [x] HW2 Transaction hierarchy (read/write subclasses, virtual `display`)
- [x] HW3 Deep copy (shallow vs deep)
- [x] HW4 Virtual methods + `$cast`
- [x] Cheatsheet: `cheatsheets/oop_basics.sv` (symlink) + `cheatsheets/data_types.sv`
- [x] Iron Rule (b) Gold TB PASS log
- [x] Iron Rule (c) `verification_report.md`

### ✅ Week 2 — Constrained Random
- [x] Reading: Spear ch.6 + ch.7 + ch.8 §6–end
- [x] HW1: 10 constraint-block exercises
- [x] HW2: ConstrainedPacket
- [x] HW3: FIFO generator
- [x] HW4: pre/post-randomize hooks (CRC)
- [x] Design: Counter, Sync FIFO RTL + small TB
- [x] Iron Rule (a)/(b)/(c)

### ✅ Week 3 — Coverage & SVA
- [x] Reading: Spear ch.9 + Cummings SNUG-2009 SVA paper
- [x] Verif HW1 FIFO covergroup; HW2 cross coverage; HW3 SVA handshake; HW4 combined
- [x] Design HW1–4: traffic-light FSM, handshake, arbiter, shift register
- [x] Iron Rule (a)/(b)/(c)

---

## Phase 2 — UVM Methodology (W4–W7)

### ✅ Week 4 — UVM Architecture (Salemi ch.9–14)
- [x] Reading: Salemi ch.9–13
- [x] Reading: Salemi ch.14 (in progress per latest commits)
- [x] Verif drill ch.9 — factory pattern (plain SV)
- [x] Verif drill ch.10 — OO testbench (TinyALU)
- [x] Verif drill ch.11 — UVM tests (`hello_uvm_test`)
- [x] Verif drill ch.12 — UVM components (phases)
- [x] Verif drill ch.13 — UVM environments
- [x] Verif connector — ALU UVM TB scaffold
- [ ] Verif big-picture — factory override demo
- [ ] **Design HW1 — ALU DUT** (Dally ch.10 + Sutherland interfaces)
- [ ] **Design HW2 — Ripple-carry adder + CLA**
- [ ] **Design HW3 — Shift-add multiplier + barrel shifter**
- [ ] Iron Rule (a) RTL committed
- [ ] Iron Rule (b) Gold TB PASS log
- [ ] Iron Rule (c) `verification_report.md`

### 🟡 Week 5 — UVM Communication (Salemi ch.15–19)
- [ ] Reading: Salemi ch.15–19
- [ ] Verif: analysis ports, TLM 1.0, reporting
- [ ] Design: Dual-port RAM, RR arbiter, valid/ready handshake
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 6 — UVM Stimulus (Salemi ch.20–23)
- [ ] Reading: Salemi ch.20–23 + Rosenberg ch.4
- [ ] Verif: transactions, agents, sequences
- [ ] Design: parameterised register file, async FIFO theory, direct-mapped cache
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 7 — UVM Full Testbench Integration
- [ ] Reading: Salemi ch.24 + Rosenberg ch.5–8
- [ ] Verif: scoreboard, coverage closure, layered seqs
- [ ] Design: pulse synchroniser, async FIFO RTL, register file
- [ ] Iron Rule (a)/(b)/(c)

---

## Phase 3 — RTL & Architecture (W8–W11)

### ⬜ Week 8 — RISC-V Single-Cycle
- [ ] Reading: Harris & Harris RISC-V ch.7
- [ ] Design HW1–5: decoder, ALU, regfile, imm-gen, single-cycle CPU
- [ ] Verif HW1–2: directed self-check, ALU random+ref-model
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 9 — RISC-V Pipeline + Hazards
- [ ] Reading: Harris & Harris ch.7 §7.5 (pipeline) + ch.7 §7.6 (hazards)
- [ ] Design HW1–4: pipeline regs, forwarding, hazard detect, branch flush
- [ ] Verif HW1–2: hazard regression, pipeline assertion bundle
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 10 — UART
- [ ] Reading: Chu ch.7–9 + Cummings FSM coding paper
- [ ] Design HW1–2: UART top, UART TX with FIFO
- [ ] Verif HW1–3: loopback regression, coverage closure, framing-error injection
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 11 — SPI + AXI-Lite
- [ ] Reading: ARM AMBA AXI spec ch.B (AXI-Lite) + Nandland SPI tutorial
- [ ] Design HW1–3: SPI master, SPI slave model, AXI-Lite slave
- [ ] Verif HW1–2: SPI master TB, AXI-Lite TB
- [ ] Iron Rule (a)/(b)/(c)

---

## Phase 4 — Portfolio + Advanced + Career (W12–W20)

### ⬜ Week 12 — Portfolio: UART-UVM
- [ ] Full UVM env (driver, monitor, agent, scoreboard, RAL-ready)
- [ ] 5 sequences, 5 tests
- [ ] Regression script + coverage closure
- [ ] GitHub-publication-ready README + waveform GIF
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 13 — Portfolio: FIFO-UVM + RISC-V CPU
- [ ] FIFO RTL polish + full UVM TB
- [ ] CPU clean-up + self-check TB
- [ ] Two GitHub-publication-ready repos
- [ ] Iron Rule (a)/(b)/(c) per project

### ⬜ Week 14 — Advanced UVM — RAL + Multi-UVC
- [ ] Hand-written 4-register UVM RAL block
- [ ] `uvm_reg_adapter` to AXI-Lite driver
- [ ] Multi-UVC env with virtual sequencer
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 15 — Design Closure — Synthesis / PPA / FPGA
- [ ] Yosys synthesis on W12 UART + W17 FIR
- [ ] LUT/FF/Fmax report
- [ ] Vivado Basys3 implementation flow
- [ ] `.xdc` constraints written
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 16 — Signed & Fixed-Point Arithmetic 🆕
- [ ] Reading: Dally ch.10 (numbers) + ch.11 (multipliers)
- [ ] Design: Q4.12 saturating MAC + rounding modes
- [ ] Stretch: Booth multiplier
- [ ] Verif: SV class TB + Python golden vectors + sat/round coverage
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 17 — DSP I — 1D FIR Filter 🆕
- [ ] Reading: Dally ch.12 (pipelined arith) + Smith DSP guide ch.15–16 (online)
- [ ] Design: 8-tap symmetric FIR with valid/ready streaming
- [ ] Verif: scipy.signal.lfilter golden + impulse/step/sine coverage
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 18 — DSP II — 2D Image Convolution 🆕
- [ ] Reading: Bailey ch.7 OR Xilinx XAPP933 (online)
- [ ] Design: 3×3 conv with line-buffer + window regfile
- [ ] Verif: PGM-driven TB vs scipy.ndimage.convolve + edge-padding coverage
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 19 — Advanced CDC & Multi-Bit Handshake 🆕
- [ ] Reading: Cummings CDC SNUG-2008 + SVA SNUG-2009
- [ ] Design: 4-phase req/ack handshake + pulse stretcher + multi-ratio async FIFOs
- [ ] Verif: SVA bundle + MTBF write-up + jitter-injection coverage
- [ ] Iron Rule (a)/(b)/(c)

### ⬜ Week 20 — Capstone: RAL + Multi-UVC + System 🆕
- [ ] Top-level SoC-lite (UART + FIFO + reg-block + CDC bridge)
- [ ] Full UVM env: AXI-Lite UVC + UART UVC + RAL (auto-gen from YAML)
- [ ] Virtual sequencer coordinating multi-DUT stimulus
- [ ] Synthesis: Yosys + nextpnr report
- [ ] Final `PORTFOLIO.md` summary + demo video script
- [ ] Iron Rule (a)/(b)/(c)

---

## Cross-cutting weekly counters

- AI productivity tasks completed: **0 / 20** (track starts now under the 2.0 plan)
- Power-skill tasks completed: **0 / 20**
- Concept notes authored / updated: **0 / 36** (foundations PR pending)
- Portfolio repos published on GitHub: **0 / 5** (UART-UVM, FIFO-UVM, RISC-V-CPU, image-conv, capstone)

Update the AI/power counters as you tick items in each week's
`checklist.md`. The badge script does not yet auto-tally these — that
is a polish-PR item.
