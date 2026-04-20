# Week 6: Full UVM Testbench Integration

## Why This Matters
This is where everything comes together. You'll build a complete, working UVM testbench end-to-end for a real DUT. After this week, you can say "I know UVM" in an interview and back it up.

## What to Study

### Reading
- **Rosenberg & Meade ch.8-10** (primary this week): "Scoreboard", "Coverage", "Reporting"
  - Reference models inside scoreboard
  - Functional coverage integration in UVM
  - UVM reporting: `uvm_info`, `uvm_warning`, `uvm_error`, `uvm_fatal`
  - Verbosity control
  - End-of-test mechanism: `phase.raise_objection()` / `phase.drop_objection()`
  - *Note*: Rosenberg is the main book this week — Salemi's primer covers scoreboard at a high level in his later chapters but Rosenberg's production-patterns treatment is what you want now
- **Verification Academy UVM Cookbook** (free, online): scoreboard and coverage recipes — still the best single reference

### Videos (Verification Academy)
- "UVM Scoreboard" course
- "UVM Coverage" course
- "UVM Debug and Reporting" course

### Quick Reference (ChipVerify.com)
- https://www.chipverify.com/uvm/uvm-scoreboard
- https://www.chipverify.com/uvm/uvm-reporting
- https://www.chipverify.com/uvm/uvm-phases
- https://www.chipverify.com/uvm/uvm-objection

### Tool
- Use **EDA Playground** for all exercises this week
- Create a project with proper file organization (pkg, interface, top)

---

## Homework

### HW1: Scoreboard with Reference Model for ALU
Build a scoreboard that checks every ALU transaction against a reference model:

Scaffolding for `alu_scoreboard extends uvm_scoreboard`:
- Register with the factory via ``` `uvm_component_utils ```
- Expose a `uvm_analysis_imp #(alu_transaction, alu_scoreboard)` so the monitor can push to it
- Track `pass_count` and `fail_count`

You need to implement:
- **`write(alu_transaction txn)`** — the TLM hook. Inside, build a small
  reference model (a `case` on `txn.operation`) that computes the expected
  result from `operand_a`/`operand_b`. Compare against `txn.result`, bump the
  counters, and `` `uvm_info `` / `` `uvm_error `` as appropriate.
- **`report_phase`** — print the final pass/fail tally and raise a
  `` `uvm_error `` if any transaction mismatched.

### HW2: Functional Coverage in UVM
Add a coverage collector component to your environment:

Build `alu_coverage extends uvm_subscriber #(alu_transaction)` with:
- An internal `alu_transaction txn` handle that the covergroup can sample from
- A `covergroup alu_cg` containing:
  - a coverpoint on `txn.operation`
  - coverpoints on `operand_a` and `operand_b`, each partitioned into
    meaningful regions (think: zero / low / mid / high / max)
  - cross coverpoints between operation and each operand
- Constructor creates the covergroup
- Override `write()` to update `txn` and call `alu_cg.sample()`
- Override `report_phase` to print final coverage with `get_coverage()`

Connect it in the env alongside the scoreboard. Run until coverage >95%.

### HW3: Complete End-to-End UVM Testbench for Register File
Build a COMPLETE testbench for a register file DUT (32 registers x 32 bits, 2 read ports, 1 write port).

**RTL (write this yourself):**
```systemverilog
module register_file (
    input  logic        clk, rst_n,
    input  logic        wr_en,
    input  logic [4:0]  wr_addr, rd_addr1, rd_addr2,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data1, rd_data2
);
    // Register x0 is always 0 (RISC-V convention)
endmodule
```

**UVM Components (build all of these):**
- `regfile_transaction` — sequence item with wr_en, addresses, data
- `regfile_interface` — SV interface with clocking block
- `regfile_driver` — drives interface signals
- `regfile_monitor` — observes interface, broadcasts transactions
- `regfile_agent` — contains driver + monitor + sequencer
- `regfile_scoreboard` — maintains a reference model (array of 32 regs), checks reads
- `regfile_coverage` — covers all registers written, read, write-then-read same register
- `regfile_env` — assembles agent + scoreboard + coverage
- `regfile_base_test` — base test class
- `regfile_directed_test` — writes known values, reads back, checks
- `regfile_random_test` — random read/write sequences
- `regfile_stress_test` — back-to-back writes and reads, concurrent read during write

**Top module:**
- Instantiate DUT + interface
- Connect via config_db
- Run with `run_test()`

This is a FULL project. Take your time. When done, you have a complete UVM testbench you understand inside out.

### HW4: Regression & Coverage Closure
Using the register file testbench from HW3:

1. Run each test individually, record coverage:
   - `+UVM_TESTNAME=regfile_directed_test`
   - `+UVM_TESTNAME=regfile_random_test`
   - `+UVM_TESTNAME=regfile_stress_test`

2. Identify holes in coverage — which bins are not hit?

3. Write a **new sequence** specifically targeting the uncovered bins

4. Re-run until you achieve 100% functional coverage

5. Document the process: what was uncovered, what sequence fixed it

This simulates real DV work — coverage closure is what you'll spend most of your time doing on the job.

---

## Self-Check Questions
1. What does `raise_objection` / `drop_objection` do? What happens if you forget it?
2. What's the difference between `uvm_subscriber` and manually connecting with `uvm_analysis_imp`?
3. How do you run different tests from the command line without recompiling?
4. What's the purpose of `report_phase`? What other end-of-test phases exist?
5. How would you merge coverage from multiple test runs?
6. Explain the complete flow of a transaction: sequence -> sequencer -> driver -> DUT -> monitor -> scoreboard

---

## Design Track: Register File, Clock Domain Crossing & Async FIFO

Week 6 has three design focuses: (1) the register file that feeds into your UVM testbench, (2) clock domain crossing — the single most common source of silicon bugs, and (3) the async FIFO — which combines CDC with the FIFO you already know.

### Reading (Design)
- **Dally & Harting ch.15**: "Timing Constraints" — setup time, hold time, clock skew, timing analysis. Read this before the timing exercise (Design HW4).
- **Dally & Harting ch.28**: "Metastability and Synchronization Failure" — the physics of metastability, MTBF calculation, why synchronizers work. Essential background for CDC.
- **Dally & Harting ch.29**: "Synchronizer Design" — 2-FF synchronizers, synchronizer architectures, design guidelines. Directly maps to Design HW2.
- **Cliff Cummings** *"Clock Domain Crossing (CDC) Design & Verification Techniques Using SystemVerilog"* (SNUG 2008) — **essential reading**. This paper is cited in every CDC interview question. Covers metastability, 2-FF synchronizer, pulse synchronizer, gray code.
- **Cliff Cummings** *"Simulation and Synthesis Techniques for Asynchronous FIFO Design"* (SNUG 2002) — you read the theory in Week 5, now build it.
- **ChipVerify**: https://www.chipverify.com/verilog/verilog-clock-domain-crossing

### Design Notes for the Register File
- **x0 hardwired to zero** — this is a RISC-V convention; any write to x0 is ignored, reads always return 0
- **2 read ports, 1 write port** — standard for single-issue CPUs
- **Write-first behavior**: if you read and write the same register on the same cycle, the read should return the NEW value (forwarding within the register file)
- **Use `always_ff`** for the write port, **`always_comb`** for read ports
- This register file will be reused in your RISC-V CPU (Weeks 7-8)

### Design HW1: Register File
Build the register file as part of verification HW3, but design it as a standalone, well-tested module first. See HW3 verification spec above for the interface.

### Design HW2: 2-FF Synchronizer & Pulse Synchronizer
These are the fundamental CDC building blocks. Every ASIC has hundreds of them.

```systemverilog
// Part A: Basic 2-FF synchronizer (for slow-changing signals)
module sync_2ff #(
    parameter WIDTH = 1
)(
    input  logic             clk_dst,    // destination clock
    input  logic             rst_n,
    input  logic [WIDTH-1:0] data_in,    // from source clock domain
    output logic [WIDTH-1:0] data_out    // synchronized to clk_dst
);
    // Two back-to-back flip-flops
    // The first FF may go metastable — the second FF resolves it
    // ONLY use for signals that change slowly (level signals, not pulses)
endmodule

// Part B: Pulse synchronizer (for single-cycle pulses across domains)
module pulse_sync (
    input  logic clk_src, clk_dst, rst_n,
    input  logic pulse_in,    // single-cycle pulse in clk_src domain
    output logic pulse_out    // single-cycle pulse in clk_dst domain
);
    // Method: toggle a flag in source domain, synchronize the toggle to
    // destination domain, detect edges on the synchronized toggle
    //
    // This handles the case where clk_src pulse is too short for clk_dst
    // to sample directly
endmodule
```

Write a testbench with two clock domains (e.g., 100 MHz and 37 MHz — intentionally non-integer ratio):
1. Drive level signal changes through 2-FF sync, verify they arrive (with 2-cycle latency)
2. Drive single-cycle pulses through pulse sync, verify each pulse arrives exactly once
3. Drive pulses very close together — verify none are lost

### Design HW3: Asynchronous FIFO
The crowning achievement of CDC design. Asked about in nearly every ASIC interview:

```systemverilog
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4    // DEPTH = 2^ADDR_WIDTH (must be power of 2!)
)(
    // Write domain
    input  logic                  wr_clk, wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    // Read domain
    input  logic                  rd_clk, rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);
    // Key design elements:
    // 1. Dual-port RAM for storage (from Week 5 Design HW2)
    // 2. Write pointer (binary) in write clock domain
    // 3. Read pointer (binary) in read clock domain
    // 4. Gray code conversion: binary -> gray for crossing domains
    //    gray = binary ^ (binary >> 1)
    // 5. Synchronize gray-coded write pointer to read domain (2-FF)
    // 6. Synchronize gray-coded read pointer to write domain (2-FF)
    // 7. Full detection: compare synced read pointer with write pointer
    //    Full when gray_wr_ptr == {~gray_rd_sync[MSB:MSB-1], gray_rd_sync[MSB-2:0]}
    // 8. Empty detection: compare synced write pointer with read pointer
    //    Empty when gray_rd_ptr == gray_wr_sync
    //
    // IMPORTANT: depth MUST be power of 2 for gray code to work correctly
endmodule
```

Write a testbench with asymmetric clocks (e.g., write at 100 MHz, read at 33 MHz):
1. Fill the FIFO completely — verify full flag
2. Drain completely — verify empty flag and data integrity (FIFO order)
3. Continuous write + read at different rates — verify no data corruption
4. Stress test: write bursts faster than read can drain

### Design HW4: Timing Analysis Exercise (Pen & Paper)
No RTL for this one — work through these on paper or a whiteboard. Understanding timing is critical for interviews:

1. **Setup & hold calculation**: Given Tclk=10ns, Tsetup=0.5ns, Thold=0.3ns, Tcq=0.8ns, and combinational delay=7ns: What is the slack? Can the design meet timing?

2. **Critical path identification**: Draw the datapath of your Week 4 ALU (inputs -> mux -> adder -> output register). Label each component's delay. What's the critical path? What's the maximum clock frequency?

3. **Pipelining for timing**: Take the multiplier from Week 4 HW3. If it were combinational (single cycle), the critical path would be WIDTH stages of add+shift. Show how breaking it into a multi-cycle design trades latency for throughput.

4. **Metastability MTBF**: Given a synchronizer with Tsetup=0.5ns, Tw=0.3ns (metastability window), clock=200MHz, input change rate=50MHz: Calculate MTBF with 1-FF vs 2-FF synchronizer. Why is 2-FF sufficient?

---

## Checklist

### Verification Track
- [ ] Read Rosenberg ch.8-10
- [ ] Watched Verification Academy Scoreboard + Coverage + Reporting
- [ ] Read ChipVerify scoreboard, reporting, phases pages
- [ ] Completed HW1 (Scoreboard with reference model)
- [ ] Completed HW2 (UVM coverage collector)
- [ ] Completed HW3 (Full register file UVM testbench — includes RTL design)
- [ ] Completed HW4 (Regression & coverage closure)
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: You can build a UVM testbench from scratch!**

### Design Track
- [ ] Read Dally ch.15 (timing constraints), ch.28 (metastability), ch.29 (synchronizer design)
- [ ] Read Cummings CDC paper (SNUG 2008)
- [ ] Read Cummings async FIFO paper (SNUG 2002)
- [ ] Completed Design HW1 (Register file with x0=0 and write-first)
- [ ] Completed Design HW2 (2-FF synchronizer + pulse synchronizer)
- [ ] Completed Design HW3 (Asynchronous FIFO with gray code pointers)
- [ ] Completed Design HW4 (Timing analysis pen-and-paper exercise)
- [ ] **MILESTONE: You understand CDC — the #1 source of silicon bugs!**
