# Multi-Bit CDC — Handshake

**Category**: CDC · **Used in**: W19 (anchor) · **Type**: authored

When a multi-bit value needs to cross a clock boundary and the
sender's update rate is *not* +1-per-cycle (so gray code doesn't
apply), use a **request/acknowledge handshake** with single-bit
synchronisers and a held data bus.

## 4-phase handshake (the workhorse)

Sender (in clock domain A):
1. Place data on `data_a` bus.
2. Pulse `req_a` (assert and hold).
3. Wait for `ack_a` (synchronised back from B).
4. De-assert `req_a`.
5. Wait for `ack_a` to de-assert.

Receiver (in clock domain B):
1. Wait for `req_b` (synchronised from A).
2. Sample `data_a` — guaranteed stable because sender holds it until
   step 4.
3. Process / latch.
4. Pulse `ack_b` (assert).
5. Wait for `req_b` to de-assert.
6. De-assert `ack_b`.

The data bus is **not synchronised** — it's stable for many clocks
of B before the receiver looks at it, so any metastability has
fully resolved. Only the 1-bit `req` and `ack` go through 2-FF
synchronisers.

## SV skeleton

```systemverilog
// Sender (domain A)
always_ff @(posedge clk_a or negedge rst_n_a) begin
    if (!rst_n_a) begin req_a <= 1'b0; data_a_q <= '0; end
    else begin
        case (state_a)
            S_IDLE  : if (start) begin data_a_q <= data_in; req_a <= 1'b1; state_a <= S_WAIT_ACK; end
            S_WAIT_ACK: if (ack_a_sync) begin req_a <= 1'b0; state_a <= S_WAIT_DEACK; end
            S_WAIT_DEACK: if (!ack_a_sync) state_a <= S_IDLE;
        endcase
    end
end

// 2-FF: req from A→B
always_ff @(posedge clk_b or negedge rst_n_b)
    if (!rst_n_b) {req_b_sync, req_b_meta} <= 2'b00;
    else          {req_b_sync, req_b_meta} <= {req_b_meta, req_a};

// Receiver (domain B): mirrors sender — sample data_a_q, pulse ack_b
// 2-FF: ack from B→A (similar block)
```

## Throughput trade-off

- 4-phase: simple but 4 cycles of B per transfer (plus 2-FF
  synchroniser latencies). Throughput ≈ `1 / (4 × T_clk_B + 4 × T_sync)`.
- 2-phase (toggle): higher throughput but trickier — uses an XOR of
  the toggled signals to detect events. Cummings has a chapter on
  this.
- Async FIFO: highest throughput multi-bit CDC; use when you need
  burst tolerance.

## Pulse synchroniser

Special case of the handshake when you only need to send a 1-cycle
*event* (not a value). Toggle a level on the source side, sample
through 2-FF on the destination, edge-detect.

```systemverilog
// Source (domain A)
always_ff @(posedge clk_a) if (event_a) toggle_a <= ~toggle_a;

// 2-FF in domain B
always_ff @(posedge clk_b) {toggle_b_q, toggle_b_meta} <= {toggle_b_meta, toggle_a};

// Edge detect in B
assign event_b = toggle_b_q ^ toggle_b_q_d1;
```

This is the W7 pulse synchroniser exercise.

## SVA bundle

```systemverilog
// req/ack ordering: req must precede ack
property p_req_before_ack;
    @(posedge clk_b) $rose(ack_b) |-> $past(req_b_sync,1);
endproperty
assert property (p_req_before_ack);
```

## Reading

- Cummings *CDC Design & Verification Techniques*, SNUG-2008 —
  multi-bit handshake section.
- Cummings SVA paper SNUG-2009 — assertion patterns for handshakes.

## Cross-links

- `[[two_ff_synchronizer]]` — the building block.
- `[[async_fifo]]` — alternative for streaming multi-bit CDC.
- `[[metastability_mtbf]]`
