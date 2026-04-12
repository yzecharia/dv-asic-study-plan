# Week 6: Full UVM Testbench Integration

## Why This Matters
This is where everything comes together. You'll build a complete, working UVM testbench end-to-end for a real DUT. After this week, you can say "I know UVM" in an interview and back it up.

## What to Study

### Reading
- **Rosenberg & Meade ch.8-10**: "Scoreboard", "Coverage", "Reporting"
  - Reference models inside scoreboard
  - Functional coverage integration in UVM
  - UVM reporting: `uvm_info`, `uvm_warning`, `uvm_error`, `uvm_fatal`
  - Verbosity control
  - End-of-test mechanism: `phase.raise_objection()` / `phase.drop_objection()`

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

```systemverilog
class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)

    uvm_analysis_imp #(alu_transaction, alu_scoreboard) imp;

    int pass_count = 0;
    int fail_count = 0;

    virtual function void write(alu_transaction txn);
        bit [8:0] expected;

        // Reference model — compute expected result
        case (txn.operation)
            ADD: expected = txn.operand_a + txn.operand_b;
            SUB: expected = txn.operand_a - txn.operand_b;
            AND: expected = txn.operand_a & txn.operand_b;
            OR:  expected = txn.operand_a | txn.operand_b;
            XOR: expected = txn.operand_a ^ txn.operand_b;
        endcase

        if (txn.result === expected) begin
            pass_count++;
            `uvm_info("SCB", $sformatf("PASS: %s", txn.convert2string()), UVM_HIGH)
        end else begin
            fail_count++;
            `uvm_error("SCB", $sformatf("FAIL: got %0h, expected %0h | %s",
                txn.result, expected, txn.convert2string()))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("RESULTS: %0d passed, %0d failed out of %0d total",
            pass_count, fail_count, pass_count + fail_count), UVM_LOW)
        if (fail_count > 0)
            `uvm_error("SCB", "TEST FAILED — there were mismatches!")
        else
            `uvm_info("SCB", "TEST PASSED — all transactions matched!", UVM_LOW)
    endfunction
endclass
```

### HW2: Functional Coverage in UVM
Add a coverage collector component to your environment:

```systemverilog
class alu_coverage extends uvm_subscriber #(alu_transaction);
    `uvm_component_utils(alu_coverage)

    alu_transaction txn;

    covergroup alu_cg;
        cp_operation: coverpoint txn.operation;
        cp_a: coverpoint txn.operand_a {
            bins zero = {0};
            bins low = {[1:63]};
            bins mid = {[64:191]};
            bins high = {[192:254]};
            bins max = {255};
        }
        cp_b: coverpoint txn.operand_b {
            bins zero = {0};
            bins low = {[1:63]};
            bins mid = {[64:191]};
            bins high = {[192:254]};
            bins max = {255};
        }
        cx_op_a: cross cp_operation, cp_a;
        cx_op_b: cross cp_operation, cp_b;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        alu_cg = new();
    endfunction

    virtual function void write(alu_transaction t);
        txn = t;
        alu_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Coverage: %.2f%%", alu_cg.get_coverage()), UVM_LOW)
    endfunction
endclass
```

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

## Design Track: Register File

Week 6 HW3 already asks you to design a register file. Here are the industry design guidelines:

### Design Notes for the Register File
- **x0 hardwired to zero** — this is a RISC-V convention; any write to x0 is ignored, reads always return 0
- **2 read ports, 1 write port** — standard for single-issue CPUs
- **Write-first behavior**: if you read and write the same register on the same cycle, the read should return the NEW value (forwarding within the register file)
- **Use `always_ff`** for the write port, **`always_comb`** for read ports
- This register file will be reused in your RISC-V CPU (Weeks 7-8)

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
- [ ] Register file RTL written with industry practices (part of HW3)
- [ ] Register file handles x0=0 and write-first correctly
