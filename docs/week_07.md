# Week 7: Full UVM Testbench Integration (capstone project)

## Why This Matters

By the end of W6 you've built every UVM piece in isolation: factory,
phases, env, analysis ports, transactions, agents, sequences. This
week you put them together into a **complete production-style**
testbench for a non-trivial DUT (a register file). On the design
side, you tackle the three things that show up in *every* RTL
interview: **timing analysis**, **clock domain crossing**, and the
**asynchronous FIFO**.

There is no new UVM concept this week. The point is integration —
producing a clean, end-to-end testbench you fully understand.

## What to Study

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.24 Onward with the UVM** — the wrap-up; what UVM doesn't
    teach you (RAL, multi-UVC, advanced sequencing) and where to go
    next.
- **Rosenberg & Meade *A Practical Guide to Adopting the UVM* (2nd
  ed.)** — the production-patterns reference. You don't need every
  chapter; pick the ones relevant to your project:
  - **ch.4-5** *Sequences and Stimulus* — production sequence
    patterns: sequence libraries, layered sequences, response
    handling
  - **ch.6** *Driver-Sequencer interface* — pull-mode driver, RSP
    handling, late randomization
  - **ch.8** *Building scoreboards* — reference models, in-order
    vs out-of-order checking
  - Read these as needed during HW3, not back-to-back
- **Verification Academy UVM Cookbook** (free, online):
  - "Scoreboard" recipes
  - "Coverage" recipes
  - "Driver / Sequencer" patterns
- **ChipVerify**: [uvm-scoreboard](https://www.chipverify.com/uvm/uvm-scoreboard),
  [uvm-phases](https://www.chipverify.com/uvm/uvm-phases),
  [uvm-objection](https://www.chipverify.com/uvm/uvm-objection)

### Reading — Design

- **Dally & Harting ch.15 — Timing Constraints** ⭐ — setup/hold,
  clock skew, slack equation. Read before Design HW3.
- **Dally & Harting ch.28 — Metastability and Synchronization
  Failure** — the physics; MTBF; why 1 FF isn't enough
- **Dally & Harting ch.29 — Synchronizer Design** — 2-FF
  synchronizers, pulse synchronizers, gray-code crossings
- **Cliff Cummings** *"Clock Domain Crossing (CDC) Design &
  Verification Techniques Using SystemVerilog"* (SNUG 2008) ⭐ —
  cited in nearly every CDC interview question
- **Cliff Cummings** *"Simulation and Synthesis Techniques for
  Asynchronous FIFO Design"* (SNUG 2002) ⭐ — you read the theory
  in W6; build it now
- **Sutherland *SV for Design* (2nd ed) ch.6 — Procedural Blocks**:
  `always_comb` vs `always_ff` vs `always_latch`, when each is the
  right tool. (Note: previous drafts of this doc cited "ch.9" or
  "ch.13"; the correct chapter is ch.6. The book also has no ch.13
  — *SV for Design* ends at ch.12.)
- **Sutherland *RTL Modeling with SystemVerilog* ch.7-8** — separate
  book, deeper synthesis-aware coding patterns for
  combinational and sequential logic. Use as a tie-breaker reference
  when style questions come up. (This is the "ch.13" people
  sometimes cite — it lives in *RTL Modeling*, not *SV for Design*.)

### Tool Setup

- **Primary**: Vivado xsim via `🧪 FLOW: XSIM UVM`. UVM-capable.
- **Fallback**: EDA Playground.
- Organize files: per-block `_pkg.sv`, top-level interface, `top.sv`.

---

## Verification Homework

### Drills (per-chapter / per-pattern warmups)

- **Drill — uvm_scoreboard**
  *File:* `homework/verif/per_chapter/hw_w7_scoreboard/scoreboard_demo.sv`
  Tiny `dummy_scoreboard extends uvm_scoreboard` with one
  `uvm_analysis_imp #(my_txn, dummy_scoreboard)`, a `write()` that
  bumps `pass_count`/`fail_count`, and a `report_phase` that prints
  the tally. Connect a stub monitor that fires 10 transactions, half
  passing, half failing.

- **Drill — uvm_subscriber covergroup**
  *File:* `homework/verif/per_chapter/hw_w7_coverage/coverage_demo.sv`
  `dummy_coverage extends uvm_subscriber #(my_txn)` with a
  covergroup whose `sample()` is called from `write()`. Print
  `cg.get_coverage()` in `report_phase`.

- **Drill — Reset sequence**
  *File:* `homework/verif/per_chapter/hw_w7_reset_sequence/reset_seq.sv`
  `reset_sequence extends uvm_sequence #(my_txn)` whose `body()`
  drives N reset cycles before sampling begins. This is the
  pattern Rosenberg ch.4 calls a *prologue sequence* — every real
  TB needs one.

### Main HWs

#### HW1: Register file DUT + interface
*Folder:* `homework/design/connector/hw1_register_file/`
(Listed under design too; the Verif HW2/HW3 reuses this.)

```systemverilog
module register_file (
    input  logic        clk, rst_n,
    input  logic        wr_en,
    input  logic [4:0]  wr_addr, rd_addr1, rd_addr2,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data1, rd_data2
);
    // x0 hardwired to 0 (RISC-V convention).
    // 2 read ports + 1 write port.
    // Write-first behavior: read-and-write same addr in same cycle
    // returns the NEW value (forwarding inside the RF).
endmodule
```

Use `always_ff` for the register array, `always_comb` (with the
write-forward MUX) for the read ports.

**Self-test**: a directed TB that writes/reads each register,
including same-cycle write-then-read-same-addr. This is the DUT
for Verif HW2.

#### HW2: Full UVM testbench for the register file ⭐
*Folder:* `homework/verif/connector/hw2_regfile_uvm_tb/`

Build a complete UVM TB using **only** concepts from W4-W6:

- `regfile_item extends uvm_sequence_item` — fields: `wr_en`,
  `wr_addr`, `rd_addr1`, `rd_addr2`, `wr_data`, plus non-rand
  `rd_data1`/`rd_data2` populated by the monitor; full `do_copy`
  / `do_compare` / `convert2string`.
- `regfile_if` — modports for `dut`, `tb`, `monitor`; clocking block.
- `regfile_driver extends uvm_driver #(regfile_item)` — pulls items
  via `seq_item_port`, drives the interface.
- `regfile_monitor extends uvm_monitor` — observes the bus,
  publishes a populated `regfile_item` via `uvm_analysis_port`.
- `regfile_agent extends uvm_agent` — driver + monitor + sequencer,
  active/passive via config object.
- `regfile_scoreboard extends uvm_scoreboard` — keeps a 32-entry
  reference array; on every observed read, predicts and compares.
  In-order checking is fine for this DUT.
- `regfile_coverage extends uvm_subscriber #(regfile_item)` — covers
  every register written, every register read, write-then-read-same
  cross.
- `regfile_env extends uvm_env` — agent + scoreboard + coverage.
- Three tests: `regfile_directed_test`, `regfile_random_test`,
  `regfile_stress_test` (back-to-back with concurrent read-during-
  write).
- Top: instantiate DUT + interface, store the vif via
  `uvm_config_db`, call `run_test()`.

#### HW3: Coverage closure
*Folder:* `homework/verif/connector/hw3_coverage_closure/`

Using the regfile TB:

1. Run each test individually, record functional coverage.
2. Identify the uncovered bins.
3. Write **one new sequence** specifically targeting the holes.
4. Re-run; iterate until 100% functional coverage.
5. Document: what was uncovered, what closed it.

Coverage closure is what real DV engineers spend most of their day
doing.

### Stretch (optional)

- **Stretch — Layered sequences (Rosenberg ch.4-5)**
  *Folder:* `homework/verif/big_picture/layered_sequences/`
  Write a high-level "scenario" sequence that internally calls
  smaller building-block sequences (e.g., `reset → fill → drain`).
  Production-pattern preview before W12.

---

## Design Homework

### Drills (per-chapter warmups)

- **Drill Dally ch.15 — Setup/hold timing**
  *Folder:* `homework/design/per_chapter/hw_dally_ch15_timing/`
  Pen-and-paper. Given Tclk=10ns, Tsetup=0.5ns, Thold=0.3ns,
  Tcq=0.8ns, Tcomb=7ns: compute slack. Repeat with Tclk=8ns and
  Tcomb=8ns — does it close?

- **Drill Dally ch.28 — MTBF intuition**
  *Folder:* `homework/design/per_chapter/hw_dally_ch28_mtbf/`
  Pen-and-paper. Given Tw=0.3ns, Tres=1ns, fclk=200MHz, fdata=50MHz:
  estimate MTBF for a 1-FF synchronizer; for a 2-FF one. Why is
  the 2-FF MTBF much better than 2× longer?

- **Drill Dally ch.29 — 2-FF synchronizer**
  *Folder:* `homework/design/per_chapter/hw_dally_ch29_synchronizer/`
  ```systemverilog
  module sync_2ff #(parameter WIDTH = 1) (
      input  logic clk_dst, rst_n,
      input  logic [WIDTH-1:0] data_in,
      output logic [WIDTH-1:0] data_out);
  ```
  Two back-to-back FFs. Use only for slow-changing level signals.

### Main HWs

#### HW1: Register file DUT (shared with Verif HW2)
*Folder:* `homework/design/connector/hw1_register_file/`
See Verification HW2 for the spec.

#### HW2: Pulse synchronizer
*Folder:* `homework/design/connector/hw2_pulse_synchronizer/`

```systemverilog
module pulse_sync (
    input  logic clk_src, clk_dst, rst_n,
    input  logic pulse_in,    // 1-cycle pulse @ clk_src
    output logic pulse_out    // 1-cycle pulse @ clk_dst
);
```
Toggle-based: flip a flag in the source domain, sync the toggle
into the destination domain via `sync_2ff`, edge-detect the
synced toggle to recreate the pulse. TB drives pulses at varying
gaps and confirms each one arrives exactly once.

#### HW3: Asynchronous FIFO ⭐
*Folder:* `homework/design/connector/hw3_async_fifo/`

```systemverilog
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4    // DEPTH = 2**ADDR_WIDTH (power of 2)
)(
    // write domain
    input  logic                  wr_clk, wr_rst_n, wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    // read domain
    input  logic                  rd_clk, rd_rst_n, rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);
```
Implements the Cummings-paper design exactly:
1. Dual-port RAM for storage (your W5 design HW1 generalizes).
2. Binary write-pointer in `wr_clk` domain, binary read-pointer in
   `rd_clk` domain.
3. Both pointers gray-code-encoded for crossing
   (`gray = bin ^ (bin >> 1)`).
4. 2-FF synchronize each gray pointer into the *other* domain.
5. `full` (in wr domain): synced rd_ptr_gray equals wr_ptr_gray
   with the top two bits inverted.
6. `empty` (in rd domain): synced wr_ptr_gray equals rd_ptr_gray.

TB with asymmetric clocks (e.g., 100 MHz write, 33 MHz read):
fill / drain / continuous / burst-faster-than-drain. Verify FIFO
order and no data corruption.

#### HW4: Critical-path / clock-frequency analysis (paper)
*Folder:* `homework/design/connector/hw4_critical_path/`

For your W4 ALU:
1. Draw the datapath (input regs → operand MUX → adder/AND/OR/XOR
   → output reg). Annotate each block's typical delay.
2. Identify the critical path.
3. Compute the maximum clock frequency.
4. Suggest one pipelining cut that would push fmax up; compute
   new fmax.

Pen-and-paper. This is exactly the analysis a static timing report
makes you do every day in industry.

### Stretch (optional)

- **Stretch — ECC: parity + Hamming(7,4) SECDED**
  *Folder:* `homework/design/big_picture/ecc/`
  Out-of-curriculum (no assigned chapter teaches Hamming codes;
  use Wikipedia + ChipVerify). Add a parity bit per register on the
  W7 register file. Then a standalone Hamming(7,4) encoder/decoder
  that corrects single-bit errors and detects double-bit errors.
  Useful interview talking point but not required.

---

## Self-Check Questions

1. What does `phase.raise_objection` / `drop_objection` actually do
   to the simulation?
2. Why is the scoreboard the right place for the reference model,
   and not the monitor?
3. How do you ensure your testbench supports `run_test("any_test")`
   without recompiling?
4. What is the difference between a 2-FF synchronizer (level) and a
   pulse synchronizer? When do you reach for which?
5. Why must async-FIFO depth be a power of 2 with gray-code
   pointers?
6. Walk through a transaction's full life: where it's created, who
   randomizes it, who drives it, who observes it, who checks it.

---

## Checklist

### Verification Track
- [ ] Read Salemi ch.24 (Onward with the UVM)
- [ ] Read Rosenberg ch.4-6, ch.8 as needed during HW
- [ ] VA Cookbook: scoreboard + coverage recipes
- [ ] Drill: uvm_scoreboard
- [ ] Drill: uvm_subscriber covergroup
- [ ] Drill: reset sequence
- [ ] HW1: register file DUT (shared with design)
- [ ] HW2: full UVM TB for register file
- [ ] HW3: coverage closure
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Dally ch.15 (timing)
- [ ] Read Dally ch.28 (metastability)
- [ ] Read Dally ch.29 (synchronizer design)
- [ ] Read Cummings CDC paper (SNUG 2008)
- [ ] Read Cummings async FIFO paper (SNUG 2002)
- [ ] Read Sutherland *SV for Design* ch.6 (procedural blocks)
- [ ] Drill Dally ch.15 (timing math)
- [ ] Drill Dally ch.28 (MTBF math)
- [ ] Drill Dally ch.29 (2-FF synchronizer)
- [ ] HW1: register file DUT
- [ ] HW2: pulse synchronizer
- [ ] HW3: async FIFO
- [ ] HW4: critical-path analysis
