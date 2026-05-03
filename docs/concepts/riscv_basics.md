# RISC-V Basics (RV32I)

**Category**: Architecture · **Used in**: W8 (single-cycle), W9 (pipeline), W13 portfolio · **Type**: authored

The base RV32I integer ISA is what your CPU project implements:
32-bit machine, 32 general-purpose registers (`x0..x31`, with `x0`
hardwired to zero), 47 instructions, no compressed encoding, no
floating point. Once RV32I is solid the M, A, F, C extensions are
incremental.

## Instruction formats

```
R-type:  funct7 | rs2 | rs1 | funct3 | rd  | opcode    (ADD, SUB, AND, ...)
I-type:  imm[11:0]    | rs1 | funct3 | rd  | opcode    (ADDI, LW, JALR)
S-type:  imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode  (SW)
B-type:  imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode  (BEQ, BNE)
U-type:  imm[31:12]   | rd  | opcode                            (LUI, AUIPC)
J-type:  imm[20|10:1|11|19:12] | rd | opcode                    (JAL)
```

Junior pitfalls:

- B-type and J-type immediates are **scrambled** in the encoding to
  let signed-ext use a single sign bit. Your decoder must
  reconstruct them.
- `x0` writes are silently dropped, but the RTL must not stall on
  them. Common implementation: gate the regfile write enable with
  `(rd != 5'd0)`.

## Single-cycle datapath (W8)

```
PC → IMEM → Decoder → {rs1, rs2, imm} → ALU → MEM (if load/store) → Writeback
```

Single-cycle means **the entire instruction completes in one clock**.
The clock period is bounded by the longest combinational path,
typically `IMEM_read + decode + regfile_read + ALU + DMEM + WB_mux`.
This sets a low Fmax — pipelining (W9) trades latency-per-instruction
for higher throughput.

## 5-stage pipeline (W9)

```
IF  | ID  | EX  | MEM | WB
```

Hazards:

| Hazard | Cause | Resolution |
|---|---|---|
| **RAW** (read-after-write) | EX stage needs result still in MEM/WB | forwarding (bypassing) |
| **Load-use** | `LW rd; ADD ..., rd, ...` back-to-back | 1-cycle stall (cannot forward, value not ready) |
| **Control** | branch taken | flush IF/ID; ≥1 bubble (or branch-prediction stretch) |
| **Structural** | shared resource (rare in 5-stage with split memories) | usually n/a in W9 |

## SV decoder skeleton (W8)

```systemverilog
always_comb begin
    case (instr[6:0])      // opcode
        7'b011_0011: kind = R_TYPE;
        7'b001_0011: kind = I_TYPE_ALU;
        7'b000_0011: kind = I_TYPE_LOAD;
        7'b010_0011: kind = S_TYPE;
        7'b110_0011: kind = B_TYPE;
        7'b110_1111: kind = J_TYPE;       // JAL
        7'b110_0111: kind = I_TYPE_JALR;
        7'b011_0111: kind = U_TYPE_LUI;
        7'b001_0111: kind = U_TYPE_AUIPC;
        default:     kind = ILLEGAL;
    endcase
end
```

The full decoder fans out to `funct3`/`funct7` for ALU op selection.
Use a separate `always_comb` for that to keep the table readable.

## Verification (W8, W9, W13)

- Directed self-check: hand-write small assembly programs and embed
  expected register state at end of run.
- Constrained-random ALU regression: drive random R/I-type ops, cross
  against a Python reference (`(a + b) & 0xFFFFFFFF` for `ADD`,
  signed comparison for `SLT`, etc.).
- Hazard regressions: handwritten programs that exercise RAW,
  load-use, and taken-branch.
- SVA: pipeline-register propagation invariants (`IF.PC + 4 ==
  ID.PC` unless flush, etc.).

## Reading

- Harris & Harris *Digital Design and Computer Architecture: RISC-V*,
  ch.5 (architecture) + ch.7 §7.1–§7.6 (single-cycle, multi-cycle,
  pipelined). Page-precise refs go in `docs/week_08.md` and
  `docs/week_09.md` once Yuval picks his W8 starting page.
- Official RISC-V ISA spec, Volume I (Unprivileged), V20191213 base
  — riscv.org/specifications.

## Cross-links

- `[[adders_carry_chain]]` — ALU adder.
- `[[multiplexers_decoders]]` — instruction decoder.
- `[[memory_models]]` — register file.
- `[[fsm_encoding_styles]]` — control unit FSM (multi-cycle if you
  go that route).
