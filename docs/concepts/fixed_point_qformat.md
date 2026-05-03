# Fixed-Point and Q-Format

**Category**: Combinational · **Used in**: W16 (anchor), W17 (FIR coefs), W18 (image conv) · **Type**: authored

Fixed-point arithmetic represents fractional numbers using integer
hardware by interpreting an implicit binary point. **Qm.n** notation
means *m* integer bits + *n* fraction bits (some authors include the
sign bit in *m*; Texas Instruments convention does not — be explicit
which you use).

## Q4.12 example

A 16-bit signed Q4.12 number has range `-8.0` to `+7.999755859375`,
with a precision of `2^-12 ≈ 0.000244`. The integer encoding `1024`
represents the real number `1024 / 4096 = 0.25`.

```systemverilog
// Q4.12: 4 int bits + 12 fraction bits, signed
typedef logic signed [15:0] q4_12_t;

function automatic q4_12_t to_q4_12(input real x);
    return q4_12_t'($rtoi(x * 4096.0));
endfunction

q4_12_t one_quarter = to_q4_12(0.25);  // = 16'h0400 = 1024
```

## Multiplication

Q4.12 × Q4.12 = Q8.24 (32 bits, signed). To return to Q4.12 you must:

1. Right-shift by 12 (drop the extra fraction bits).
2. **Round** (truncate / round-half-up / convergent — pick one).
3. **Saturate** if the result exceeds Q4.12 range (`±8.0`).

```systemverilog
logic signed [31:0] prod;
logic signed [15:0] result;

assign prod = a * b;            // Q8.24

// truncate (worst rounding behaviour, biased toward -∞)
assign result = prod[27:12];

// round-half-up (add 0.5 LSB before truncating)
logic signed [31:0] rounded;
assign rounded = prod + 32'sd2048;     // 2048 = 0.5 in Q24
assign result  = rounded[27:12];
```

## Saturation

```systemverilog
// after computing wide_sum, saturate to Q4.12 range
localparam logic signed [15:0] Q412_MAX = 16'h7FFF;
localparam logic signed [15:0] Q412_MIN = 16'h8000;

always_comb begin
    if (wide_sum > Q412_MAX) clamped = Q412_MAX;
    else if (wide_sum < Q412_MIN) clamped = Q412_MIN;
    else clamped = wide_sum[15:0];
end
```

## Coverage strategy (W16)

When verifying the MAC you need to cover:

- Sign of A × sign of B (4 combinations).
- Saturation events (high pos, high neg).
- Rounding mode boundaries (input lands exactly on `0.5 LSB`).
- Accumulator overflow detection.

These are crossed in the W16 functional coverage model.

## Reading

- Dally & Harting ch.10 (number systems) — pp. TBD.
- Sutherland *RTL Modeling* arithmetic operators ch.
- Online: Texas Instruments TMS320C6000 Q-format application note
  (search "Q-format TI") for the canonical reference.

## Cross-links

- `[[signed_arithmetic]]` — Q-format builds on two's-complement.
- `[[multipliers]]` — every Q-format multiply is a wide multiply
  followed by shift+round+saturate.
- `[[fir_filters]]` — every FIR tap is a Q-format multiply-add.
