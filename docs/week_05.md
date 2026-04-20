# Week 5: UVM Sequences, Sequencer & Config DB

## Why This Matters
Sequences are how you generate stimulus in UVM. The sequencer-driver handshake is the engine of every UVM testbench. Config DB is how you pass configuration down the hierarchy without hard-coding. Mastering these means you can write real tests.

## What to Study

### Reading
- **Salemi *The UVM Primer* ch.6-8** (primary): sequences, config DB, virtual sequences
  - `uvm_sequence` and `uvm_sequence_item`
  - `body()` task — the sequence execution
  - `start_item()` / `finish_item()` handshake
  - Sequence library, virtual sequences
  - `uvm_config_db#(T)::set()` / `::get()`
  - Passing virtual interfaces, parameterizing components from the test level
- **Rosenberg & Meade ch.5-7** (reference, optional): deeper treatment of the same topics for industry-style patterns
- **Verification Academy UVM Cookbook** (free, online): best resource for sequence variants and config_db patterns — search it whenever stuck

### Videos (Verification Academy)
- "UVM Sequences" course
- "UVM Configuration" course

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/uvm/uvm-sequence
- https://www.chipverify.com/uvm/uvm-sequence-item
- https://www.chipverify.com/uvm/uvm-sequencer
- https://www.chipverify.com/uvm/uvm-config-db
- https://www.chipverify.com/uvm/uvm-virtual-sequence

---

## Homework

### HW1: Three Types of Sequences
Using the ALU environment from Week 4, write three sequences:

**Directed sequence** — `alu_directed_seq extends uvm_sequence #(alu_transaction)`
Inside `body()`, drive ~10 specific, known test vectors using the
`start_item()` / `finish_item()` handshake. Suggested cases:
- 0 + 0 = 0
- FF + 1 = overflow
- FF AND 0F = 0F
- A XOR A = 0
- ... pick 6 more that exercise each operation's edges

**Random sequence** — `alu_random_seq extends uvm_sequence #(alu_transaction)`
Parameterize with a `rand int unsigned num_txns` (e.g., 10..100). In `body()`,
loop `num_txns` times and randomize each transaction before sending it.

**Error injection sequence** — `alu_error_seq extends uvm_sequence #(alu_transaction)`
Targets illegal / edge-case scenarios:
- Max values (FF op FF)
- Min values (00 op 00)
- Same operands (A op A)
- Back-to-back transactions with no delay

Run all three from the test and verify they drive correctly.

### HW2: Virtual Sequence
Create a scenario where you have TWO agents (e.g., an ALU agent and a memory agent):

Write a `top_virtual_seq extends uvm_sequence`. It needs:
- handles to both sub-sequencers (an ALU sequencer and a memory sequencer)
- a `body()` task that runs a sequence on each sub-sequencer in parallel
  (hint: `fork ... join` with `seq.start(sqr)` calls)

The virtual sequence coordinates stimulus across multiple agents — this is how complex tests are written in real projects.

### HW3: Config DB Exercise
Parameterize your environment using `uvm_config_db`:

From the **test level**, in `build_phase`, you should pass three things down
into the env *before* creating it:
- the virtual interface (typed `virtual alu_if`) destined for the driver
- an `int` telling the sequencer how many transactions to run
- a `uvm_active_passive_enum` telling the agent whether to be ACTIVE or PASSIVE

All three go via `uvm_config_db#(T)::set(...)`. Think carefully about the
scope (`this` and the path string) so each value lands at the right component.

In the **agent/driver**, retrieve the corresponding value with
`uvm_config_db#(T)::get(...)`. If the `get` fails, raise a `uvm_fatal` —
silently running without an interface is a classic UVM footgun.

Write two different tests that pass different configurations:
- `small_test`: 10 transactions, directed sequence
- `stress_test`: 10000 transactions, random sequence

Run both using `+UVM_TESTNAME=small_test` and `+UVM_TESTNAME=stress_test`.

### HW4: TLM Connection — Monitor to Scoreboard
Implement the TLM connection properly:

Three pieces to wire up:
- **Monitor** — owns a `uvm_analysis_port #(alu_transaction)`. In `run_phase`,
  observes the interface, builds a transaction, and `ap.write(txn)`s it.
- **Scoreboard** — owns a `uvm_analysis_imp #(alu_transaction, alu_scoreboard)`.
  Implements a `write()` function that compares against a reference model.
- **Env** — in `connect_phase`, connect the monitor's analysis port to the
  scoreboard's imp.

Make sure transactions flow from monitor through the analysis port to the scoreboard. Print messages at each stage to verify.

---

## Self-Check Questions
1. What's the difference between `start_item()`/`finish_item()` and `uvm_do()`?
2. Why do sequences use `body()` as a task (not function)?
3. What happens if `uvm_config_db::get()` fails? How should you handle it?
4. What's the difference between `uvm_analysis_port` and `uvm_analysis_imp`?
5. What is a virtual sequence and when do you need one?
6. How does `+UVM_TESTNAME` work?

---

## Design Track: Memory Design & UVM Integration

This week has two design focuses: (1) connecting your ALU DUT into UVM, and (2) learning memory design — RAMs, ROMs, and dual-port memories that appear in every chip.

### Reading (Design)
- **Dally & Harting ch.16**: "Datapath Sequential Logic" — counters, shift registers, LFSRs, FIFOs, and datapath design patterns. Covers the sequential building blocks for memories and arbiters.
- **Dally & Harting ch.25**: "Memory Systems" — SRAM, DRAM, caches (direct-mapped, set-associative), memory hierarchy. Read this before building the cache HW.
- **Dally & Harting ch.24**: "Interconnect" — buses, arbitration schemes (fixed-priority, round-robin, weighted), crossbars. Directly relevant to your round-robin arbiter HW.
- **Cliff Cummings** *"Simulation and Synthesis Techniques for Asynchronous FIFO Design"* (SNUG 2002) — the canonical paper on async FIFO design with Gray code pointers. Read the theory now, build it in Week 6.
- **ChipVerify**: https://www.chipverify.com/verilog/verilog-single-port-ram — RAM design patterns

### Design HW1: Top-Level Testbench Module
Write the `tb_top.sv` that instantiates the DUT, interface, and runs UVM:

```systemverilog
module tb_top;
    logic clk, rst_n;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Interface instance
    alu_if aif(clk, rst_n);

    // DUT instance — uses modport
    alu dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .operand_a (aif.operand_a),
        .operand_b (aif.operand_b),
        .operation (aif.operation),
        .valid_in  (aif.valid_in),
        .result    (aif.result),
        .valid_out (aif.valid_out)
    );

    // Pass interface to UVM via config_db
    initial begin
        uvm_config_db#(virtual alu_if)::set(null, "*", "vif", aif);
        run_test();
    end
endmodule
```

This is the standard pattern for every UVM testbench — learn it well.

### Design HW2: True Dual-Port RAM
Design a dual-port RAM — the core building block inside caches, FIFOs, and register files:

```systemverilog
module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,      // 16 entries
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  logic                  clk,
    // Port A (read/write)
    input  logic                  en_a,
    input  logic                  wr_en_a,
    input  logic [ADDR_WIDTH-1:0] addr_a,
    input  logic [DATA_WIDTH-1:0] wr_data_a,
    output logic [DATA_WIDTH-1:0] rd_data_a,
    // Port B (read/write)
    input  logic                  en_b,
    input  logic                  wr_en_b,
    input  logic [ADDR_WIDTH-1:0] addr_b,
    input  logic [DATA_WIDTH-1:0] wr_data_b,
    output logic [DATA_WIDTH-1:0] rd_data_b
);
    // Key behaviors:
    // - Both ports can read simultaneously from different addresses
    // - Both ports can write simultaneously to different addresses
    // - Simultaneous write to SAME address: port A wins (or flag collision)
    // - Read-during-write to same address: return NEW data (write-first)
    //
    // Industry note: this should infer BRAM on FPGAs — use `logic` array,
    // not `reg`, and follow Xilinx/Intel RAM coding guidelines
endmodule
```

Write a testbench:
1. Write from port A, read from port B (and vice versa)
2. Simultaneous reads from both ports to different addresses
3. Write collision: both ports write same address — verify port A wins
4. Read-during-write: write via A, read same address via B on same cycle

### Design HW3: Round-Robin Arbiter
Upgrade from Week 3's fixed-priority arbiter to a fair round-robin arbiter:

```systemverilog
module round_robin_arbiter #(
    parameter NUM_REQ = 4
)(
    input  logic                clk, rst_n,
    input  logic [NUM_REQ-1:0]  request,
    output logic [NUM_REQ-1:0]  grant,
    output logic                grant_valid
);
    // Rules:
    // - After granting request N, the next grant starts searching from N+1
    // - Wraps around: after request 3, search starts from request 0
    // - Uses a rotating priority mask to track the "last served" requester
    //
    // This is the most common arbiter in real SoCs — bus arbiters, NoC routers,
    // memory controllers all use variants of round-robin
endmodule
```

Write a testbench:
1. All 4 requests active continuously — verify each gets served in order (0,1,2,3,0,1,...)
2. Some requests drop out — verify remaining requests still get fair access
3. Single requester — verify it gets immediate grant every cycle
4. Add SVA: grant is always one-hot or zero; no starvation (every active request gets served within NUM_REQ cycles)

### Design HW4: Simple Direct-Mapped Cache Structure
Design the data structure of a direct-mapped cache — you'll use this concept in Week 7-8 CPU work:

```systemverilog
module direct_mapped_cache #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter CACHE_LINES = 16,    // number of cache lines
    parameter LINE_SIZE   = 4      // words per line
)(
    input  logic                  clk, rst_n,
    input  logic                  rd_en,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  hit,
    output logic                  miss
);
    // Structure per cache line:
    //   [valid] [tag] [data_word_0] [data_word_1] ... [data_word_N]
    //
    // Address decomposition:
    //   [tag | index | offset]
    //   - offset: selects word within line (log2(LINE_SIZE) bits)
    //   - index: selects cache line (log2(CACHE_LINES) bits)
    //   - tag: remaining upper bits
    //
    // Hit logic: valid[index] && (tag_store[index] == addr.tag)
    //
    // Focus on the READ path and hit/miss detection this week.
    // Don't worry about write-back/write-through policies — just write-through.
endmodule
```

Write a testbench:
1. Write to address, read it back — verify hit
2. Read from unloaded address — verify miss
3. Read from two addresses that map to the same index (conflict miss)
4. Verify tag comparison logic

---

## Checklist

### Verification Track
- [ ] Read Salemi *UVM Primer* ch.6-8 (Rosenberg ch.5-7 optional reference)
- [ ] Watched Verification Academy Sequences + Config DB modules
- [ ] Read ChipVerify sequence, sequencer, config_db pages
- [ ] Completed HW1 (Three sequence types)
- [ ] Completed HW2 (Virtual sequence)
- [ ] Completed HW3 (Config DB exercise)
- [ ] Completed HW4 (TLM monitor-to-scoreboard)
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Dally ch.16 (datapath sequential logic), ch.24 (interconnect), ch.25 (memory systems)
- [ ] Read Cummings async FIFO paper (theory — build in Week 6)
- [ ] Completed Design HW1 (tb_top.sv connecting DUT to UVM via interface)
- [ ] Completed Design HW2 (True dual-port RAM)
- [ ] Completed Design HW3 (Round-robin arbiter)
- [ ] Completed Design HW4 (Direct-mapped cache structure)
