# Week 12: Portfolio Projects #2 & #3 — RISC-V CPU + FIFO UVM

## Why This Matters
Three GitHub repos is the magic number. It shows consistency, not a one-off. The RISC-V CPU shows architecture depth, the FIFO UVM shows you can verify any IP block. Together with the UART, you have a portfolio that makes you stand out from other junior candidates.

---

## Project #2: RISC-V Pipelined CPU

### Step 1: Clean Up
Take your Week 7-8 RISC-V code and organize it:

```
riscv-sv-cpu/
    rtl/
        rv32i_top.sv
        program_counter.sv
        instruction_memory.sv
        register_file.sv
        rv32i_decoder.sv
        rv32i_alu.sv
        imm_generator.sv
        data_memory.sv
        forwarding_unit.sv
        hazard_detection_unit.sv
        branch_unit.sv
        pipeline_registers.sv
    tb/
        rv32i_tb.sv
        test_programs/
            test_alu.hex
            test_memory.hex
            test_branch.hex
            test_hazards.hex
            test_sum_1_to_10.hex
    sim/
        Makefile
    docs/
        pipeline_diagram.png    # draw this!
        datapath.png           # block diagram
    README.md
```

### Step 2: Add a Good Testbench
If you only have basic tests, enhance:
- Self-checking tests (program writes result to a known memory address, testbench reads it)
- Assertion: PC never goes to an invalid address
- Assertion: x0 is always 0
- Print register file contents at end of each test

### Step 3: README
```markdown
# RISC-V RV32I Pipelined CPU

## Overview
5-stage pipelined RISC-V processor implementing the RV32I base integer instruction set.

## Architecture
![Pipeline Diagram](docs/pipeline_diagram.png)

## Features
- 5-stage pipeline: IF, ID, EX, MEM, WB
- Full data forwarding (EX-EX, MEM-EX)
- Load-use hazard detection with pipeline stall
- Branch handling with flush on misprediction
- 47 RV32I instructions supported

## Supported Instructions
| Type | Instructions |
|------|-------------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| I-type | ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI, LW, JALR |
| S-type | SW |
| B-type | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| U-type | LUI, AUIPC |
| J-type | JAL |

## Test Results
| Test | Description | Result |
|------|------------|--------|
| ALU | Basic arithmetic/logic operations | PASS |
| Memory | Load/store operations | PASS |
| Branch | All branch types + flush verification | PASS |
| Hazards | Forwarding + stall scenarios | PASS |
| Sum 1-10 | Integration test (result = 55) | PASS |

## How to Run
```
make compile
make run TEST=test_sum_1_to_10
make all  # run all tests
```
```

### Step 4: Push to GitHub
```bash
git init && git add . && git commit -m "5-stage pipelined RISC-V RV32I CPU"
git remote add origin https://github.com/YOUR_USERNAME/riscv-sv-cpu.git
git push -u origin main
```

---

## Project #3: Synchronous FIFO with UVM Testbench

### Step 1: RTL
Design a parameterized synchronous FIFO:

```systemverilog
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic                  clk, rst_n,
    input  logic                  wr_en, rd_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full, empty,
    output logic                  overflow, underflow,
    output logic [$clog2(DEPTH):0] count
);
```

Key behaviors to implement:
- Circular buffer with read/write pointers
- Full when count == DEPTH
- Empty when count == 0
- Overflow: write when full (flag it, don't write)
- Underflow: read when empty (flag it, don't read)
- Simultaneous read+write: always works (count stays same)

### Step 2: UVM Testbench
```
fifo-uvm-verification/
    rtl/
        sync_fifo.sv
    tb/
        fifo_pkg.sv
        fifo_if.sv
        fifo_seq_item.sv       # operation (PUSH/POP/BOTH/IDLE) + data
        fifo_driver.sv
        fifo_monitor.sv
        fifo_agent.sv
        fifo_scoreboard.sv     # reference model: SV queue [$]
        fifo_coverage.sv
        fifo_env.sv
        fifo_tests.sv
        fifo_sequences.sv
        tb_top.sv
    sim/
        Makefile
    README.md
```

**Scoreboard reference model:**
```systemverilog
// Inside scoreboard — behavioral FIFO model
logic [DATA_WIDTH-1:0] ref_queue[$];

function void write(fifo_transaction txn);
    case (txn.operation)
        PUSH: begin
            if (ref_queue.size() < DEPTH)
                ref_queue.push_back(txn.wr_data);
            // else: expect overflow flag
        end
        POP: begin
            if (ref_queue.size() > 0) begin
                expected = ref_queue.pop_front();
                assert(txn.rd_data == expected);
            end
            // else: expect underflow flag
        end
        PUSH_AND_POP: begin
            // Handle simultaneous
        end
    endcase
endfunction
```

**Coverage targets:**
- FIFO states: empty, partially filled, full
- Transitions: empty->non-empty, non-empty->full, full->non-empty, non-empty->empty
- Operations at each state: push when full, pop when empty, push+pop at all states
- Data patterns: all zeros, all ones, alternating
- Count values: every value from 0 to DEPTH hit
- Overflow flag asserted
- Underflow flag asserted

**Tests:**
- `fifo_fill_drain_test`: fill completely, then drain completely
- `fifo_random_test`: random push/pop for 10000 cycles
- `fifo_stress_test`: push+pop simultaneously at various fill levels
- `fifo_overflow_test`: push beyond capacity, verify overflow flag
- `fifo_underflow_test`: pop when empty, verify underflow flag
- `fifo_coverage_test`: run until 100% coverage

### Step 3: Push to GitHub

---

## Final Steps: Update Your CV & LinkedIn

### Update plain_text_resume.yaml
Add to the projects section:
```yaml
projects:
  - name: "UART with UVM Verification"
    description: "Designed UART TX/RX IP core with full UVM testbench including constrained random verification, coverage-driven methodology, and reference model scoreboard. Achieved 100% functional coverage."
    link: "https://github.com/YOUR_USERNAME/uart-uvm-verification"
  - name: "RISC-V RV32I Pipelined CPU"
    description: "Built a 5-stage pipelined RISC-V processor in SystemVerilog with data forwarding, hazard detection, and branch handling. Verified with self-checking assembly test programs."
    link: "https://github.com/YOUR_USERNAME/riscv-sv-cpu"
  - name: "Synchronous FIFO with UVM Verification"
    description: "Parameterized synchronous FIFO with complete UVM testbench. Coverage-driven verification with overflow/underflow testing and 100% functional coverage."
    link: "https://github.com/YOUR_USERNAME/fifo-uvm-verification"
```

### Update LinkedIn
- Add all 3 projects to your LinkedIn profile
- Add skills: UVM, SystemVerilog Verification, Constrained Random, Functional Coverage
- Update headline to mention verification

### Update AutoApply Bot
- Update `data_folder/plain_text_resume.yaml` with new projects
- Add your GitHub URL to the config
- Restart the bot — it will now include your projects when applying!

---

## Checklist

### RISC-V CPU (Project #2)
- [ ] Code organized in clean project structure
- [ ] All test programs pass
- [ ] Pipeline diagram drawn
- [ ] README written
- [ ] Pushed to GitHub

### FIFO UVM (Project #3)
- [ ] FIFO RTL implemented and tested
- [ ] Full UVM environment built
- [ ] All 6 tests pass
- [ ] Coverage >95%
- [ ] README written
- [ ] Pushed to GitHub

### Profile Updates
- [ ] plain_text_resume.yaml updated with 3 projects
- [ ] LinkedIn profile updated
- [ ] GitHub profile has 3 repos with READMEs
- [ ] AutoApply bot restarted with new resume

---

## **CONGRATULATIONS!**

You now have:
- SystemVerilog verification skills (OOP, constrained random, coverage, assertions)
- UVM methodology (full testbench from scratch)
- Computer architecture knowledge (pipelined RISC-V CPU)
- Protocol experience (UART, SPI, AXI-Lite)
- 3 GitHub portfolio projects
- An auto-apply bot sending your improved CV to relevant jobs

You are ready for junior DV/FPGA/ASIC interviews in Israel. Good luck!
