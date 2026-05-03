# Asynchronous FIFO

**Category**: FIFO · **Used in**: W6 (theory), W7 (RTL), W19 (multi-ratio) · **Type**: authored

A FIFO with **independent read and write clocks**. The crux of the
design is detecting empty/full when the read and write pointer
counters live in different clock domains — you cannot use a binary
subtract because the pointers are not coherently sampleable across
domains.

## Why gray code

When a binary counter increments, multiple bits can change in the
same cycle (e.g. `0111 → 1000`). If a 2-FF synchroniser samples mid-
transition, the captured value is arbitrary garbage.

A **gray-code counter** has the property that *exactly one bit*
changes per increment. If the receiver samples mid-transition, it
sees either the old value or the new value — never a corrupted
intermediate. Combined with 2-FF synchronisers, this gives you a
multi-bit CDC that is *correct by construction*.

```
Binary    Gray
0000      0000
0001      0001
0010      0011    ← 1-bit change
0011      0010
0100      0110    ← 1-bit change
...
```

## Architecture

- Two counters: `wbin` (binary, in write domain), `rbin` (binary, in
  read domain).
- Two gray versions: `wgray = wbin ^ (wbin >> 1)`, same for read.
- Two synchronisers: `wgray_rsync` (write gray re-sampled in read
  domain), `rgray_wsync` (read gray re-sampled in write domain).
- Empty (read side): `rgray == wgray_rsync`.
- Full (write side): `wgray == ~rgray_wsync[MSB], ~rgray_wsync[MSB-1],
  rgray_wsync[MSB-2:0]` — i.e. the inverted top two bits of the
  re-synced read pointer plus equality on the rest.

## SV skeleton (Cummings-style)

```systemverilog
module async_fifo #(parameter int W = 8, D = 16) (
    input  logic         wr_clk, wr_rst_n,
    input  logic         rd_clk, rd_rst_n,
    input  logic         wr_en, rd_en,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout,
    output logic         empty, full
);
    localparam int AW = $clog2(D);
    logic [W-1:0]   mem [0:D-1];
    logic [AW:0]    wbin, wgray, wbin_n, wgray_n;
    logic [AW:0]    rbin, rgray, rbin_n, rgray_n;
    logic [AW:0]    wgray_rsync_q1, wgray_rsync_q2;
    logic [AW:0]    rgray_wsync_q1, rgray_wsync_q2;

    // Write side
    always_ff @(posedge wr_clk or negedge wr_rst_n)
        if (!wr_rst_n) {wbin, wgray} <= '0;
        else           {wbin, wgray} <= {wbin_n, wgray_n};
    assign wbin_n  = wbin + (wr_en && !full);
    assign wgray_n = wbin_n ^ (wbin_n >> 1);

    // Read side (mirror)
    always_ff @(posedge rd_clk or negedge rd_rst_n)
        if (!rd_rst_n) {rbin, rgray} <= '0;
        else           {rbin, rgray} <= {rbin_n, rgray_n};
    assign rbin_n  = rbin + (rd_en && !empty);
    assign rgray_n = rbin_n ^ (rbin_n >> 1);

    // CDC: 2-FF synchronisers
    always_ff @(posedge rd_clk or negedge rd_rst_n)
        if (!rd_rst_n) {wgray_rsync_q2, wgray_rsync_q1} <= '0;
        else           {wgray_rsync_q2, wgray_rsync_q1} <= {wgray_rsync_q1, wgray};

    always_ff @(posedge wr_clk or negedge wr_rst_n)
        if (!wr_rst_n) {rgray_wsync_q2, rgray_wsync_q1} <= '0;
        else           {rgray_wsync_q2, rgray_wsync_q1} <= {rgray_wsync_q1, rgray};

    assign empty = (rgray == wgray_rsync_q2);
    assign full  = (wgray == {~rgray_wsync_q2[AW:AW-1], rgray_wsync_q2[AW-2:0]});

    // Memory R/W
    always_ff @(posedge wr_clk)
        if (wr_en && !full) mem[wbin[AW-1:0]] <= din;
    assign dout = mem[rbin[AW-1:0]];
endmodule : async_fifo
```

## Verification (W7 + W19 reuse)

- Two independent clock generators in the TB.
- Drive bursty writes and slow reads (and vice versa) — observe
  empty/full edges.
- SVA: `empty |-> !rd_en` (or `rd_en` ignored), `full |-> !wr_en`,
  pointer monotonicity in each domain.
- Coverage: pointer-rollover events, empty/full transitions,
  concurrent rd+wr at occupancy edges.

## Reading

- Cummings *Simulation and Synthesis Techniques for Asynchronous
  FIFO Design*, SNUG-2002 — the canonical paper.
- Cummings *CDC Design & Verification Techniques*, SNUG-2008 — broader
  CDC context.

## Cross-links

- `[[gray_code_pointers]]`
- `[[two_ff_synchronizer]]`
- `[[metastability_mtbf]]`
- `[[multibit_handshake_cdc]]` — alternative for non-FIFO crossings.
