# Ready/Valid Handshake

**Category**: Protocols · **Used in**: W5, W11 (AXI), W17 (FIR streaming) · **Type**: authored

The fundamental streaming handshake. Producer asserts `valid` when
data is available; consumer asserts `ready` when it can accept.
A transfer happens on the clock edge when **both** are high
simultaneously. This is the building block under AXI-Stream,
AXI-Full handshakes, and most internal pipeline coupling.

## The protocol

```
            ___       ___
clk      __|   |__... |   |...
            
valid    __/¯¯¯¯¯¯¯¯¯¯¯¯¯¯\__
            
ready    __________/¯¯¯¯¯\___
                            
transfer happens here  ↑
```

Three rules to internalise:

1. `valid` may **not** depend on `ready` (no combinational loop).
   Producer cannot say "I'll have data only if you're ready" — that
   creates a chicken-and-egg.
2. Once asserted, `valid` must remain asserted **and the data must
   not change** until the transfer completes (`ready` rises). The
   producer cannot retract.
3. `ready` may freely depend on `valid`. (e.g. a stage may decide
   to absorb only when there's actually a producer.)

## SV idiom

```systemverilog
// Pipeline stage: receives from upstream, emits to downstream
logic        upstream_valid, upstream_ready;
logic [W-1:0] upstream_data;
logic        downstream_valid, downstream_ready;
logic [W-1:0] downstream_data;

logic [W-1:0] stage_data;
logic         stage_full;

assign upstream_ready   = !stage_full || downstream_ready;
assign downstream_valid = stage_full;
assign downstream_data  = stage_data;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) stage_full <= 1'b0;
    else if (upstream_valid && upstream_ready) begin
        stage_data <= upstream_data;
        stage_full <= 1'b1;
    end else if (downstream_valid && downstream_ready) begin
        stage_full <= 1'b0;
    end
end
```

## Skid buffer

The naive pipeline above causes a combinational path from
`downstream_ready` through `upstream_ready`. For long pipelines this
is a timing problem. A **skid buffer** breaks it: holds 2 entries so
upstream can keep pushing while downstream stalls.

## SVA bundle

```systemverilog
// once valid, must stay valid until handshake completes
property p_valid_held;
    @(posedge clk) disable iff (!rst_n)
        ($rose(valid) || (valid && !$past(ready)))
        |-> valid;
endproperty
assert property (p_valid_held);

// data stable while valid held high without ready
property p_data_stable_during_stall;
    @(posedge clk) disable iff (!rst_n)
        (valid && !ready) |-> $stable(data);
endproperty
assert property (p_data_stable_during_stall);
```

## Coverage

- Cross `(valid, ready)` × stall length × consecutive transfers.
- Bins: stall=0 (handshake same cycle), stall=1, stall>1.

## Reading

- ARM AMBA AXI specification (IHI0022E) ch.A — handshake principles
  for AXI4-Stream and full AXI.
- Sutherland *RTL Modeling* sequential design ch. — backpressure
  patterns.

## Cross-links

- `[[axi_lite]]` — AXI-Lite uses this handshake on each channel.
- `[[sync_fifo]]` — the buffer underneath ready/valid pipelines.
