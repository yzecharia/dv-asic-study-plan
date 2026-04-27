# Week 9: Pipelined CPU & Hazard Handling

## Why This Matters

Every real CPU is pipelined. Understanding pipeline hazards (data,
control, structural) and their solutions (forwarding, stalling,
flushing) is essential interview knowledge — and the diagrams come
up *every* time. Building a working 5-stage pipeline on top of your
W8 single-cycle CPU proves you understand microarchitecture, not
just RTL syntax.

This week, drills are per-hazard-type. Main HWs are the
incremental pipeline-correctness milestones.

## What to Study

### Reading — Verification

- **Spear & Tumbush ch.4 §4.9** — same minimal SVA chapter as W8;
  use it to write hazard-violation assertions.
- **ChipVerify** — quick reference for `$past`, `$rose`, `$fell`
  used in hazard assertions. (Note: full SVA semantics are
  *outside* Spear's scope — see Sutherland's *SVA Handbook* if you
  want the deep dive.)

### Reading — Design

- **Harris & Harris ch.7.5** ⭐ — pipelined microarchitecture
  (the 5-stage IF/ID/EX/MEM/WB datapath).
- **Harris & Harris ch.7.7** ⭐ — hazards: data hazards, forwarding,
  load-use stall, control hazards, branch prediction.
- **Harris & Harris ch.7.8** — performance analysis (CPI, throughput).
- **Dally & Harting ch.16 — Datapath Sequential Logic**: pipeline
  registers, forwarding muxes — the design building blocks behind
  Harris ch.7.5.
- **Sutherland *SV for Design* ch.6 — Procedural Blocks**:
  `always_ff` for pipeline registers; how to avoid latch inference
  between stages.
- **Sutherland *SV for Design* ch.5 — Arrays, Structures, Unions**:
  packed `struct` for the IF/ID, ID/EX, EX/MEM, MEM/WB pipeline
  bundles.

### Tool Setup

- xsim or iverilog. No new tools — same flow as W8.

---

## Verification Homework

### Drills (per-hazard-type warmups)

> Each drill targets one specific hazard. Small assembly snippets
> + a self-checking TB. ~50 lines each.

- **Drill — RAW (read-after-write) hazard demo (Harris ch.7.7)**
  *File:* `homework/verif/per_chapter/hw_hazard_raw/raw_hazard.s`
  ```
  addi x1, x0, 5
  add  x2, x1, x1   # depends on x1 just written — RAW
  ```
  TB runs this on the W8 single-cycle CPU and on the pipelined
  CPU; confirms single-cycle gets 10, pipelined (without
  forwarding) gets 0 or stale value. This is the motivating
  example for HW2.

- **Drill — Load-use hazard demo (Harris ch.7.7)**
  *File:* `homework/verif/per_chapter/hw_hazard_load_use/load_use.s`
  ```
  lw   x1, 0(x0)
  add  x2, x1, x3   # x1 not ready until end of MEM — needs stall
  ```
  Even with forwarding, this MUST stall 1 cycle. Drill confirms
  stall logic later in HW3.

- **Drill — Control hazard demo (Harris ch.7.7)**
  *File:* `homework/verif/per_chapter/hw_hazard_control/control_hazard.s`
  ```
  beq  x0, x0, target
  addi x1, x0, 99   # FLUSHED
  addi x2, x0, 99   # FLUSHED
  target: addi x3, x0, 1
  ```
  Predict-not-taken + flush on misprediction. Drill confirms the
  next-2-instructions are not committed.

- **Drill — Hazard SVA (Spear §4.9)**
  *File:* `homework/verif/per_chapter/hw_hazard_sva/hazard_sva.sv`
  Light concurrent assertions on the pipeline:
  - `assert property (@(posedge clk) (rd_wb == 0) |-> !reg_write_wb)`
    — never write x0.
  - `assert property (@(posedge clk) stall |=> $stable(pc))`
    — when stall is asserted, PC must hold next cycle.
  Two or three asserts is plenty — Spear barely covers SVA.

### Main HWs

#### HW1: Hazard regression suite
*Folder:* `homework/verif/connector/hw1_hazard_regression/`

A self-checking TB that runs a battery of hazard-trigger programs
through the pipelined CPU (built in DHW1-DHW4) and verifies each
finishes with the right architectural state.

Programs (one .hex / .s each):
- Test A: EX-EX forwarding (back-to-back ALU ops).
- Test B: MEM-EX forwarding (one nop between).
- Test C: load-use stall + forward.
- Test D: branch taken — flush 2 instructions.
- Test E: back-to-back loads with double-forward.
- Test F: store after load (forward to store-data).
- Test G: full integration — `sum 1..10` (final x1 = 55).

TB loads each program, releases reset, runs to completion, reads
expected register values, asserts. Print a final pass/fail summary.

#### HW2: Pipeline-state assertion bundle
*Folder:* `homework/verif/connector/hw2_pipeline_assertions/`

Concurrent SVA bundle on the pipelined CPU:
- x0 is never written.
- PC holds steady whenever `stall` is asserted.
- On a flush, the next two `instruction` outputs at IF must be
  treated as bubbles (i.e., `reg_write` must be 0 for those slots
  by the time they reach WB).
- `mem_read` and `mem_write` are never both asserted.

Run alongside HW1's regression and confirm zero assertion
failures.

### Stretch (optional)

- **Stretch — Branch prediction (Harris ch.7.7 mentions, light
  coverage)**
  Add a 1-bit predictor (history bit per branch PC, small table)
  and re-measure cycles for `test_loop.hex`. Compare against
  predict-not-taken. Harris ch.7.7 mentions branch prediction but
  doesn't go deep — outside-curriculum extension is the
  Patterson & Hennessy ch.4 treatment.

---

## Design Homework

### Drills (per-hazard-type warmups)

- **Drill — Pipeline register module (Harris ch.7.5, Dally ch.16,
  Sutherland ch.5+ch.6)**
  *Folder:* `homework/design/per_chapter/hw_pipe_register/`
  One generic `pipe_reg #(type T)` parameterized on the bundle
  type. Internally one `always_ff` with synchronous flush input
  that zeroes the bundle. Use a packed `struct` (Sutherland ch.5)
  for the bundle types.

- **Drill — Forwarding unit (Harris ch.7.7)**
  *Folder:* `homework/design/per_chapter/hw_forwarding_unit/`
  ```systemverilog
  module forwarding_unit (
      input  logic [4:0] rs1_ex, rs2_ex,
      input  logic [4:0] rd_mem, rd_wb,
      input  logic       reg_write_mem, reg_write_wb,
      output logic [1:0] forward_a, forward_b // 00=reg 01=WB 10=MEM
  );
  ```
  Pure combinational priority logic. MEM beats WB. x0 never
  forwards.

- **Drill — Hazard detection unit (load-use stall)
  (Harris ch.7.7)**
  *Folder:* `homework/design/per_chapter/hw_hazard_detection/`
  ```systemverilog
  module hazard_detection_unit (
      input  logic [4:0] rs1_id, rs2_id,
      input  logic [4:0] rd_ex,
      input  logic       mem_read_ex,
      output logic       stall
  );
  ```
  When the EX-stage instruction is a load AND its destination
  matches either ID source: stall.

- **Drill — Branch unit + flush (Harris ch.7.7)**
  *Folder:* `homework/design/per_chapter/hw_branch_unit/`
  Resolve branches in MEM (simplest), assert `flush` to zero
  IF/ID and ID/EX bundles, mux PC ← branch_target.

### Main HWs

#### HW1: Insert pipeline registers (no hazard logic yet)
*Folder:* `homework/design/connector/hw1_pipeline_registers/`

Take your W8 single-cycle CPU. Add the four pipeline-register
stages between IF/ID/EX/MEM/WB using your pipe-register drill.
Carry across the right signals at each boundary:

- IF/ID: instruction, pc, pc+4
- ID/EX: control bundle, read_data1, read_data2, imm, rd, rs1, rs2,
  pc, pc+4
- EX/MEM: control subset, alu_result, write_data, rd, zero,
  branch_target
- MEM/WB: control subset, alu_result, mem_read_data, rd

Run W8's `test_alu.hex`, `test_loop.hex`. **They will fail.**
Document each failure and identify which hazard caused it. This
is the motivating prework for HW2-HW4.

#### HW2: Add forwarding (EX-EX and MEM-EX)
*Folder:* `homework/design/connector/hw2_forwarding/`

Wire your forwarding-unit drill in. Add forwarding muxes in front
of the ALU operand-A and operand-B inputs, selecting between
register-file output, EX/MEM result, MEM/WB result.

After this, ALU-to-ALU sequences pass; load-use still fails.

#### HW3: Add load-use stall
*Folder:* `homework/design/connector/hw3_stall/`

Wire your hazard-detection-unit drill in. When `stall == 1`:
- Freeze PC (don't update).
- Freeze IF/ID register (don't update).
- Insert a bubble into ID/EX (zero the control bundle).

After this, load-use sequences pass.

#### HW4: Add branch flush
*Folder:* `homework/design/connector/hw4_branch_flush/`

Wire your branch-unit drill in. On a taken branch resolved in MEM,
flush IF/ID and ID/EX (zero the bundles) and select PC ←
branch_target.

After this, all hazard regression tests in VHW1 pass.

### Stretch (optional)

- **Stretch — Resolve branches in ID stage**
  Move branch resolution earlier. Reduces flush penalty from 2
  cycles to 1, but needs new forwarding paths. Harris discusses
  this briefly.

---

## Self-Check Questions

1. What are the three types of hazards? Give an example of each.
2. Why can't forwarding solve the load-use hazard?
3. What's the performance penalty of a branch misprediction in a
   5-stage pipeline?
4. Difference between "predict not taken" and "predict taken"?
5. Draw the pipeline diagram for `lw x1,0(x0); add x2,x1,x3;`
   showing the stall bubble.
6. Could branch resolution move to the ID stage? What changes?

---

## Checklist

### Verification Track
- [ ] Read Spear ch.4 §4.9 (assertion intro)
- [ ] Drill: RAW hazard demo
- [ ] Drill: load-use hazard demo
- [ ] Drill: control hazard demo
- [ ] Drill: hazard SVA bundle
- [ ] HW1: hazard regression (7 programs pass)
- [ ] HW2: pipeline-state assertion bundle
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Harris ch.7.5 (pipelined uarch)
- [ ] Read Harris ch.7.7 (hazards)
- [ ] Read Harris ch.7.8 (perf analysis)
- [ ] Read Dally ch.16 (datapath sequential)
- [ ] Read Sutherland ch.5 (structs for pipeline bundles)
- [ ] Read Sutherland ch.6 (always_ff for pipe registers)
- [ ] Drill: pipe_reg module
- [ ] Drill: forwarding unit
- [ ] Drill: hazard detection unit
- [ ] Drill: branch unit + flush
- [ ] HW1: pipeline registers inserted (W8 tests fail as expected)
- [ ] HW2: forwarding (ALU-ALU passes)
- [ ] HW3: stall (load-use passes)
- [ ] HW4: branch flush (branch tests pass)
- [ ] **MILESTONE: Working pipelined RISC-V CPU.**
