# Flip-Flops and Latches

**Category**: Sequential · **Used in**: W3 (shift register), W7 (regfile) · **Type**: auto-stub

A latch is level-sensitive (transparent while enable is high). A flip-
flop is edge-sensitive (samples on a clock edge, opaque otherwise).
Synthesised RTL should produce flip-flops; latches arise only from
incomplete `always_comb` blocks and are nearly always bugs.

## SV idioms

```systemverilog
// Edge-triggered flip-flop (good)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= '0;
    else        q <= d;
end

// Combinational with implicit latch (BAD — incomplete)
always_comb begin
    if (enable) y = d;     // y has no else → latch
end

// Combinational without latch (good)
always_comb begin
    y = '0;                // default
    if (enable) y = d;
end
```

## Reading

- Harris & Harris ch.3 §3.2, pp. 121–135.
- Dally & Harting ch.14 (latch/FF distinctions).

## Cross-links

- `[[setup_hold_metastability]]` — timing constraints are about
  flip-flop sampling windows.
- `[[clocking_resets]]` — reset behaviour of FFs.
