# Week 8: Pipelined CPU & Hazard Handling

## Why This Matters
Every real CPU is pipelined. Understanding pipeline hazards (data, control, structural) and their solutions (forwarding, stalling, flushing) is essential interview knowledge. Building this proves you understand hardware at the microarchitecture level.

## What to Study

### Reading
- **Harris & Harris ch.7.5-7.8**: Pipelining
  - 5-stage pipeline: IF, ID, EX, MEM, WB
  - Pipeline registers
  - Data hazards: RAW (read-after-write)
  - Forwarding (bypassing)
  - Stalls (load-use hazard)
  - Control hazards: branch prediction, pipeline flush
- **Patterson & Hennessy** (optional, deeper): Chapter 4 "The Processor"

### Videos
- **MIT 6.004**: Pipelining lectures (2-3 lectures)
- **Harris & Harris** lecture on pipelining if available

### Reference
- Your single-cycle CPU from Week 7 is the starting point

---

## Homework

### HW1: Add Pipeline Registers
Take your single-cycle CPU and insert pipeline registers between each stage:

```
IF/ID Register:
    - instruction
    - pc
    - pc_plus4

ID/EX Register:
    - control signals (reg_write, mem_write, mem_read, branch, alu_src, alu_control, mem_to_reg)
    - read_data1, read_data2
    - immediate
    - rd, rs1, rs2
    - pc, pc_plus4

EX/MEM Register:
    - control signals (reg_write, mem_write, mem_read, branch, mem_to_reg)
    - alu_result
    - write_data (for store)
    - rd
    - zero flag
    - branch_target

MEM/WB Register:
    - control signals (reg_write, mem_to_reg)
    - alu_result
    - read_data (from memory)
    - rd
```

Implement as a struct or individual registers. Run your Week 7 test programs — they will FAIL due to hazards. That's expected!

Document which tests fail and why (identify the specific hazard in each case).

### HW2: Forwarding Unit
Implement the forwarding (bypass) unit to solve most data hazards:

```systemverilog
module forwarding_unit (
    input  logic [4:0] rs1_ex,       // source register 1 in EX stage
    input  logic [4:0] rs2_ex,       // source register 2 in EX stage
    input  logic [4:0] rd_mem,       // destination register in MEM stage
    input  logic [4:0] rd_wb,        // destination register in WB stage
    input  logic       reg_write_mem, // writing in MEM stage?
    input  logic       reg_write_wb,  // writing in WB stage?
    output logic [1:0] forward_a,    // 00=reg, 01=WB, 10=MEM
    output logic [1:0] forward_b     // 00=reg, 01=WB, 10=MEM
);
    // Forwarding logic:
    // EX hazard:  forward from MEM stage if rd_mem matches rs1/rs2
    // MEM hazard: forward from WB stage if rd_wb matches rs1/rs2
    // Priority:   EX hazard takes precedence over MEM hazard
    // Exception:  never forward from x0
endmodule
```

Add MUXes before the ALU inputs to select between:
- Register file output (no hazard)
- MEM stage result (EX-EX forwarding)
- WB stage result (MEM-EX forwarding)

Re-run tests — ALU-to-ALU sequences should now work:
```
addi x1, x0, 5
addi x2, x1, 3    # needs forwarding: x1 from previous instruction
```

### HW3: Hazard Detection Unit (Stall for Load-Use)
Forwarding can't solve everything. A load followed by a use needs a 1-cycle stall:

```
lw   x1, 0(x0)    # x1 available after MEM stage
add  x2, x1, x3   # needs x1 in EX stage — too early!
```

```systemverilog
module hazard_detection_unit (
    input  logic [4:0] rs1_id,       // source registers in ID stage
    input  logic [4:0] rs2_id,
    input  logic [4:0] rd_ex,        // destination in EX stage
    input  logic       mem_read_ex,  // is EX stage a load?
    output logic       stall         // insert bubble
);
    // Stall if: EX stage is a load AND its rd matches ID stage rs1 or rs2
    assign stall = mem_read_ex &&
                   ((rd_ex == rs1_id) || (rd_ex == rs2_id)) &&
                   (rd_ex != 5'b0);
endmodule
```

When stalling:
- Freeze PC (don't update)
- Freeze IF/ID register (don't update)
- Insert NOP (bubble) into ID/EX register (zero all control signals)

Test with:
```
lw   x1, 0(x0)
add  x2, x1, x3   # should stall 1 cycle, then forward
```

### HW4: Branch Handling (Flush on Misprediction)
Implement branch handling with "predict not taken" strategy:

- Always fetch the next sequential instruction (predict not taken)
- If the branch IS taken (detected in MEM or EX stage):
  - Flush the incorrectly fetched instructions (zero out IF/ID and ID/EX registers)
  - Set PC to branch target

```systemverilog
module branch_unit (
    input  logic        branch_mem,    // is MEM stage a branch?
    input  logic        zero_mem,      // ALU zero flag
    input  logic [31:0] branch_target, // computed target
    output logic        flush,         // flush IF/ID and ID/EX
    output logic        pc_sel         // 0=PC+4, 1=branch_target
);
endmodule
```

Test with:
```
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, target   # taken — must flush next 2 instructions
addi x3, x0, 99       # FLUSHED — should NOT execute
addi x4, x0, 99       # FLUSHED — should NOT execute
target:
addi x5, x0, 1        # x5 = 1
```

### HW5: Comprehensive Hazard Tests
Write test programs that trigger each specific hazard:

```
# Test A: EX-EX forwarding (no stall needed)
addi x1, x0, 1
add  x2, x1, x1     # forward x1 from EX/MEM

# Test B: MEM-EX forwarding
addi x1, x0, 1
nop
add  x2, x1, x1     # forward x1 from MEM/WB

# Test C: Load-use stall + forward
lw   x1, 0(x0)
add  x2, x1, x0     # stall 1 cycle, then forward

# Test D: Branch taken — flush
beq  x0, x0, skip
addi x1, x0, 99     # must be flushed
skip: addi x1, x0, 1

# Test E: Back-to-back loads
lw   x1, 0(x0)
lw   x2, 4(x0)
add  x3, x1, x2     # double forwarding

# Test F: Store after load (no hazard for store data)
lw   x1, 0(x0)
sw   x1, 4(x0)      # needs forwarding for store data

# Test G: Full program — sum 1 to 10 (combines everything)
```

All tests must produce correct results. Verify in waveform.

---

## Self-Check Questions
1. What are the three types of hazards? Give an example of each.
2. Why can't forwarding solve the load-use hazard?
3. What's the performance penalty of a branch misprediction in a 5-stage pipeline?
4. What's the difference between "predict not taken" and "predict taken"?
5. Draw the pipeline diagram for: `lw x1, 0(x0)` followed by `add x2, x1, x3` — show the stall bubble.
6. Could you move branch resolution to the ID stage? What would change?

---

## Checklist
- [ ] Read Harris & Harris ch.7.5-7.8
- [ ] Watched MIT 6.004 pipelining lectures
- [ ] Completed HW1 (Pipeline registers — tests fail due to hazards)
- [ ] Completed HW2 (Forwarding unit — ALU-ALU tests pass)
- [ ] Completed HW3 (Hazard detection — load-use tests pass)
- [ ] Completed HW4 (Branch handling — branch tests pass)
- [ ] Completed HW5 (All 7 hazard test programs pass)
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: Working pipelined RISC-V CPU!**
