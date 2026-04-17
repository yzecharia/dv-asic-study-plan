# Week 5: UVM Sequences, Sequencer & Config DB

## Why This Matters
Sequences are how you generate stimulus in UVM. The sequencer-driver handshake is the engine of every UVM testbench. Config DB is how you pass configuration down the hierarchy without hard-coding. Mastering these means you can write real tests.

## What to Study

### Reading
- **Rosenberg & Meade ch.5-6**: "Sequences", "Sequencer-Driver"
  - `uvm_sequence` and `uvm_sequence_item`
  - `body()` task — the sequence execution
  - `start_item()` / `finish_item()` handshake
  - Sequence library, virtual sequences
- **Rosenberg & Meade ch.7**: "Configuration"
  - `uvm_config_db#(T)::set()` and `::get()`
  - Passing virtual interfaces
  - Parameterizing components from test level

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

**Directed sequence** — tests specific known cases:
```systemverilog
class alu_directed_seq extends uvm_sequence #(alu_transaction);
    `uvm_object_utils(alu_directed_seq)

    virtual task body();
        alu_transaction txn;

        // Test 1: 0 + 0 = 0
        txn = alu_transaction::type_id::create("txn");
        start_item(txn);
        txn.operand_a = 0; txn.operand_b = 0; txn.operation = ADD;
        finish_item(txn);

        // Test 2: FF + 1 = overflow
        // Test 3: FF AND 0F = 0F
        // Test 4: A XOR A = 0
        // ... add 6 more directed test vectors
    endtask
endclass
```

**Random sequence** — generates N random transactions:
```systemverilog
class alu_random_seq extends uvm_sequence #(alu_transaction);
    `uvm_object_utils(alu_random_seq)
    rand int unsigned num_txns;
    constraint c_num { num_txns inside {[10:100]}; }

    virtual task body();
        for (int i = 0; i < num_txns; i++) begin
            alu_transaction txn = alu_transaction::type_id::create($sformatf("txn_%0d", i));
            start_item(txn);
            assert(txn.randomize());
            finish_item(txn);
        end
    endtask
endclass
```

**Error injection sequence** — intentionally creates illegal/edge cases:
```systemverilog
class alu_error_seq extends uvm_sequence #(alu_transaction);
    // Generate sequences that test:
    // - Max values (FF op FF)
    // - Min values (00 op 00)
    // - Same operands (A op A)
    // - Back-to-back transactions with no delay
endclass
```

Run all three from the test and verify they drive correctly.

### HW2: Virtual Sequence
Create a scenario where you have TWO agents (e.g., an ALU agent and a memory agent):

```systemverilog
class top_virtual_seq extends uvm_sequence;
    `uvm_object_utils(top_virtual_seq)

    // Handles to sub-sequencers
    uvm_sequencer #(alu_transaction) alu_sqr;
    uvm_sequencer #(mem_transaction) mem_sqr;

    virtual task body();
        alu_random_seq alu_seq = alu_random_seq::type_id::create("alu_seq");
        mem_write_seq  mem_seq = mem_write_seq::type_id::create("mem_seq");

        // Run both in parallel using fork-join
        fork
            alu_seq.start(alu_sqr);
            mem_seq.start(mem_sqr);
        join
    endtask
endclass
```

The virtual sequence coordinates stimulus across multiple agents — this is how complex tests are written in real projects.

### HW3: Config DB Exercise
Parameterize your environment using `uvm_config_db`:

From the **test level**, configure:
```systemverilog
class configurable_test extends uvm_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Pass virtual interface to driver
        uvm_config_db#(virtual alu_if)::set(this, "env.agent.driver", "vif", alu_vif);

        // Pass number of transactions to sequence
        uvm_config_db#(int)::set(this, "env.agent.sequencer", "num_transactions", 500);

        // Pass agent mode (ACTIVE or PASSIVE)
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.agent", "is_active", UVM_ACTIVE);

        env = alu_env::type_id::create("env", this);
    endfunction
endclass
```

In the **agent/driver**, retrieve:
```systemverilog
class alu_driver extends uvm_driver #(alu_transaction);
    virtual alu_if vif;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found in config DB!")
    endfunction
endclass
```

Write two different tests that pass different configurations:
- `small_test`: 10 transactions, directed sequence
- `stress_test`: 10000 transactions, random sequence

Run both using `+UVM_TESTNAME=small_test` and `+UVM_TESTNAME=stress_test`.

### HW4: TLM Connection — Monitor to Scoreboard
Implement the TLM connection properly:

```systemverilog
// In monitor: analysis port sends observed transactions
class alu_monitor extends uvm_monitor;
    uvm_analysis_port #(alu_transaction) ap;

    virtual task run_phase(uvm_phase phase);
        forever begin
            alu_transaction txn;
            // ... observe DUT signals on interface ...
            // ... create transaction from observed values ...
            ap.write(txn);  // broadcast to all subscribers
        end
    endtask
endclass

// In scoreboard: analysis imp receives transactions
class alu_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(alu_transaction, alu_scoreboard) imp;

    virtual function void write(alu_transaction txn);
        // Check: does txn.result match expected result?
        // Compute expected result here (reference model)
        // Compare and report pass/fail
    endfunction
endclass

// In agent: connect monitor's port to scoreboard's imp
class alu_env extends uvm_env;
    virtual function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.imp);
    endfunction
endclass
```

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
- [ ] Read Rosenberg ch.5-7
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
