# Clocking and Reset Strategy

**Category**: Sequential · **Used in**: every week with sequential RTL · **Type**: authored

The two pieces of RTL infrastructure that, if done sloppily, will
silently bite you in synthesis or simulation. Pick a strategy
upfront and document it in `verification_report.md`.

## Reset choices

| Strategy | When | Pros | Cons |
|---|---|---|---|
| **Sync reset** | most ASIC datapaths | timing analysed normally; no async path | needs clock running to reset |
| **Async assert / sync deassert** | most modern ASICs (Xilinx, Intel) | works without clock; clean release | slightly more complex glue |
| **Pure async** | legacy / FPGA fabrics | simplest | recovery/removal timing harder; CDC-fragile |
| **No reset** (initial value) | small FPGA blocks where init is enough | smaller area | not portable to ASIC |

The idiomatic SV for **async assert / sync deassert** with a
synchroniser:

```systemverilog
// reset synchroniser — emits a sync_deassert pulse from async input
module rstn_sync (
    input  logic clk,
    input  logic rst_n_async,    // async assert from outside
    output logic rst_n_sync      // sync release for downstream logic
);
    logic rst_meta;
    always_ff @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async) begin
            rst_meta   <= 1'b0;
            rst_n_sync <= 1'b0;
        end else begin
            rst_meta   <= 1'b1;
            rst_n_sync <= rst_meta;
        end
    end
endmodule : rstn_sync
```

The receiving FFs use the synchronised `rst_n_sync` in their
sensitivity list (or as a sync condition).

## Clocking idioms

### Single-clock RTL

Use `always_ff @(posedge clk)`. Use `always_comb` for combinational.
Never mix in the same `always` block.

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= '0;
    else        q <= d;
end
```

### Multi-clock RTL

Each clock domain gets its own `always_ff` block. Crossing between
domains uses **only** synchronisers, gray-code FIFOs, or handshakes
— never a direct `assign` from one domain's signal to another's
flop. See `[[multibit_handshake_cdc]]`.

### Clocking blocks (verification)

Use `clocking` blocks in interfaces to avoid race conditions between
the testbench and the DUT. The `default input #1step output #1` idiom
samples DUT outputs just before the clock edge and drives DUT inputs
just after.

```systemverilog
interface alu_if(input bit clk);
    logic [7:0] a, b, result;
    logic       op_valid, op_ready;

    clocking cb @(posedge clk);
        default input #1step output #1;
        output a, b, op_valid;
        input  result, op_ready;
    endclocking : cb
endinterface : alu_if
```

## Reading

- Sutherland *SystemVerilog for Design* clocking blocks ch.
- Cummings — async-reset SNUG papers (search cummings.com for "reset").
- Spear *SV for Verification* ch.4 — clocking blocks in TBs.

## Cross-links

- `[[setup_hold_metastability]]`
- `[[two_ff_synchronizer]]`
- `[[interfaces_modports]]` — clocking blocks live in interfaces.
