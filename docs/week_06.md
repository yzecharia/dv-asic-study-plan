# Week 6: UVM Stimulus — Transactions, Agents, Sequences

## Why This Matters

This is where UVM finally clicks. You'll learn:
- **Transactions** — proper data carriers with `do_copy` / `do_compare` / `do_print`
- **Agents** — the standard packaging of driver+sequencer+monitor (active/passive)
- **Sequences** — the unit of stimulus generation, decoupled from the driver

Sequences are the **defining feature** of UVM that makes verification IP
reusable. After this week the architectural picture is complete.

## What to Study (Salemi ch.20-23)

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.20 Class Hierarchies and Deep Operations** ⭐ — `do_copy`, `do_compare`, `do_print`, `do_pack`, the visitor pattern
  - **ch.21 UVM Transactions** ⭐ — proper `uvm_sequence_item`, framework method overrides, transaction recording
  - **ch.22 UVM Agents** — packaging driver+sqr+mon; `uvm_active_passive_enum`
  - **ch.23 UVM Sequences** ⭐ — `uvm_sequence`, `body()`, `start_item`/`finish_item`, the sequencer/driver handshake (`get_next_item`, `item_done`)
- **Verification Academy**: UVM Cookbook → "Sequences" section (essential — 30 pages)
- **ChipVerify**: [uvm-sequence-item](https://www.chipverify.com/uvm/uvm-sequence-item), [uvm-sequence](https://www.chipverify.com/uvm/uvm-sequence), [uvm-sequencer](https://www.chipverify.com/uvm/uvm-sequencer), [uvm-driver](https://www.chipverify.com/uvm/uvm-driver), [uvm-agent](https://www.chipverify.com/uvm/uvm-agent)

### Reading — Design

- **Sutherland *SV for Design* ch.11** — hierarchical structure, `generate` blocks, parameterized modules
- **Dally & Harting ch.25** — memory systems (cache organization)
- **Cliff Cummings** — *"Async FIFO Design"* paper (companion to W5; now apply it)

### Tool Setup

- xsim with `-L uvm` (same as before)
- Sequence stop: `+UVM_TIMEOUT=<n>,YES` if a sequence hangs

---

## Verification Homework

### Per-chapter

- **HW ch.20 — Deep operations on a custom class**
  *File:* `homework/verif/per_chapter/hw_ch20_deep_operations/deep_ops_demo.sv`

  Build a `point_3d` class extending `uvm_object` with `rand bit [7:0] x, y, z;`
  fields. Implement and exercise:
  ```systemverilog
  function void do_copy(uvm_object rhs);
      point_3d that;
      super.do_copy(rhs);
      $cast(that, rhs);
      x = that.x;  y = that.y;  z = that.z;
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      point_3d that;
      $cast(that, rhs);
      return (x == that.x) && (y == that.y) && (z == that.z);
  endfunction

  function string convert2string();
      return $sformatf("(%0d, %0d, %0d)", x, y, z);
  endfunction
  ```
  In a top module, randomize two points, copy one to the other, compare,
  modify one field and compare again. Print both with `print()`.

- **HW ch.21 — Full ALU transaction**
  *File:* `homework/verif/per_chapter/hw_ch21_uvm_transactions/alu_transaction.sv`

  Move your week-4 `alu_transaction` to its proper home and implement
  the FULL `uvm_sequence_item` API:
  - `\`uvm_object_utils(alu_transaction)`
  - `rand` fields: `operand_a`, `operand_b`, `operation` (enum)
  - non-rand `result` (set by monitor)
  - constructor: `function new(string name = "alu_transaction"); super.new(name); endfunction`
  - `do_copy`, `do_compare`, `convert2string`, `do_print` overrides
  - one constraint that excludes the all-zero corner

- **HW ch.22 — UVM agent**
  *File:* `homework/verif/per_chapter/hw_ch22_uvm_agents/alu_agent.sv`

  Build an `alu_agent extends uvm_agent` that holds:
  ```systemverilog
  alu_driver    drv;
  alu_monitor   mon;
  uvm_sequencer #(alu_transaction) sqr;
  ```
  Implement `build_phase` that creates the children based on
  `get_is_active()` (active → drv+sqr+mon; passive → mon only). Implement
  `connect_phase` to wire `drv.seq_item_port.connect(sqr.seq_item_export)`.

- **HW ch.23 — Three sequence types**
  *File:* `homework/verif/per_chapter/hw_ch23_uvm_sequences/sequences.sv`

  Write three sequences extending `uvm_sequence #(alu_transaction)`:
  1. `directed_seq` — drives 5 specific corner-case operations
     (`{0,0,ADD}`, `{FF,FF,ADD}`, `{1,N,MUL}`, etc.)
  2. `random_seq` — drives 100 random transactions
  3. `error_seq` — deliberately drives an illegal `operation` field to
     test scoreboard/checker reaction

  Each implements `task body()` with `start_item(tr); assert(tr.randomize());
  finish_item(tr);` pattern.

### Connector — full sequence-driven UVM TB

- **Connector HW — Sequence-driven ALU testbench**
  *Folder:* `homework/verif/connector/`

  Now upgrade your week-4/5 connector TB to use the proper sequence-based
  flow:
  - Replace the in-tester stimulus with sequences started from the test
  - The driver pulls transactions via `seq_item_port.get_next_item()`
  - The agent's sequencer arbitrates between sequences
  - Three `uvm_test` subclasses, each starting a different sequence
  - All connected via TLM analysis ports (from W5)
  - Test selection via `+UVM_TESTNAME=<name>` plusarg

  Run all three tests against the same compiled binary. Print
  topology to confirm the full UVM tree.

### Big picture — stretch within scope

- **Big-picture HW — Virtual sequence**
  *Folder:* `homework/verif/big_picture/virtual_sequence/`

  Two agents in the same env (e.g., `alu_agent` + a side-channel agent
  for register configuration). A `virtual_sequence` orchestrates both
  via `uvm_sequencer` handles. Demonstrates multi-agent coordination —
  the pattern used in real chip-level testbenches.

- **Big-picture HW — Sequence library + selection**
  *Folder:* `homework/verif/big_picture/sequence_library/`

  Create a `uvm_sequence_library` with the three sequences from the
  per-chapter HW. Use `select_sequences_max`/`select_rand` policies.
  Run a single test that randomly picks sequences from the library.

---

## Design Homework

### Per-chapter

- **HW Sutherland ch.11 — Parameterized + generate**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch11_generate/`

  Build a parameterized `N`-bit register file using a `generate` block.
  Tunable depth and width via parameters; verify with TB at WIDTH=8,32,
  DEPTH=16,128.

- **HW Dally ch.25 — Memory bank with byte enable**
  *Folder:* `homework/design/per_chapter/hw_dally_ch25_memory_bank/`

  Build a 1KB memory with byte-write-enable (bytewise mask). Show
  read-after-write and write-strobe coverage cases.

- **HW Cummings — Async FIFO theory**
  *Folder:* `homework/design/per_chapter/hw_cummings_async_fifo_theory/`

  Read the Cummings async FIFO paper. Write a 1-page summary covering:
  Gray-code pointers, why they help, 2-FF synchronizer, MTBF basics.
  No RTL yet — that's W7.

### Connector

- **Connector HW — Direct-mapped cache structure**
  *Folder:* `homework/design/connector/direct_mapped_cache/`

  Build the structural skeleton of a direct-mapped cache:
  tag/index/offset address decomposition, tag array, data array, hit/miss
  signal. No replacement policy needed (direct-mapped). Combines memory
  + parameterization + addressing from this week's design reading.

### Big picture

- **Big-picture HW — Round-robin arbiter (parameterized N inputs)**
  *Folder:* `homework/design/big_picture/round_robin_arbiter/`

  Parameterized N-input round-robin arbiter with rotating priority.
  Test fairness (every input eventually gets granted) under sustained
  contention. Bonus: weighted round-robin variant.

---

## Self-Check Questions

1. What's the difference between `uvm_object` and `uvm_sequence_item`?
2. Why override `do_copy` instead of just writing your own `copy` function?
3. What does the sequencer/driver TLM handshake (`get_next_item` /
   `item_done`) actually pass between them?
4. What's a virtual sequence and when do you need one?
5. Active vs passive agent — what's the difference and when would you use each?
6. What does `start_item(tr); finish_item(tr);` do? What happens between them?

---

## Checklist

### Verification Track
- [ ] Read Salemi ch.20 (deep operations)
- [ ] Read Salemi ch.21 (UVM transactions)
- [ ] Read Salemi ch.22 (UVM agents)
- [ ] Read Salemi ch.23 (UVM sequences)
- [ ] Read Verification Academy "Sequences" section
- [ ] Read ChipVerify uvm-sequence + uvm-sequencer + uvm-driver pages
- [ ] Per-chapter HW ch.20 (deep operations)
- [ ] Per-chapter HW ch.21 (full alu_transaction)
- [ ] Per-chapter HW ch.22 (alu_agent)
- [ ] Per-chapter HW ch.23 (three sequence types)
- [ ] Connector HW (sequence-driven UVM TB, multiple tests via plusarg)
- [ ] Big-picture HW: virtual sequence
- [ ] Big-picture HW: sequence library
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Sutherland ch.11 (parameterization, generate)
- [ ] Read Dally ch.25 (memory systems)
- [ ] Read Cummings async FIFO paper
- [ ] Per-chapter HW: parameterized register file with generate
- [ ] Per-chapter HW: memory bank with byte enable
- [ ] Per-chapter HW: async FIFO theory write-up
- [ ] Connector HW: direct-mapped cache structure
- [ ] Big-picture HW: round-robin arbiter
