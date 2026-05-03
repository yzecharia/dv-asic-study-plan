# Boolean Algebra

**Category**: Combinational · **Used in**: W3, W4 · **Type**: auto-stub

The algebraic foundation under every combinational circuit you will
draw. You should be fluent enough to manipulate expressions on
paper without referencing the laws each time.

## Key laws

| Law | Statement |
|---|---|
| Identity | `A + 0 = A`, `A · 1 = A` |
| Null | `A + 1 = 1`, `A · 0 = 0` |
| Idempotent | `A + A = A`, `A · A = A` |
| Complement | `A + ¬A = 1`, `A · ¬A = 0` |
| De Morgan | `¬(A · B) = ¬A + ¬B`, `¬(A + B) = ¬A · ¬B` |
| Distributive | `A · (B + C) = A·B + A·C` |
| Absorption | `A + A·B = A`, `A · (A + B) = A` |

## Reading

- Harris & Harris, *Digital Design and Computer Architecture: RISC-V*,
  ch.2 §2.1–2.4, pp. 55–80.

## Example

```systemverilog
// Direct expression
assign y1 = (a & b) | (~a & c);

// After Boolean simplification (no functional difference) —
// shows why hand-simplifying matters less in modern synthesis
assign y2 = (a & b) | (~a & c);  // same; synthesis tool will
                                  // optimise based on technology library
```

## Cross-links

- `[[multiplexers_decoders]]` — every mux is a Boolean expression.
- `[[karnaugh_maps]]` — visual Boolean simplification.
- `[[fsm_encoding_styles]]` — state-encoding Boolean tradeoffs.
