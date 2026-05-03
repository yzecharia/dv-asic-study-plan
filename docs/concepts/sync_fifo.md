# Synchronous FIFO

**Category**: FIFO · **Used in**: W2 (anchor RTL), W7, W12 portfolio (FIFO-UVM), W18 (line buffers) · **Type**: authored

A FIFO with a **single clock** for both read and write ports. Used
for buffering between rate-mismatched producer/consumer in the same
clock domain. Should be the first sequential block you can build
from memory before tackling async FIFO.

## Architecture

- Memory array of size `DEPTH × WIDTH`.
- **Write pointer** `wptr` (incremented on `wr_en`).
- **Read pointer** `rptr` (incremented on `rd_en`).
- **Count** to detect empty (`count == 0`) and full (`count == DEPTH`).

A common trick: use a `DEPTH+1`-bit counter and compare MSBs +
remaining bits to detect full vs empty without a separate counter
register. Chu ch.6 shows this; it saves area on small FIFOs.

## SV skeleton

```systemverilog
module sync_fifo #(
    parameter int W = 8,
    parameter int D = 16
) (
    input  logic         clk, rst_n,
    input  logic         wr_en, rd_en,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout,
    output logic         empty, full
);
    localparam int AW = $clog2(D);
    logic [W-1:0]       mem [0:D-1];
    logic [AW:0]        wptr, rptr;       // 1 extra bit for full vs empty

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= '0; rptr <= '0;
        end else begin
            if (wr_en && !full)  begin mem[wptr[AW-1:0]] <= din; wptr <= wptr + 1; end
            if (rd_en && !empty) rptr <= rptr + 1;
        end
    end

    assign dout  = mem[rptr[AW-1:0]];
    assign empty = (wptr == rptr);
    assign full  = (wptr[AW] != rptr[AW]) && (wptr[AW-1:0] == rptr[AW-1:0]);
endmodule : sync_fifo
```

## SVA bundle (W12 reuse)

```systemverilog
// no write when full
property p_no_write_when_full;
    @(posedge clk) disable iff (!rst_n)
        full |-> !wr_en;
endproperty
assert property (p_no_write_when_full);

// pointer monotonic: wptr never decreases (mod 2^(AW+1))
property p_wptr_monotonic;
    @(posedge clk) disable iff (!rst_n)
        $stable(wptr) || (wptr == $past(wptr) + 1);
endproperty
assert property (p_wptr_monotonic);
```

## Coverage strategy

- Cross `(empty, full, wr_en, rd_en)`.
- Occupancy bins: `[0]`, `[1:DEPTH-2]`, `[DEPTH-1:DEPTH]`.
- Concurrent read+write at every occupancy.

## Reading

- Chu *FPGA Prototyping* ch.6 (FIFO design).
- Cummings *Async FIFO* SNUG-2002 — the *async* paper but its sync-
  background section is the cleanest concise treatment of basic FIFO
  pointer logic.

## Cross-links

- `[[async_fifo]]` — same idea + gray-code pointers + 2-FF
  synchronisers.
- `[[memory_models]]`
- `[[ready_valid_handshake]]` — ready/valid is the streaming view of
  a FIFO interface.
