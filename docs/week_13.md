# Week 13: Portfolio Projects #2 & #3 — FIFO UVM + RISC-V CPU

## Why This Matters

Three GitHub repos is the magic number — it shows consistency, not
a one-off. The **FIFO UVM** project shows you can verify any block
from scratch. The **RISC-V CPU** shows architectural depth.
Together with the W12 UART, you have a portfolio that stands out
from other junior candidates.

This week pairs the rest of Salemi (ch.21-23 patterns) with
Rosenberg ch.4-9 to consolidate UVM idioms across two distinct
DUTs.

## What to Study

### Reading — Verification

- **Salemi *UVM Primer* ch.20-24** — refresher (same chapters as
  W12).
- **Rosenberg & Meade**:
  - **ch.4-5** — sequences, virtual sequences, sequence libraries.
  - **ch.6** — driver/sequencer.
  - **ch.8** — scoreboards (especially the queue-based reference
    model used here).
  - **ch.9** — stimulus / sequence layering.
- **Spear & Tumbush ch.6 — Randomization**: refresher for the
  FIFO sequence's `dist` constraints and `solve...before`.
- **Spear & Tumbush ch.9 — Functional Coverage**: the FIFO
  state-transition coverage in HW2 below.
- **Verification Academy** UVM Cookbook — *Sequences*,
  *Scoreboards*.

### Tool Setup

- xsim with `-L uvm`.
- Same `+UVM_TESTNAME` convention as W12.

---

## Project A: Synchronous FIFO with UVM Testbench

This is the new RTL+UVM build for W13.

### Drills (per-component warmups)

- **Drill — `fifo_seq_item` with dist constraints
  (Salemi ch.21, Spear ch.6)**
  *File:* `homework/verif/per_chapter/hw_fifo_seq_item/fifo_item.sv`
  ```systemverilog
  typedef enum {PUSH, POP, BOTH, IDLE} fifo_op_e;
  class fifo_seq_item extends uvm_sequence_item;
      `uvm_object_utils(fifo_seq_item)
      rand fifo_op_e         op;
      rand bit [DATA_W-1:0]  wr_data;
      constraint c_op { op dist {PUSH:=4, POP:=4, BOTH:=1, IDLE:=1}; }
  endclass
  ```

- **Drill — `fifo_driver` (Salemi ch.23, Rosenberg ch.6)**
  *File:* `homework/verif/per_chapter/hw_fifo_driver/fifo_driver.sv`
  Translates `op` → `wr_en`, `rd_en` toggles for one cycle.

- **Drill — `fifo_monitor` (Salemi ch.16)**
  *File:* `homework/verif/per_chapter/hw_fifo_monitor/fifo_monitor.sv`
  Samples `wr_en`, `rd_en`, `wr_data`, `rd_data`, `full`, `empty`,
  `count` every cycle; emits a `fifo_observation` to analysis
  port.

- **Drill — Reference-model scoreboard (Rosenberg ch.8)**
  *File:* `homework/verif/per_chapter/hw_fifo_scb/fifo_scb.sv`
  ```systemverilog
  logic [DATA_W-1:0] ref_q[$];
  function void write(fifo_observation o);
      case (o.op)
          PUSH: if (ref_q.size() < DEPTH) ref_q.push_back(o.wr_data);
                else assert(o.overflow);
          POP:  if (ref_q.size() > 0) begin
                    expected = ref_q.pop_front();
                    assert(o.rd_data == expected);
                end else assert(o.underflow);
          BOTH: ...
      endcase
  endfunction
  ```

- **Drill — FIFO state-transition coverage (Spear ch.9)**
  *File:* `homework/verif/per_chapter/hw_fifo_cov/fifo_cov.sv`
  Covergroup with `count` cross with `op`, plus state-transition
  bins: empty→nonempty, nonempty→full, full→nonempty,
  nonempty→empty. Coverage on overflow / underflow flags.

### Main HWs

#### HW-A1: FIFO RTL
*Folder:* `homework/design/connector/hwA1_sync_fifo/`

```systemverilog
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  logic                       clk, rst_n,
    input  logic                       wr_en, rd_en,
    input  logic [DATA_WIDTH-1:0]      wr_data,
    output logic [DATA_WIDTH-1:0]      rd_data,
    output logic                       full, empty,
    output logic                       overflow, underflow,
    output logic [$clog2(DEPTH):0]     count
);
```

- Circular buffer + read/write pointers.
- Full when `count == DEPTH`; empty when `count == 0`.
- Overflow/underflow flags for write-when-full / read-when-empty
  (don't actually corrupt data — just flag).
- Simultaneous read+write is legal; `count` stays the same.

This is mostly a refresher of W2/W4 design idioms — Pong Chu ch.4
is the textbook source for the basic FIFO buffer pattern.

#### HW-A2: FIFO UVM env + tests
*Folder:* `homework/verif/connector/hwA2_fifo_uvm/`

Project layout (this is what gets pushed to GitHub):
```
fifo-uvm-verification/
    rtl/sync_fifo.sv
    tb/
        fifo_pkg.sv, fifo_if.sv, fifo_seq_item.sv,
        fifo_driver.sv, fifo_monitor.sv, fifo_agent.sv,
        fifo_scoreboard.sv, fifo_coverage.sv,
        fifo_env.sv, fifo_sequences.sv, fifo_tests.sv,
        tb_top.sv
    sim/Makefile
    README.md
```

Six tests (each extends `fifo_base_test`):
- `fifo_fill_drain_test` — fill to full, drain to empty.
- `fifo_random_test` — 10000 random ops.
- `fifo_stress_test` — push+pop (BOTH) at various fill levels.
- `fifo_overflow_test` — push beyond capacity; assert `overflow`.
- `fifo_underflow_test` — pop when empty; assert `underflow`.
- `fifo_coverage_test` — runs until coverage = 100%.

#### HW-A3: README + push to GitHub
*Folder:* `homework/verif/connector/hwA3_fifo_readme/`

Standard README (overview, architecture diagram, results table,
how-to-run). Push the repo.

---

## Project B: RISC-V Pipelined CPU (clean-up + publish)

The CPU itself was built in W8/W9. This project takes that code,
adds a self-checking testbench, polishes documentation, and
publishes it. **There is no UVM here** — the CPU TB is plain SV
self-checking + assertions, because building a UVM env around a
multi-instruction CPU is a multi-week project that's outside scope
for the curriculum (real CPU UVM uses RVFI / co-simulation against
spike, which is W14+ territory).

### Drills

- **Drill — Self-checking program harness (Spear ch.4 §4.9 +
  Harris ch.7.5)**
  *File:* `homework/verif/per_chapter/hw_cpu_self_check/harness.sv`
  Convention: every test program writes its result to a known
  memory address (`tohost`). The TB monitors that address; on
  write, compares against expected.

- **Drill — CPU invariant SVA (Spear §4.9)**
  *File:* `homework/verif/per_chapter/hw_cpu_sva/cpu_sva.sv`
  - `assert property (@(posedge clk) (rd_wb == 0) |-> !reg_write_wb)`
    — x0 never written.
  - `assert property (@(posedge clk) !$isunknown(pc))` — PC
    never X.
  - `assert property (@(posedge clk) !(mem_read && mem_write))`
    — never both.

### Main HWs

#### HW-B1: Project clean-up
*Folder:* `homework/design/connector/hwB1_cpu_cleanup/`

Reorganize your W8+W9 RISC-V code into the publish layout:
```
riscv-sv-cpu/
    rtl/
        rv32i_top.sv, program_counter.sv, instruction_memory.sv,
        register_file.sv, rv32i_decoder.sv, rv32i_alu.sv,
        imm_generator.sv, data_memory.sv, forwarding_unit.sv,
        hazard_detection_unit.sv, branch_unit.sv,
        pipe_register.sv
    tb/
        rv32i_tb.sv
        cpu_sva.sv
        test_programs/
            test_alu.hex, test_memory.hex, test_branch.hex,
            test_hazards.hex, test_sum_1_to_10.hex
    sim/Makefile
    docs/pipeline_diagram.png, datapath.png
    README.md
```

#### HW-B2: Self-checking testbench
*Folder:* `homework/verif/connector/hwB2_cpu_tb/`

- All W8/W9 hex tests use the `tohost` self-check convention.
- The TB instantiates `cpu_sva` (asserts).
- `make run TEST=test_sum_1_to_10` prints PASS / FAIL.
- `make all` runs the whole regression and prints a results
  table.

#### HW-B3: README + diagrams + publish
*Folder:* `homework/verif/connector/hwB3_cpu_readme/`

- Pipeline diagram (PNG, hand-drawn or drawio).
- Datapath block diagram.
- README with: overview, architecture diagram, supported
  instructions table, test results, how-to-run.
- Push to GitHub as `riscv-sv-cpu`.

### Stretch (optional)

- **Stretch — RVFI co-simulation (outside curriculum)**
  Wire RVFI signals out of your CPU and compare against
  `riscv/sail-riscv` or `spike`. This is a real-industry pattern
  for CPU verification but outside the W8/W9 textbook scope —
  flag it as bonus.

---

## Final Steps: Update CV & LinkedIn

### Update `plain_text_resume.yaml`

```yaml
projects:
  - name: "UART with UVM Verification"
    description: "Designed UART TX/RX IP and built a full UVM
      testbench (constrained-random, coverage-driven, ref-model
      scoreboard). 100% functional coverage."
    link: "https://github.com/YOUR_USERNAME/uart-uvm-verification"
  - name: "Synchronous FIFO with UVM Verification"
    description: "Parameterized synchronous FIFO with full UVM
      testbench, queue-based ref model, overflow/underflow
      verification, 100% functional coverage."
    link: "https://github.com/YOUR_USERNAME/fifo-uvm-verification"
  - name: "RISC-V RV32I Pipelined CPU"
    description: "5-stage pipelined RISC-V processor with
      forwarding, hazard detection, branch flush. Self-checking
      assembly regression."
    link: "https://github.com/YOUR_USERNAME/riscv-sv-cpu"
```

### Update LinkedIn
- Add all 3 projects.
- Skills: UVM, SystemVerilog Verification, Constrained Random,
  Functional Coverage, RISC-V.

### Update AutoApply Bot
- Update `data_folder/plain_text_resume.yaml`.
- Restart the bot — it will now include your projects.

---

## Self-Check Questions

1. Why does the FIFO scoreboard use a `[$]` queue instead of an
   array?
2. What's the difference between the FIFO `BOTH` op behavior and
   sequential push-then-pop? When does count change vs not?
3. In the CPU TB, why is `tohost` the standard self-check
   convention rather than reading the register file directly?
4. What invariants does `cpu_sva` enforce, and which ones would
   FAIL under a real bug you might introduce?
5. Why isn't there a UVM env for the CPU in this week?
6. What's the right way to handle "coverage already 100% from a
   single test" — drop the other tests, or keep them?

---

## Checklist

### Project A: FIFO UVM
- [ ] Read Salemi ch.20-24 (refresher)
- [ ] Read Rosenberg ch.4-9
- [ ] Read Spear ch.6 (random) + ch.9 (coverage) refresher
- [ ] Drill: fifo_seq_item
- [ ] Drill: fifo_driver
- [ ] Drill: fifo_monitor
- [ ] Drill: fifo_scoreboard (queue ref model)
- [ ] Drill: fifo_coverage
- [ ] HW-A1: FIFO RTL
- [ ] HW-A2: FIFO UVM env + 6 tests, all pass, coverage 100%
- [ ] HW-A3: README + GitHub push

### Project B: RISC-V CPU
- [ ] Drill: self-check program harness
- [ ] Drill: CPU invariant SVA
- [ ] HW-B1: project clean-up
- [ ] HW-B2: self-checking TB + assertions
- [ ] HW-B3: README + diagrams + GitHub push

### Profile Updates
- [ ] plain_text_resume.yaml updated
- [ ] LinkedIn profile updated
- [ ] GitHub has 3 repos with READMEs
- [ ] AutoApply bot restarted

---

## Congratulations

You now have:
- SystemVerilog verification skills (OOP, constrained random,
  coverage, assertions).
- UVM methodology (full testbench from scratch, twice).
- Computer architecture knowledge (pipelined RISC-V CPU).
- Protocol experience (UART, SPI, AXI-Lite).
- 3 GitHub portfolio projects.

You are ready for junior DV/FPGA/ASIC interviews in Israel. Good
luck.
