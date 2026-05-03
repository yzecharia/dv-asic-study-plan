# Karnaugh Maps

**Category**: Combinational · **Used in**: W3 · **Type**: auto-stub

Visual technique for minimising Boolean expressions of up to ~4
variables. Beyond 4 variables, hand K-maps lose to algebraic methods
and synthesis tools.

## When to use

- Quick sanity checks on a truth table you wrote.
- Interview whiteboard problems (always 2–4 variables).
- Identifying don't-care optimisations.

## When not to use

- > 4 variables. Use `case` in SV and let synthesis optimise.
- When you have a clean algebraic expression — K-maps add no value.

## Reading

- Harris & Harris ch.2 §2.7, pp. 91–102.

## Example layout (3-variable map)

```
       BC
       00  01  11  10
A  0 [  0   1   1   0 ]
   1 [  0   0   1   1 ]
       ↑
       Cells adjacent if they differ in 1 bit
       (note: 11→10 and 10→00 wrap around)
```

Reading the 1-cells together: `Y = B + AC` (after grouping the
horizontal `1,1` pair on the bottom row and the vertical `1,1` pair
in the BC=11 column).

## Cross-links

- `[[boolean_algebra]]`
- `[[multiplexers_decoders]]`
