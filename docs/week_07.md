# Week 7: RISC-V ISA & Single-Cycle CPU

## Why This Matters
Computer architecture knowledge separates "I can write Verilog" from "I understand what I'm building." A CPU project on your resume proves deep understanding of digital design — datapath, control, instruction decoding, memory hierarchy. Israeli semiconductor companies (Intel, Marvell, Qualcomm) love this.

You already have `DDCA_RISCV` on your machine — this week you either extend it or rebuild it properly in SystemVerilog with verification in mind.

## What to Study

### Reading
- **Harris & Harris ch.6**: "Architecture" — RISC-V ISA, instruction formats
- **Harris & Harris ch.7 (7.1-7.3)**: "Microarchitecture" — single-cycle implementation
- **RISC-V Spec Volume 1** (free PDF from riscv.org): Chapter 2 — RV32I Base Integer ISA
  - Only 47 instructions. Manageable.
  - Focus on: R-type, I-type, S-type, B-type, U-type, J-type formats

### Videos
- **MIT 6.004** (YouTube/OCW): Lectures on single-cycle processor
- **Harris & Harris lecture videos** if available from your university

### Reading (Design Best Practices)
- **Dally & Harting ch.17**: "Factoring Finite-State Machines" — decomposing complex FSMs into smaller, manageable pieces. Directly applicable to the CPU control unit.
- **Dally & Harting ch.18**: "Microcode" — microprogrammed control vs hardwired control. Understanding the tradeoff between the two approaches for instruction decoding.
- **Dally & Harting ch.9**: "Combinational Examples" — worked examples of combinational design including decoders and control logic.
- **Cliff Cummings** *"Full Case Parallel Case"* — understanding synthesis pragmas for case statements (critical for decoders)
- **Cliff Cummings** *"Coding And Scripting Techniques for FSM Designs with Synthesis-Optimized, Glitch-Free Outputs"*

### Reference
- RISC-V Green Card (instruction reference sheet) — Google "RISC-V reference card PDF"
- Your existing code in `/Users/yuval/verilog_projects/DDCA_RISCV/`

### Industry Design Guidelines for the CPU
- **Separate datapath from control** — decoder/control in one module, datapath in another
- **Use enums for opcodes and ALU operations** — not raw bit patterns
- **Use `always_comb` with `unique case`** for the decoder — catches missing cases at simulation time
- **Parameterize the data width** even if you only use 32-bit — shows good design habits
- **Name your signals clearly**: `alu_result`, not `res`; `mem_write_en`, not `mw`

---

## Homework

### HW1: RISC-V Instruction Decoder
Write a standalone instruction decoder module:

```systemverilog
module rv32i_decoder (
    input  logic [31:0] instruction,
    output logic [6:0]  opcode,
    output logic [4:0]  rd, rs1, rs2,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,
    output logic [31:0] imm,           // sign-extended immediate
    output logic [3:0]  alu_control,   // decoded ALU operation
    output logic        reg_write,     // write to register file
    output logic        mem_write,     // write to memory
    output logic        mem_read,      // read from memory
    output logic        branch,        // branch instruction
    output logic        jump,          // JAL/JALR
    output logic [1:0]  alu_src        // ALU operand B source
);
```

Supported instruction types:
- **R-type:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
- **I-type:** ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI, LW, JALR
- **S-type:** SW
- **B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU
- **U-type:** LUI, AUIPC
- **J-type:** JAL

Write a testbench that feeds known instruction encodings and verifies all outputs. Use a reference table from the RISC-V spec.

### HW2: ALU with All RV32I Operations
Write the ALU module:

```systemverilog
module rv32i_alu (
    input  logic [31:0] a, b,
    input  logic [3:0]  alu_control,
    output logic [31:0] result,
    output logic        zero,          // result == 0
    output logic        negative,      // result[31]
    output logic        overflow       // signed overflow
);
    // Operations based on alu_control:
    // ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
endmodule
```

Write a thorough testbench:
- All operations with corner cases (0, -1, MAX_INT, MIN_INT)
- Overflow detection for ADD/SUB
- Shift by 0, 1, 31
- SLT vs SLTU difference (signed vs unsigned comparison)

### HW3: Single-Cycle Datapath
Build the complete single-cycle CPU. Key modules:

```
                    +----------+
Instruction  ------>| Decoder  |-----> Control signals
Memory              +----------+
    |                                    |
    v                                    v
+--------+    +--------+    +-----+    +--------+
|   PC   |--->| I-Mem  |--->| Reg |--->| ALU    |---> Data Memory
+--------+    +--------+    | File|    +--------|     (Load/Store)
    ^                       +--------+
    |                           ^
    +------ PC+4 / Branch -----+
```

Modules to implement:
1. `program_counter` — PC register with reset
2. `instruction_memory` — ROM initialized from file
3. `register_file` — 32 x 32-bit (x0 hardwired to 0)
4. `rv32i_alu` — from HW2
5. `rv32i_decoder` — from HW1
6. `data_memory` — RAM for loads/stores
7. `imm_generator` — extract and sign-extend immediates
8. `rv32i_top` — top-level connecting everything

### HW4: Assembly Test Programs
Write small RISC-V assembly programs (or hand-encode the hex) to test your CPU:

**Test 1: Basic ALU**
```
addi x1, x0, 5      # x1 = 5
addi x2, x0, 3      # x2 = 3
add  x3, x1, x2     # x3 = 8
sub  x4, x1, x2     # x4 = 2
and  x5, x1, x2     # x5 = 1
or   x6, x1, x2     # x6 = 7
```

**Test 2: Memory**
```
addi x1, x0, 42     # x1 = 42
sw   x1, 0(x0)      # mem[0] = 42
lw   x2, 0(x0)      # x2 = mem[0] = 42
```

**Test 3: Branches**
```
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, skip   # should branch
addi x3, x0, 1      # should NOT execute
skip:
addi x3, x0, 2      # x3 should be 2
```

**Test 4: Loop (sum 1 to 10)**
```
addi x1, x0, 0      # sum = 0
addi x2, x0, 1      # i = 1
addi x3, x0, 11     # limit = 11
loop:
add  x1, x1, x2     # sum += i
addi x2, x2, 1      # i++
bne  x2, x3, loop   # if i != 11, loop
# x1 should be 55
```

Load each program into instruction memory, simulate, verify results in waveform.

Tip: Use https://riscvasm.lucasteske.dev/ (online RISC-V assembler) to convert assembly to hex.

---

## Self-Check Questions
1. What are the 6 RISC-V instruction formats? Draw each one with bit fields.
2. Why is x0 hardwired to zero? What problem does it solve?
3. How does the immediate encoding differ between I-type, S-type, and B-type?
4. What control signals are needed to distinguish ADD from SUB? (Hint: funct7)
5. What's the critical path of a single-cycle CPU?
6. Why is single-cycle impractical for real CPUs? (preview for Week 8)

---

## Bonus: Signed Arithmetic & Fixed-Point Numbers

Most academic DV courses cover signed/fixed-point arithmetic explicitly because
DSP and AI accelerator pipelines use it everywhere. Your RISC-V ALU already
exercises signed comparisons (`SLT`/`SLTU`) and arithmetic shifts (`SRA`); this
section pushes a level deeper.

### Reading
- Dally & Harting **ch.10 §10.1-10.4**: signed two's complement, sign extension,
  overflow detection on signed adds.
- Wikipedia **"Q (number format)"**: a 5-min read on Q1.15 / Q15.16 / general
  Qm.n notation used in DSP.
- ChipVerify **"SystemVerilog signed and unsigned"** (search the site).

### Bonus HW5: Signed & Fixed-Point ALU Extensions
1. **Signed multiplication**: extend HW2's ALU to compute the full 64-bit
   signed product `A * B` for two 32-bit signed operands. Verify against
   Verilog's `signed'(...)` cast.
2. **Q15.16 fixed-point multiply**: build a tiny `qmul.sv` that takes two
   `signed [31:0]` inputs interpreted as Q15.16, multiplies, and returns the
   correctly scaled Q15.16 result (i.e., the 64-bit product right-shifted by 16,
   with rounding).
3. **Saturating add**: `sat_add.sv` — signed 16-bit add that clamps at
   `+0x7FFF` / `-0x8000` instead of wrapping. Used in DSP/audio pipelines.
4. **Testbench**: random + directed corner cases (max+1, min-1, sign-flip).

Why care: AI accelerators (Gaudi, NVIDIA Tensor Cores) and DSP IPs verify
exactly these number formats. Even if a junior DV role doesn't ask for it,
knowing Q-format and saturation gives you something real to discuss in
interviews about AI / signal-processing teams.

---

## Checklist
- [ ] Read Harris & Harris ch.6 and ch.7.1-7.3
- [ ] Read RISC-V spec RV32I chapter
- [ ] Downloaded RISC-V reference card
- [ ] Watched MIT 6.004 single-cycle processor lecture
- [ ] Completed HW1 (Instruction decoder)
- [ ] Completed HW2 (ALU with all operations)
- [ ] Completed HW3 (Single-cycle datapath)
- [ ] Completed HW4 (Assembly test programs — all 4 pass)
- [ ] *(Bonus)* Completed HW5 (Signed mul + Q15.16 fixed-point + saturating add)
- [ ] Can answer all self-check questions
