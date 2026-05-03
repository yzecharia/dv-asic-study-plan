# Multipliers

**Category**: Combinational · **Used in**: W4 (shift-add), W16 (signed/Booth), W17 (FIR taps) · **Type**: auto-stub

Multipliers are the bottleneck in any DSP datapath. The textbook
structures (shift-add, Booth, Wallace tree) trade area for latency in
predictable ways.

## Structures

| Structure | Latency | Area | Notes |
|---|---|---|---|
| Shift-add (sequential) | O(N) cycles | tiny | useful only for small embedded systems |
| Combinational array | O(N) gates | O(N²) | the default for FPGA DSP slices |
| Wallace tree | O(log N) | O(N²) gates, denser routing | ASIC, Fmax-critical |
| Booth (radix-4) | half the partial products | encoder logic | signed; standard in modern ASICs |

## Reading

- Dally & Harting ch.11 (multipliers), pp. TBD (verify).
- Sutherland *RTL Modeling* operators ch. — `*` synthesis defaults.

## Example — combinational with `*` operator

```systemverilog
// Synthesis tool picks Wallace/array depending on target
module mul_signed #(parameter int W = 16) (
    input  logic signed [W-1:0]   a, b,
    output logic signed [2*W-1:0] p
);
    assign p = a * b;
endmodule : mul_signed
```

For Q1.15 × Q1.15 = Q2.30 — drop the redundant top sign bit and
truncate/round the bottom 15 bits to get Q1.15 again. See
`[[fixed_point_qformat]]`.

## Cross-links

- `[[adders_carry_chain]]` — multipliers reduce to a partial-product
  add tree.
- `[[signed_arithmetic]]` — sign extension and Booth encoding.
- `[[fir_filters]]` — every tap is a multiply.
