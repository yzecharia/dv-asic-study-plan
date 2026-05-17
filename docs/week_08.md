# Week 8: RISC-V ISA & Single-Cycle CPU

## Why This Matters

Computer architecture knowledge separates "I can write Verilog" from
"I understand what I'm building." A working RISC-V CPU on your resume
proves you understand datapath, control, instruction decoding, and
memory hierarchy — exactly what Israeli semiconductor companies
(Intel, Marvell, Qualcomm) screen for. RISC-V is also the simplest
real ISA, so it's the right vehicle.

This week is **project-style**: drills are per-component (decoder,
ALU, register file, datapath wiring); main HWs are the integration
into a working CPU.

## What to Study

### Reading — Verification

- **Spear & Tumbush ch.4 §4.9 (assertions overview)** — light SVA on
  the decoder TB (only 3 pages in the book; just enough to assert
  decoder invariants).
- **ChipVerify** — quick tasks/functions reference if you need it
  for the testbench harness.

### Reading — Design

- **Harris & Harris ch.6** ⭐ — RISC-V architecture, RV32I
  instruction formats (R/I/S/B/U/J).
- **Harris & Harris ch.7.1-7.3** ⭐ — single-cycle microarchitecture:
  datapath + control + immediate generation.
- **RISC-V Spec Volume 1** ch.2 — RV32I Base Integer ISA (47
  instructions).
- **Dally & Harting ch.17 — Factoring Finite-State Machines**: how
  to decompose the control unit into small, independently
  verifiable FSMs. (The single-cycle CPU's "FSM" is trivial — just
  a decoder — but ch.17 sets you up for W9's pipeline control.)
  *(Further reading: Harris & Harris ch.3 §3.4.4 — factoring state
  machines.)*
- **Dally & Harting ch.18 — Microcode**: hardwired vs micro-coded
  control; understand the tradeoff.
- **Dally & Harting ch.8 — Combinational Building Blocks**: decoders
  + arbiters; the decoder section is directly applicable. *(Further
  reading: Harris & Harris ch.2 §2.8 — multiplexers & decoders.)*
- **Sutherland *SV for Design* ch.6 — Procedural Blocks, Tasks &
  Functions**: `always_comb`, `always_ff`; the right way to code
  the decoder and the register file.
- **Sutherland *SV for Design* ch.8 — Modeling Finite State
  Machines**: 2-block / 3-block FSM patterns; reference for the
  decoder's `unique case`.
- **Cliff Cummings** *"Full Case / Parallel Case"* — synthesis
  pragma pitfalls (relevant to decoder coding).

### Tool Setup

- xsim or iverilog for RTL simulation.
- Online RISC-V assembler (https://riscvasm.lucasteske.dev/) to
  hand-encode the test programs in HW4.

---

## Verification Homework

### Drills (per-chapter warmups)

> Light per-component testbench drills. Each ~30-60 lines.

- **Drill — Decoder TB skeleton (Harris ch.6)**
  *File:* `homework/verif/per_chapter/hw_riscv_decoder_tb/decoder_tb.sv`
  Drive 6 known instruction encodings (one per format: ADD, ADDI,
  SW, BEQ, LUI, JAL) into your decoder and `$display` all output
  fields. This is just a "does my decoder output match the green
  card" smoke test.

- **Drill — ALU directed corners (Harris ch.7.1)**
  *File:* `homework/verif/per_chapter/hw_riscv_alu_corners/alu_tb.sv`
  Hit each ALU op once with a corner pair: `0+0`, `MAX_INT+1`,
  `MIN_INT-1`, `-1 SLT 0`, `-1 SLTU 0`, `1 SLL 31`, `0xFFFF_FFFF
  SRA 1`. Compare against hand-computed expected values.

- **Drill — Register file read/write (Harris ch.7.1)**
  *File:* `homework/verif/per_chapter/hw_riscv_regfile_tb/regfile_tb.sv`
  Write x1=5, x2=10, read both back, then write x0=42 and verify
  reads as 0. Same-cycle write+read on the same register is the
  one tricky case.

- **Drill — SVA on decoder (Spear ch.4 §4.9)**
  *File:* `homework/verif/per_chapter/hw_decoder_sva/decoder_sva.sv`
  One-line concurrent assertions on your decoder: e.g., "if
  `opcode == OPCODE_R`, then `reg_write == 1` and `mem_write ==
  0`". Three or four such asserts. (SVA is barely covered in
  Spear — this is the ceiling for what the assigned chapter
  supports.)

### Main HWs

#### HW1: Per-instruction directed self-check tests
*Folder:* `homework/verif/connector/hw1_riscv_directed_tests/`

Hand-write small RV32I assembly programs (or hex) that each exercise
one feature, and a self-checking testbench that loads each program
into instruction memory, runs to completion, and checks a known
register/memory location for the expected result.

Programs to write (one .hex each):
- `test_alu.hex` — ADD, SUB, AND, OR, XOR; final state has
  expected values in x3..x6.
- `test_memory.hex` — SW then LW round-trips a value through
  data memory.
- `test_branches.hex` — BEQ taken vs not-taken.
- `test_loop.hex` — sum 1..10 via loop; final x1 = 55.

Testbench writes the program into `instruction_memory`, releases
reset, waits N cycles, then `$readmemh`s data memory / `force`s
to read register file and asserts the expected values.

#### HW2: ALU randomized + reference-model TB
*Folder:* `homework/verif/connector/hw2_alu_random_tb/`

Wrap your `rv32i_alu` in a randomized testbench (plain SV, no UVM
yet — UVM ALU TB lives in W12):
- Random `a`, `b`, `alu_control` for 1000 cycles.
- A reference model in plain SV (`function automatic [31:0]
  alu_ref(...)`) computes the expected result.
- Scoreboard `assert(dut_result == ref_result)`.
- Cover all 10 ALU ops × {zero/non-zero result} via a covergroup.

This is the standard "DUT vs golden function" pattern. You'll
re-do it in UVM in W12.

### Stretch (optional)

- **Stretch — Compliance test snippet (outside chapter scope)**
  Run one or two tests from the
  [riscv-tests](https://github.com/riscv/riscv-tests) repo against
  your CPU. This is what real RISC-V verification looks like.
  Outside Harris's scope — for interview talking points.

---

## Design Homework

### Drills (per-component warmups)

- **Drill — RV32I instruction decoder (Harris ch.6)**
  *Folder:* `homework/design/per_chapter/hw_riscv_decoder/`
  Standalone `rv32i_decoder` module per the port list below.
  Supports R/I/S/B/U/J. Use `enum`s for opcodes/funct3/funct7
  (Sutherland ch.4) and `unique case` in `always_comb`
  (Sutherland ch.6 + Cummings paper).

  ```systemverilog
  module rv32i_decoder (
      input  logic [31:0] instruction,
      output logic [6:0]  opcode,
      output logic [4:0]  rd, rs1, rs2,
      output logic [2:0]  funct3,
      output logic [6:0]  funct7,
      output logic [31:0] imm,           // sign-extended immediate
      output logic [3:0]  alu_control,   // decoded ALU operation
      output logic        reg_write, mem_write, mem_read,
      output logic        branch, jump,
      output logic [1:0]  alu_src        // ALU operand-B source
  );
  ```

- **Drill — RV32I ALU (Harris ch.7.1)**
  *Folder:* `homework/design/per_chapter/hw_riscv_alu/`
  ```systemverilog
  module rv32i_alu (
      input  logic [31:0] a, b,
      input  logic [3:0]  alu_control,
      output logic [31:0] result,
      output logic        zero, negative, overflow
  );
  ```
  Operations: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU.
  SLT vs SLTU is the easy mistake — handle signedness explicitly.

- **Drill — Register file (Harris ch.7.1, Dally ch.16)**
  *Folder:* `homework/design/per_chapter/hw_riscv_regfile/`
  32 × 32-bit register file, 2 read ports + 1 write port, x0
  hardwired to 0. Use `always_ff` for the write port (Sutherland
  ch.6).

- **Drill — Immediate generator (Harris ch.6)**
  *Folder:* `homework/design/per_chapter/hw_riscv_immgen/`
  Extracts and sign-extends the I/S/B/U/J-format immediates. Pure
  combinational. The trickiest part of the decoder — give it its
  own module.

- **Drill — Control unit / FSM factoring (Dally ch.17)**
  *Folder:* `homework/design/per_chapter/hw_control_factoring/`
  Re-read ch.17 and write a 1-page note: how would the
  single-cycle "control" (just a decoder) extend into the
  pipelined-CPU control (W9)? Identify which signals stay
  combinational and which become per-stage registered.

### Main HWs

#### HW1: Single-cycle RV32I datapath integration
*Folder:* `homework/design/connector/hw1_single_cycle_cpu/`

Wire all the drill modules into a working single-cycle CPU per
Harris ch.7.1-7.3:

```
Instruction  ----> [Decoder] -----> control
Memory                                  |
   ^                                    v
+------+   +-------+   +--------+   +-----+   +---------+
|  PC  |-->| I-Mem |-->| RegFile|-->| ALU |-->| D-Mem   |
+------+   +-------+   +--------+   +-----+   +---------+
   ^                                    |
   +-------- PC+4 / branch <------------+
```

Modules:
1. `program_counter` — PC register, reset to 0.
2. `instruction_memory` — ROM, `$readmemh`-loaded.
3. `register_file` — your drill module.
4. `rv32i_decoder` + `imm_generator` + `rv32i_alu` — your drills.
5. `data_memory` — RAM for loads/stores.
6. `rv32i_top` — top-level wire-up.

Run all four `test_*.hex` programs from VHW1 and confirm the
expected post-conditions.

#### HW2: Documentation pass
*Folder:* `homework/design/connector/hw2_docs/`

Industry-style doc pass on your CPU:
- Block diagram (PNG or ASCII) showing all modules + signals.
- 1-page per module: ports, behavior, key design choices.
- Coding-standard sweep: every module uses `always_ff` for
  registers and `always_comb` for combinational logic
  (Sutherland ch.6); enums for opcodes/control encodings
  (Sutherland ch.4); no latches.

### Stretch (optional — outside chapter scope)

- **Stretch — Signed / fixed-point / saturating arithmetic
  (outside curriculum)**
  Dally ch.10 §10.1-10.4 covers signed two's complement and
  overflow detection (in scope for W3 already). Q-format
  fixed-point and saturating arithmetic are NOT in any assigned
  chapter — skip unless you want interview ammo for AI/DSP roles.
  External refs: Wikipedia "Q (number format)"; ChipVerify
  "SystemVerilog signed and unsigned".

  If you do it, add three small modules to
  `homework/design/big_picture/signed_fixed_point/`:
  1. `signed_mul.sv` — full 64-bit signed product.
  2. `qmul.sv` — Q15.16 × Q15.16 → Q15.16 with rounding.
  3. `sat_add.sv` — saturating signed 16-bit add.

---

## Self-Check Questions

1. What are the 6 RISC-V instruction formats? Draw each one with
   bit fields.
2. Why is x0 hardwired to zero? What problem does it solve?
3. How does the immediate encoding differ between I-type, S-type,
   and B-type?
4. What control signals distinguish ADD from SUB? (Hint: funct7.)
5. What's the critical path of a single-cycle CPU?
6. Why is single-cycle impractical for real CPUs? (preview for W9)

---

## Checklist

### Verification Track
- [ ] Read Spear ch.4 §4.9 (assertion intro)
- [ ] Drill: decoder TB skeleton
- [ ] Drill: ALU directed corners
- [ ] Drill: regfile read/write
- [ ] Drill: SVA on decoder
- [ ] HW1: per-instruction directed self-check tests
- [ ] HW2: ALU randomized + ref-model TB
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Harris ch.6 (architecture / ISA)
- [ ] Read Harris ch.7.1-7.3 (single-cycle uarch)
- [ ] Read RISC-V spec ch.2 (RV32I)
- [ ] Read Dally ch.8 (combinational building blocks)
- [ ] Read Dally ch.17 (FSM factoring)
- [ ] Read Dally ch.18 (microcode vs hardwired)
- [ ] Read Sutherland ch.6 (procedural blocks)
- [ ] Read Sutherland ch.8 (FSM modeling)
- [ ] Read Cummings full-case/parallel-case paper
- [ ] Drill: decoder module
- [ ] Drill: ALU module
- [ ] Drill: register file module
- [ ] Drill: immediate generator
- [ ] Drill: control-factoring write-up
- [ ] HW1: single-cycle CPU integration + 4 hex tests pass
- [ ] HW2: documentation pass

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_08_riscv_single_cycle/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 8 — Week 8: RISC-V ISA & Single-Cycle CPU

> **Phase 3 — RTL & Architecture** · canonical syllabus: [`docs/week_08.md`](../docs/week_08.md) · ⬜ Not started

Computer architecture knowledge separates "I can write Verilog" from
"I understand what I'm building." A working RISC-V CPU on your resume
proves you understand datapath, control, instruction decoding, and
memory hierarchy — exactly what Israeli semiconductor companies
(Intel, Marvell, Qualcomm) screen for. RISC-V is also the simplest
real ISA, so it's the right vehicle.

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

Canonical syllabus: [`docs/week_08.md`](../docs/week_08.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 8 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_08.md`](../docs/week_08.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 2 — Flashcards (RV32I instruction encodings)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

LinkedIn — RISC-V learning post (one paragraph + a snippet)

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 8 — Homework

The canonical homework list lives at
[`docs/week_08.md`](../docs/week_08.md). When you start
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
cd week_08_*

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

# Week 8 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_08.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_08.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 2 — Flashcards (RV32I instruction encodings)
- [ ] **Power-skill task** — LinkedIn — RISC-V learning post (one paragraph + a snippet)
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 8 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

