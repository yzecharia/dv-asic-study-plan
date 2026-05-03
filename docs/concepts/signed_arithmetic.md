# Signed Arithmetic

**Category**: Combinational · **Used in**: W4, W8 (`SLT/SLTU`), W16 (anchor), W17 · **Type**: authored

Signed arithmetic is where junior bugs cluster. Two's-complement is
not just "the negative of the positive" — it has asymmetric range
(`-2^(N-1)` to `2^(N-1)-1`), wraparound on overflow, and requires
explicit sign extension before mixing widths.

## Two's complement

For N bits, range is `-2^(N-1)` to `2^(N-1)-1`. Negation: `-x =
~x + 1`. Adding two N-bit signed numbers produces an N-bit result;
overflow is detected by the XOR of the carry into and out of the
sign bit.

```systemverilog
// signed addition with overflow detection
logic signed [7:0] a, b, sum;
logic              ovf;

always_comb begin
    sum = a + b;
    ovf = (a[7] == b[7]) && (sum[7] != a[7]);  // same-sign inputs,
                                                // different-sign result
end
```

## Sign extension

Mixing widths: a signed value zero-extended like an unsigned will
flip sign. SystemVerilog's `signed` keyword is load-bearing: the
synthesis tool propagates the MSB only when the operand is declared
`signed`.

```systemverilog
logic signed [3:0] x;     // -8..+7
logic signed [7:0] y;
assign y = x;             // sign-extends correctly because x is signed

logic        [3:0] u;     // 0..15
logic signed [7:0] z;
assign z = $signed({{4{u[3]}}, u});  // explicit if u was unsigned
```

## SLT vs SLTU (RISC-V)

`SLT` (set less than) treats both operands as signed; `SLTU` treats
both as unsigned. At the bit level, `SLT(a, b) = (a−b)[N−1] XOR
overflow_flag`, while `SLTU` is just `~carry_out` of `(a−b)`. Junior
mistake: implementing `SLT` as `SLTU` and missing negative
comparisons.

## Booth encoding (preview for W16)

Radix-4 Booth halves the number of partial products in a signed
multiplier by encoding the multiplier in groups of 3 bits with a
1-bit overlap. Each group selects from `{0, ±A, ±2A}`. Skip-zero
runs are free. This is the structure used in nearly all modern
ASIC multipliers; the signed version handles the sign without
needing a final correction step the way naive shift-add does.

## Reading

- Dally & Harting ch.10 (numbers, two's complement, sign extension)
  — pp. TBD (verify).
- Harris & Harris RISC-V ch.5 §5.1 — sign-extension hardware in the
  RV32I datapath.
- For Booth: any standard arithmetic textbook; Cummings has no paper
  on this so no SNUG ref.

## Cross-links

- `[[fixed_point_qformat]]` — Q-format extends signed arithmetic with
  an implicit binary point.
- `[[multipliers]]` — Booth encoding is multiplier-internal.
- `[[adders_carry_chain]]` — signed add reuses unsigned hardware
  with the same sum, different overflow rule.
