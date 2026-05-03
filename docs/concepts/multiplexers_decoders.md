# Multiplexers and Decoders

**Category**: Combinational · **Used in**: W3, W4, W8 (CPU control) · **Type**: auto-stub

Multiplexers select; decoders activate. They appear everywhere — at
register file read ports, in instruction decode, inside ALUs, in the
control unit of any CPU.

## Mux

A 2-to-1 mux is `Y = sel ? B : A` — one bit of decision. An
`N`-to-1 mux is `log2(N)` select bits and `N` data inputs.

```systemverilog
// 4-to-1 mux
always_comb begin
    case (sel)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        2'b11: y = d;
    endcase
end
```

## Decoder

An `N`-to-`2^N` decoder activates exactly one of `2^N` output lines
based on an N-bit input. Use one-hot decoders for FSM state outputs
(see `[[fsm_encoding_styles]]`).

## Reading

- Harris & Harris ch.2 §2.8, pp. 102–110.
- Dally & Harting ch.10 (decoders within adders).

## Cross-links

- `[[boolean_algebra]]`
- `[[fsm_encoding_styles]]` — one-hot encoding ≈ decoder of state.
- `[[adders_carry_chain]]` — adders use mux+decoder internally.
