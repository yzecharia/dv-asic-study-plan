# Adders and Carry Chains

**Category**: Combinational · **Used in**: W4 (Dally ch.10), W8 (RV32I ALU), W16 (Q-format MAC) · **Type**: auto-stub

The carry chain is the latency-defining path in most adder
microarchitectures. Pick the right structure for the right
size/Fmax.

## Structures

| Structure | Latency | Area | When to use |
|---|---|---|---|
| Ripple-carry | O(N) | smallest | small N (≤8), low Fmax |
| Carry-lookahead (CLA) | O(log N) | larger | medium N (8–32), Fmax-limited |
| Carry-select | O(√N) | duplicate logic | medium N, throughput-friendly |
| Carry-save | O(1) per stage, defers final propagation | smallest deferred area | inside multipliers |

## Reading

- Dally & Harting ch.10 (numbers + ripple/CLA), pp. TBD (verify
  before assigning W4 HW).
- Sutherland *RTL Modeling with SystemVerilog* arithmetic operators
  ch.

## Example — ripple-carry

```systemverilog
module ripple_adder #(parameter int W = 4) (
    input  logic [W-1:0] a, b,
    input  logic         cin,
    output logic [W-1:0] sum,
    output logic         cout
);
    logic [W:0] carry;
    assign carry[0] = cin;
    genvar i;
    for (i = 0; i < W; i++) begin : g_fa
        assign sum[i]     = a[i] ^ b[i] ^ carry[i];
        assign carry[i+1] = (a[i] & b[i]) | (carry[i] & (a[i] ^ b[i]));
    end
    assign cout = carry[W];
endmodule : ripple_adder
```

## Cross-links

- `[[carry_lookahead_adder]]` — deep dive on CLA hierarchy, BG/BP
  block descriptors, and the cla4/lcu4/cla16 architecture.
- `[[multipliers]]` — carry-save structures inside Wallace/Dadda
  trees.
- `[[signed_arithmetic]]` — sign-extend before adding signed numbers.
