# Week 6: UVM Stimulus — Transactions, Agents, Sequences

## Why This Matters

After this week the architectural picture is complete:

- **Transactions** (ch.20-21) — proper data carriers with deep ops
  (`do_copy`, `do_compare`, `convert2string`).
- **Agents** (ch.22) — the standard packaging of monitor + driver +
  ... around a single interface; active vs passive.
- **Sequences** (ch.23) — the *defining* UVM feature: stimulus
  generation **decoupled** from the testbench structure. Same env,
  any stimulus.

Important sequencing: Salemi introduces **`uvm_transaction`** in
ch.21. The class **`uvm_sequence_item`** doesn't appear until ch.23.
The HW below respects that order — don't try to skip ahead.

## What to Study (Salemi ch.20-23)

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.20 Class Hierarchies and Deep Operations** ⭐ — the lions
    return: `convert2string` and `do_copy` written *deeply* using
    `super.<method>` so each class only handles its own fields. The
    `do_copy` argument type trick (always take the base class +
    `$cast` inside) is the headline technique.
  - **ch.21 UVM Transactions** ⭐ — `command_transaction extends
    uvm_transaction`, with `do_copy`, `do_compare`,
    `convert2string`. The randomization (`rand` fields, simple
    constraint) replaces the get_op / get_data helpers from W4.
    Note: extends `uvm_transaction`, **not** `uvm_sequence_item`
    (yet).
  - **ch.22 UVM Agents** ⭐ — `uvm_agent` encapsulates the per-
    interface components (here: monitors + scoreboard + coverage +
    tester + driver from W5) into one reusable block. Introduces
    a config object (`tinyalu_agent_config` holding `virtual <bfm>`
    and `is_active`), conditional instantiation based on
    `is_active`, and exposing top-level analysis ports through the
    agent. *No sequencer/sequence yet* — that's ch.23.
  - **ch.23 UVM Sequences** ⭐ — finally introduces
    `uvm_sequence_item` (extends `uvm_transaction`),
    `uvm_sequencer`, `uvm_driver` (with built-in
    `seq_item_port`), and `uvm_sequence` (with `body()`,
    `start_item`/`finish_item`, `start()`, `m_sequencer`).
    Walks through 6 conversion steps to make the TB sequence-driven.
    Also covers virtual sequences (using `uvm_top.find()` to grab
    a sequencer handle) and parallel sequences via fork/join.
- **Verification Academy**: UVM Cookbook → "Sequences" section
- **ChipVerify**: [uvm-sequence-item](https://www.chipverify.com/uvm/uvm-sequence-item),
  [uvm-sequence](https://www.chipverify.com/uvm/uvm-sequence),
  [uvm-sequencer](https://www.chipverify.com/uvm/uvm-sequencer),
  [uvm-driver](https://www.chipverify.com/uvm/uvm-driver),
  [uvm-agent](https://www.chipverify.com/uvm/uvm-agent)

### Reading — Design

- **Dally & Harting ch.25 — Memory Systems**: SRAM organization,
  byte enables, banking
- **Sutherland *SV for Design* ch.9 — Design Hierarchy**:
  parameterized modules and `generate` blocks. (Note: the earlier
  reference to "ch.11 — generate" was wrong; ch.11 is the ATM
  worked example, not generate constructs.)
- **Cliff Cummings** *"Asynchronous FIFO Design"* (theory follow-up
  — build is W7)

### Tool Setup

- xsim with `-L uvm`
- Sequence stop: `+UVM_TIMEOUT=<n>,YES` if a sequence hangs

---

## Verification Homework

### Drills (per-chapter warmups)

- **Drill ch.20 — Deep ops on a class hierarchy**
  *File:* `homework/verif/per_chapter/hw_ch20_deep_operations/deep_ops_demo.sv`
  Recreate Salemi's lion hierarchy or a simpler `point_3d`. Three
  classes in a chain; each implements `convert2string()` calling
  `super.convert2string()`, and `do_copy(uvm_object rhs)` using the
  always-take-the-base + `$cast` trick. Demonstrate that adding a
  new level in the middle doesn't require touching the leaf class.

- **Drill ch.21 — command_transaction extends uvm_transaction**
  *File:* `homework/verif/per_chapter/hw_ch21_uvm_transactions/cmd_transaction.sv`
  ```systemverilog
  class command_transaction extends uvm_transaction;
      `uvm_object_utils(command_transaction)
      rand byte unsigned A, B;
      rand operation_t   op;
      constraint c_zeros_ones { A dist {0:=1, [1:254]:=1, 255:=1}; }
      function new(string name = "command_transaction");
          super.new(name);
      endfunction
      // Implement do_copy, do_compare, convert2string
  endclass
  ```
  In a small top, randomize one, copy to a second, compare (match),
  modify a field, compare again (mismatch). Print both via the UVM's
  built-in `print()` (which calls `convert2string`).
  **Important:** this drill extends `uvm_transaction`, not
  `uvm_sequence_item` — the latter is taught in ch.23.

- **Drill ch.22 — Minimal agent (no sequencer yet)**
  *File:* `homework/verif/per_chapter/hw_ch22_uvm_agents/alu_agent_minimal.sv`
  Build `alu_agent extends uvm_agent` containing only:
  ```
  alu_command_monitor   cmd_mon;
  alu_result_monitor    rslt_mon;
  alu_coverage          cov;       // uvm_subscriber
  alu_scoreboard        scb;       // uvm_subscriber + tlm_analysis_fifo
  alu_tester            tester;    // active only — from W5
  alu_driver            drv;       // active only — from W5
  uvm_tlm_fifo #(command_transaction) cmd_f; // active only
  ```
  Plus an `alu_agent_config` carrying `virtual alu_if` and
  `is_active`. The agent gets the config in `build_phase` via
  `uvm_config_db`, builds children conditionally on `is_active`
  (active builds tester+driver+fifo; passive builds only the
  monitors + analysis path), and exposes top-level
  `cmd_ap`/`result_ap` analysis ports in `connect_phase` by
  forwarding the monitor ports up. **No sequencer / no
  seq_item_port** — those arrive in ch.23.

- **Drill ch.23 — First sequence**
  *File:* `homework/verif/per_chapter/hw_ch23_uvm_sequences/first_sequence.sv`
  Now do all 6 of Salemi's conversion steps on a tiny scope:
  1. Convert `command_transaction` to `tinyalu_item extends
     uvm_sequence_item` (add `result` field).
  2. Replace `tester` with `typedef uvm_sequencer #(tinyalu_item)
     sequencer;`
  3. Upgrade driver to `extends uvm_driver #(tinyalu_item)`, use
     `seq_item_port.get_next_item(cmd) → bfm.send_op(...) →
     item_done()`.
  4. In env: instantiate sequencer + driver, connect with
     `drv.seq_item_port.connect(sqr.seq_item_export)`. *No
     tlm_fifo needed.*
  5. Write `fibonacci_sequence extends uvm_sequence #(tinyalu_item)`
     with a `body()` that uses `start_item(cmd) / finish_item(cmd)`
     to generate the first 10 Fibonacci numbers via the ALU.
  6. Test: `fibonacci_test::run_phase` raises objection, calls
     `fib_seq.start(env_h.sqr)`, drops objection.

### Main HWs

#### HW1: Transaction-ize the W5 ALU testbench
*Folder:* `homework/verif/connector/hw1_alu_transactions/`

Take your W5 HW1 (analysis path) testbench. Replace the bare
`command_s` struct and `shortint` result with proper transaction
classes:

- `command_transaction extends uvm_transaction` (your ch.21 drill,
  expanded for the full ALU op set)
- `result_transaction extends uvm_transaction`
- `add_transaction extends command_transaction` adding a constraint
  `op == add_op`

Update the monitors to send transactions through the analysis ports.
The scoreboard's `compare()` becomes a one-liner:
`predicted_result.compare(actual_result)`.

Add an `add_test` that overrides `command_transaction` with
`add_transaction` via `set_type_override` — same TB, different
stimulus.

This is the testbench Salemi ends ch.21 with.

#### HW2: Encapsulate into an alu_agent (Salemi ch.22)
*Folder:* `homework/verif/connector/hw2_alu_agent/`

Build on HW1. Wrap everything ALU-touching into `alu_agent` per
your ch.22 drill. Add `alu_agent_config` carrying the virtual
interface + `is_active`. The env now holds *just* the agent (and
optionally a higher-level scoreboard/coverage subscribed to the
agent's exposed analysis ports). Run the existing tests through
this new structure — same behavior.

#### HW3: Sequence-driven testbench (Salemi ch.23)
*Folder:* `homework/verif/connector/hw3_sequence_driven_tb/`

Build on HW2. Apply Salemi's 6 conversion steps to the full ALU TB:

- `tinyalu_item extends uvm_sequence_item` (with `result` field)
- Replace tester+driver+tlm_fifo trio with `uvm_sequencer` +
  `uvm_driver` with `seq_item_port`
- Three sequences:
  - `fibonacci_seq` — generates Fib(0..N) via the adder
  - `random_seq` — uses `\`uvm_do(cmd)` or
    `start_item; assert(cmd.randomize()); finish_item;` for 100
    random ops
  - `corner_seq` — directed: 0+0, FF+FF, 0×FF, FF×FF, etc.
- Three `uvm_test` subclasses, each starting one sequence in
  `run_phase`. Pick via `+UVM_TESTNAME=...`.
- Print topology in `end_of_elaboration_phase` to confirm the full
  tree.

### Stretch (optional)

- **Stretch — Virtual sequence (Salemi ch.23)**
  *Folder:* `homework/verif/big_picture/virtual_sequence/`
  Write `runall_seq extends uvm_sequence #(tinyalu_item)` whose
  `body()` finds the sequencer via `uvm_top.find("*.env_h.sqr_h")`
  and `$cast`s it, then starts `reset_seq`, `fibonacci_seq`, and
  `random_seq` in turn. Launch with `runall_seq.start(null)`.

- **Stretch — Parallel sequences via fork/join**
  Two sequences started in parallel through the same sequencer
  (Salemi's parallel example). Watch the sequencer's default FIFO
  arbitration interleave them.

---

## Design Homework

### Drills (per-chapter warmups)

- **Drill Sutherland ch.9 — Parameterized + generate**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch9_generate/`
  Parameterized N-bit register file using a `generate for` block.
  Verify with TB at WIDTH=8/32, DEPTH=16/128. (Note: generate is
  ch.9 in *SV for Design*, not ch.11.)

- **Drill Dally ch.25 — Memory bank with byte enable**
  *Folder:* `homework/design/per_chapter/hw_dally_ch25_memory_bank/`
  1KB memory with bytewise write-enable mask. Show
  read-after-write behavior and the byte-strobe coverage cases.

- **Drill Cummings — Async FIFO theory write-up**
  *Folder:* `homework/design/per_chapter/hw_cummings_async_fifo_theory/`
  Read the Cummings async-FIFO paper. One page covering: gray-code
  pointers, why they help across CDC, 2-FF synchronizer, MTBF
  basics. No RTL — that's W7.

### Main HWs

#### HW1: Direct-mapped cache structure
*Folder:* `homework/design/connector/hw1_direct_mapped_cache/`

Structural skeleton of a direct-mapped cache: address →
{tag, index, offset}, tag array, data array, hit/miss output. No
replacement policy needed (direct-mapped). Combines memory +
parameterization + addressing.

#### HW2: Async FIFO theory
*Folder:* `homework/design/connector/hw2_async_fifo_theory/`

Expand the Cummings drill into a full pre-build study: draw the
block diagram, identify each clock domain crossing, choose
gray-code width, and **predict** the full/empty conditions
algebraically. The actual RTL build happens in W7; this is the
design doc for it.

---

## Self-Check Questions

1. What's the difference between `uvm_object`, `uvm_transaction`, and
   `uvm_sequence_item`? In what order does Salemi introduce them?
2. Why must `do_copy` always take a base-class argument and `$cast`
   inside, instead of taking the derived type directly?
3. What does the sequencer/driver TLM handshake (`get_next_item` /
   `item_done`) actually pass, and what does the sequencer hold while
   the driver works?
4. What's a virtual sequence and when do you need one?
5. Active vs passive agent — what changes inside `build_phase`?
6. What does `start_item(tr); finish_item(tr);` do? What blocks where?

---

## Checklist

### Verification Track
- [ ] Read Salemi ch.20 (deep operations)
- [ ] Read Salemi ch.21 (uvm_transactions)
- [ ] Read Salemi ch.22 (uvm_agents)
- [ ] Read Salemi ch.23 (uvm_sequences)
- [ ] Read Verification Academy "Sequences" section
- [ ] Drill ch.20 (deep operations)
- [ ] Drill ch.21 (command_transaction extends uvm_transaction)
- [ ] Drill ch.22 (minimal agent, no sequencer)
- [ ] Drill ch.23 (first sequence + 6-step conversion)
- [ ] HW1: transaction-ize the ALU TB
- [ ] HW2: alu_agent + config object
- [ ] HW3: sequence-driven TB with 3 sequences
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Sutherland ch.9 (parameterization + generate)
- [ ] Read Dally ch.25 (memory systems)
- [ ] Read Cummings async FIFO paper
- [ ] Drill Sutherland ch.9 (param register file via generate)
- [ ] Drill Dally ch.25 (memory bank with byte enable)
- [ ] Drill Cummings (async FIFO theory write-up)
- [ ] HW1: direct-mapped cache structure
- [ ] HW2: async FIFO design doc
