# Portfolio Projects

The five projects you publish from this curriculum. Three flagships
(W12, W13×2, W20) and two supporting (W18, W19). Each lives as its
own GitHub repo, linked from this file and from your resume's
**Projects** section.

This is the doc a recruiter or hiring engineer should land on first.
If something here looks impressive, the rest of the repo backs it up
with the daily homework, notes, and tests that produced it.

---

## Project pitches (1 sentence each)

| # | Project | Source week | One-line pitch |
|---|---|---|---|
| 1 | **UART-UVM** | W12 | A configurable UART RTL block verified with a full UVM environment — driver, monitor, scoreboard, 5 sequences, 3 tests, 100% functional coverage closure including framing-error injection. |
| 2 | **FIFO-UVM** | W13 | A parameterized synchronous FIFO with a UVM testbench whose scoreboard uses a SystemVerilog queue as a reference model and SVA assertions for full/empty boundary safety. |
| 3 | **RISC-V CPU (RV32I)** | W13 | A 5-stage pipelined RV32I subset with forwarding and hazard detection, verified via a directed self-checking suite and constrained-random ALU regression against a Python reference. |
| 4 | **2D Image Convolution** 🆕 | W18 | A 3×3 hardware convolution engine with line-buffer architecture, verified against scipy.ndimage with edge-padding coverage and Q1.15 fixed-point reference. |
| 5 | **Multi-UVC RAL Capstone** 🆕 | W20 | A SoC-lite top integrating UART + FIFO + register block + CDC bridge, verified by a multi-UVC UVM env with auto-generated RAL model and virtual-sequencer-coordinated stimulus. |

---

## Per-project specs

### Project 1 — UART-UVM (W12)

**Goal**: prove you can build a production-pattern UVM env.

**RTL**: UART top with TX FSM, RX FSM (16× oversampling), baud-rate
generator, optional FIFO buffer.

**Verification**:
- Driver, monitor, agent, sequence, sequencer, scoreboard.
- 5 sequences: random TX, back-to-back stress, framing-error injection
  (inject early stop bit), parity flip, baud-rate sweep.
- 3 tests: smoke, regression, error injection.
- Functional coverage on baud rates × parity modes × payload byte
  values × inter-byte gaps × framing-error events.
- SVA bundle for handshake and framing.

**Iron-Rule deliverables**: lint-clean RTL, 3 tests with PASS log
captured, `verification_report.md` summarising methodology and
coverage holes.

**README needed**: block diagram, waveform GIF, coverage report
screenshot, run commands.

**What it shows employers**: you can write production-style UVM, you
understand coverage closure, you can debug from waveform.

---

### Project 2 — FIFO-UVM (W13 first half)

**Goal**: prove parametric/scalable verification.

**RTL**: parameterized synchronous FIFO with depth and width as
parameters; almost-full / almost-empty thresholds; clean reset
behaviour.

**Verification**:
- UVM env with reference model (SV queue).
- Sequences: writes-only, reads-only, concurrent, full-and-back,
  empty-and-back.
- SVA for: full→no-write-accepted, empty→no-read-valid, monotonic
  pointer behaviour, count consistency.
- Coverage on `(write,read)` cross × occupancy bins.

**Iron-Rule deliverables**: same as Project 1.

**README needed**: param sweep results (e.g., a table showing
coverage at depth 4, 8, 16, 64).

**What it shows employers**: you understand coverage scaling and
reference-model design — both NVIDIA-tier expectations.

---

### Project 3 — RISC-V CPU (W13 second half)

**Goal**: prove computer-architecture depth.

**RTL**: 5-stage pipelined RV32I subset (instructions: `ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU`, immediates, loads, stores, branches, JAL/JALR). Forwarding from EX/MEM and MEM/WB. Hazard detection unit with bubble insertion. Branch flush on taken branches.

**Verification**:
- Directed self-check tests: hand-written assembly programs whose
  expected register state is checked at end of run.
- Constrained-random ALU regression against a Python reference
  (`riscv-py` or hand-rolled).
- Hazard regressions: load-use, RAW between consecutive ops, control
  hazard on taken branch.
- SVA bundle on pipeline-register propagation.

**Iron-Rule deliverables**: same. The PASS log includes a regression
summary.

**README needed**: instruction list, pipeline diagram, hazard
examples with waveforms.

**What it shows employers**: you understand the actual bone of CPU
design, not just toy single-cycle ALUs.

---

### Project 4 — 2D Image Convolution (W18) 🆕

**Goal**: prove signal-processing-on-hardware fluency.

**RTL**: 3×3 streaming convolution engine. Two row line-buffers
(BRAM-style), 3×3 window register file, parameterizable kernel
(default Sobel; Gaussian and sharpen as alternates), Q1.15
coefficients, valid/ready streaming I/O.

**Verification**:
- TB drives a 64×64 PGM grayscale image (committed as test
  fixture).
- Reference = `scipy.ndimage.convolve` with the same kernel; pixel-
  level diff with Q1.15 tolerance.
- Coverage on edge-padding modes (zero-pad / mirror / clamp).

**Iron-Rule deliverables**: same.

**README needed**: input image, output image, kernel sweep
demonstration, brief math derivation of why line-buffer architecture
is correct.

**What it shows employers**: you can take a math problem and turn it
into a synthesisable streaming pipeline. This is the kind of demo
that catches recruiters from companies like NVIDIA / Apple Silicon
imaging teams.

---

### Project 5 — Multi-UVC RAL Capstone (W20) 🆕

**Goal**: prove integration-level verification ability.

**RTL** (top-level SoC-lite): instantiates the W12 UART core, the W13
FIFO core, an 8-register AXI-Lite control block, and a W19-style CDC
bridge between two clock domains.

**Verification**:
- Full UVM environment with: AXI-Lite UVC, UART UVC, RAL model
  auto-generated from a YAML register description (Python script
  generates the SystemVerilog package).
- Virtual sequencer coordinating stimulus across UVCs (e.g.,
  configure baud-rate via AXI register, then TX a payload, then read
  status register to confirm).
- Cross-DUT scoreboarding: RAL writes propagate to UART config →
  observable in UART traffic.

**Synthesis side**: Yosys + nextpnr (open-source flow) on the UART
and FIFO cores, with `synth_report.md` documenting LUT, FF, Fmax. A
stretch retiming pass on the FIR core (W17 reuse).

**Iron-Rule deliverables**: same. Plus the synthesis report and a
**5-minute demo video script** (record optional but planned).

**README needed**: top block diagram, register map (auto-rendered
from YAML), virtual-sequencer flow diagram, synth report excerpt.

**What it shows employers**: you've done a small but real SoC. RAL +
multi-UVC is the single most CV-impactful demo from this curriculum.

---

## Per-project README template

Every published repo's `README.md` follows this template:

```
# <Project Name>

> One-sentence pitch. The kind that reads well as a LinkedIn project line.

## What this proves

- 2-3 bullets of senior-engineer-grade claims, each backed by code
  the reader can find.

## Block diagram

![block](docs/block_diagram.png)

## Waveform demo

![waveform](docs/waveform.gif)

## How to run

```
git clone …
cd <project>
make sim       # or specific run command
```

## Verification methodology

- Coverage model
- Reference model location
- SVA bundle location
- How to read the regression report

## Files

- `rtl/` — synthesisable RTL
- `tb/` — testbench
- `docs/` — block diagram, register map, etc.
- `verification_report.md` — written self-critique

## What's not done

- Honest list of known holes / scope cuts. (Senior engineers respect this.)

## Resources

- Books / papers / tutorials cited.

## License

MIT.
```

The `What's not done` section is non-negotiable. It's what separates
"I'm a junior with self-awareness" from "I'm a junior with claims."

---

## Demo video script (W20)

5 minutes, screen-share format. Outline:

- **0:00–0:30** — Hook. "I built a SoC-lite with UART + FIFO + CDC
  bridge, verified by a multi-UVC UVM environment with an auto-
  generated RAL."
- **0:30–1:30** — Block diagram on screen. Walk through DUT and TB
  layers.
- **1:30–3:00** — Live: kick off a regression. Show RAL config writes
  → UART traffic → scoreboard PASS log.
- **3:00–4:00** — Open `verification_report.md`. Read aloud the
  coverage closure paragraph and the what-didn't-work section.
- **4:00–5:00** — Synthesis side: open Yosys report, point to the
  Fmax number and the critical path. Wrap.

Embed the video link from W20's `README.md`.

---

## Status

| # | Project | RTL | UVM env | README | Synth | Published |
|---|---|---|---|---|---|---|
| 1 UART-UVM | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 2 FIFO-UVM | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 RISC-V CPU | ⬜ | ⬜ | ⬜ | ⬜ | n/a | ⬜ |
| 4 2D Conv 🆕 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 5 Capstone 🆕 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

Update this table as each milestone completes.
