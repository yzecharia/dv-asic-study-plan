# 2-FF Synchroniser

**Category**: CDC · **Used in**: W7, W19 · **Type**: auto-stub

The simplest CDC primitive: cascade two flops in the destination
clock domain. The first flop accepts the asynchronous input (and may
go metastable); the second flop samples the first one cycle later,
giving the metastable settle time of nearly a full clock period.

```systemverilog
always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) {sync_q, sync_meta} <= 2'b00;
    else            {sync_q, sync_meta} <= {sync_meta, async_in};
end
```

## Use ONLY for single-bit signals

A 2-FF on each bit of a multi-bit value will desync the bits — the
receiver may sample inconsistent intermediate values. For multi-bit
crossings use `[[gray_code_pointers]]` (FIFO pointer) or
`[[multibit_handshake_cdc]]` (general).

## Reading

- Cummings *CDC Design & Verification Techniques*, SNUG-2008.

## Cross-links

- `[[setup_hold_metastability]]`
- `[[metastability_mtbf]]`
- `[[multibit_handshake_cdc]]`
