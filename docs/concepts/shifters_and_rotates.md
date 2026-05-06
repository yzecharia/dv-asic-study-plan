# Shifters and Rotates

**Category**: Combinational · **Used in**: W4 HW3 (barrel shifter), W8 (RV32I ALU shift unit), W16 (fixed-point Q-format scaling) · **Type**: authored

A shifter takes a data word and a shift amount, and produces the
data word displaced by that many bit positions. The variants differ
in **what fills the vacated bits** and **whether the displaced bits
wrap around**. Get the names straight before writing RTL — every
ISA spec, every textbook, and every linter assumes them.

## The five canonical operations

| Mnemonic | Name                       | Fill on the vacated side                              | RISC-V op | Verilog operator | SV signed operator |
|----------|----------------------------|-------------------------------------------------------|-----------|------------------|--------------------|
| **SLL**  | Shift Left Logical         | LSBs filled with `0`                                  | `sll`     | `<<`             | `<<`               |
| **SRL**  | Shift Right Logical        | MSBs filled with `0`                                  | `srl`     | `>>`             | `>>`               |
| **SRA**  | Shift Right Arithmetic     | MSBs filled with the **original sign bit** (`a[N-1]`) | `sra`     | n/a (use `>>>` on `signed`) | `>>>`     |
| **ROL**  | Rotate Left (Circular)     | LSBs filled with the bits **shifted out of the MSB**  | (RV-Zbb `rol`) | manual: `{a, a} >> ...` slice | manual |
| **ROR**  | Rotate Right (Circular)    | MSBs filled with the bits **shifted out of the LSB**  | (RV-Zbb `ror`) | manual              | manual             |

There is no "Shift Left Arithmetic" as a distinct operation — SLA is
exactly SLL on a two's-complement value (multiplying by 2 is the
same bit-shift regardless of sign), so most ISAs (including RISC-V)
do not name it separately.

## Why SRA exists at all

`SRL` of a negative two's-complement number gives the wrong
*arithmetic* answer. Example, 8-bit:

```
a       = 8'sb1111_1100   // -4 in two's complement
SRL 1   = 8'b0111_1110   //  126 — garbage if you wanted -2
SRA 1   = 8'b1111_1110   //   -2 — correct (preserves sign)
```

`SRA` is exactly "divide by 2^N, rounding toward −∞". `SRL` is
"divide the *unsigned* interpretation by 2^N". Pick the one that
matches your operand's signedness, not the one that "shifts right."

## SystemVerilog operator semantics — read the small print

```systemverilog
logic        [7:0] u;     // unsigned (default)
logic signed [7:0] s;     //   signed

u >>  3   // SRL — fills with 0
u >>> 3   // ALSO SRL — operator follows operand signedness, and `u` is unsigned
s >>  3   // SRL — same warning: `>>` ignores the signed declaration
s >>> 3   // SRA — finally arithmetic, because both operator AND operand agree
```

**Trap**: writing `data >>> n` where `data` is `logic [W-1:0]`
(unsigned by default) silently behaves like `>>` — the `>>>`
operator only does sign-extension when **its left operand is
declared signed**. Salemi/Sutherland call this out; lint tools
(Verilator, Spyglass) flag it as a likely-wrong-result style
violation.

If you want a parameterisable arithmetic shift on an unsigned bus
without flipping the whole declaration to `signed`, cast at the
operator:

```systemverilog
assign y = $signed(a) >>> shamt;   // explicit one-shot
```

## Hardware structures — three families

### 1. Barrel / funnel shifter (logarithmic mux cascade)

`log2(WIDTH)` stages, stage `i` is a 2:1 mux per bit selected by
`shamt[i]`. Single-cycle, combinational, area `O(W·log W)`,
critical path `O(log W)`. This is the textbook "fast shifter" and
the canonical W4 HW3 / W8 ALU implementation.

```
shamt[2]  shamt[1]  shamt[0]
   │         │         │
data ─► [shift 4] ─► [shift 2] ─► [shift 1] ─► y
```

### 2. Iterative / sequential shifter

One shift per cycle, controlled by a counter. Area `O(W)`, latency
`O(W)` cycles. Found in tiny embedded cores or where shift latency
is not on the critical timing path. Almost never used in modern
ALUs — barrel shifters are cheap enough that nobody pays the
multi-cycle penalty.

### 3. Funnel shifter (rotate-friendly variant)

Inputs are a **`2W`-bit concatenation** `{a_high, a_low}` and a
shift amount, output is a `W`-bit window. Lets you do shifts,
rotates, and double-precision shifts (e.g. for a 64-bit shift on a
32-bit datapath) with the same hardware. RISC-V Zbb's `fsl`/`fsr`
instructions map directly to a funnel shifter; ARM's barrel shifter
inside the ALU is essentially a funnel shifter exposed at the
register-read stage.

## Implementing all five operations on one barrel shifter

The trick most textbooks teach: build a **right shifter** in
hardware, and reuse it for the others by bit-reversing inputs and
outputs.

```systemverilog
// Pseudocode skeleton — one shifter, five operations
always_comb begin
    logic [WIDTH-1:0] in, out;
    case (op)
        SLL : in = {<<{a}};                  // bit-reverse  → right-shift → bit-reverse output
        SRL : in = a;
        SRA : in = a;                         // same path; but funnel uses a[W-1] as fill
        ROL : in = {<<{a}};                   // rotate via bit-reverse trick
        ROR : in = a;
    endcase
    // ... feed `in` into the right-shift cascade with appropriate fill ...
end
```

`{<<{a}}` is SV-2012 streaming-operator syntax for bit-reversal —
synthesisable, no for-loop required.

## Edge cases that catch juniors

1. **`shamt >= WIDTH`**: SV defines `a >> WIDTH` as `0` (entirely
   shifted out). RISC-V differs: only the low `log2(WIDTH)` bits of
   the shift amount are used (`shamt mod WIDTH`). If you're
   modelling RV32I, mask `shamt` to `[$clog2(WIDTH)-1:0]` before
   the shifter, or your TB will catch a divergence vs the ISA spec.
2. **Negative `shamt`**: `<<` and `>>` in SV require an unsigned
   right operand at synthesis time. A signed `shamt` whose top bit
   is set is treated as a very large unsigned number — i.e. the
   result is `0`. Verilator warns; XSIM doesn't.
3. **`WIDTH == 1` corner**: `$clog2(1) == 0`, which makes
   `[$clog2(WIDTH)-1:0]` an illegal `[-1:0]` range. Either constrain
   `WIDTH >= 2` with an `initial assert` or guard the localparam:
   `localparam SHAMT_W = (WIDTH > 1) ? $clog2(WIDTH) : 1;`.
4. **SRA with constant shift amount on unsigned input**: synthesis
   will silently drop the sign-extension. If the lint waiver list
   shows `WIDTHEXPAND` warnings on a shifter, this is usually why.

## Reading

- Dally & Harting *Digital Design: A Systems Approach* ch.12 (Fast
  Arithmetic) — barrel-shifter mux cascade and funnel variant.
- Harris & Harris *Digital Design and Computer Architecture* (RISC-V
  ed.) — shifter as part of the ALU build-up; very code-shaped.
- Chu *FPGA Prototyping by Verilog Examples* — worked Verilog for
  barrel shifter and rotator.
- IEEE 1800-2017 §11.4.10 — SV shift-operator semantics, signed vs
  unsigned operand rules.
- RISC-V ISA Spec, Volume I, RV32I §2.4 — `sll`/`srl`/`sra` semantics
  and the `shamt` masking rule (https://riscv.org/specifications/).

## Cross-links

- `[[adders_carry_chain]]` — same "log-depth combinational"
  structural family.
- `[[multipliers]]` — shift-add multipliers reuse the shifter
  microarchitecture under FSM control.
- `[[signed_arithmetic]]` — when SRL vs SRA actually matters.
- `[[fixed_point_qformat]]` — Q-format scale changes are SRA on
  signed values (W16 portfolio).
