# SVA — SystemVerilog Assertions

**Category**: UVM / Verification · **Used in**: W3 (anchor), W7, W12, W19 · **Type**: authored

Concurrent assertions describe **temporal behaviour over multiple
cycles**. They're the single most effective tool you have for
catching protocol violations — far more than ad-hoc `if/$error`
checks.

## Operators you must know

| Operator | Meaning |
|---|---|
| `\|->` | Overlapping implication — if antecedent matches at cycle N, consequent must hold at cycle N. |
| `\|=>` | Non-overlapping implication — consequent must hold starting cycle N+1. |
| `##N` | Wait exactly N cycles. |
| `##[N:M]` | Wait between N and M cycles. |
| `s_eventually` | Strong: must eventually happen (liveness). |
| `s_always` | Strong: must always hold (safety). |
| `[*N]` | Repetition: N consecutive matches. |

## Sampled value functions

| Function | Use |
|---|---|
| `$rose(x)` | x went 0→1 in the last cycle |
| `$fell(x)` | x went 1→0 in the last cycle |
| `$stable(x)` | x did not change since last cycle |
| `$past(x, N)` | value of x N cycles ago (default N=1) |

## Skeleton

```systemverilog
property p_handshake_valid_until_ready;
    @(posedge clk) disable iff (!rst_n)
        valid && !ready |=> valid;
endproperty
assert property (p_handshake_valid_until_ready);
cover  property (p_handshake_valid_until_ready);
```

The `disable iff (!rst_n)` clause is essential — without it, the
property fires during reset and falsely fails.

## Bind file pattern (Cummings SNUG-2009)

Keep assertions out of the DUT — `bind` them from a separate file.
Three benefits: assertions are netlist-aware (synthesisable RTL stays
clean), assertions can be enabled/disabled by file inclusion, and
binding allows the same DUT to be used with different assertion
suites in different testbenches.

```systemverilog
// dut_assertions.sv
module dut_assertions (clk, rst_n, valid, ready, data);
    input logic clk, rst_n, valid, ready;
    input logic [7:0] data;
    // ... assertions here ...
endmodule

// bind file (in TB)
bind dut dut_assertions u_assertions (.*);
```

## Common patterns

### "X must follow Y within N cycles"

```systemverilog
property p_resp_within_n;
    @(posedge clk) disable iff (!rst_n)
        $rose(req) |-> ##[1:N] $rose(ack);
endproperty
```

### "While X, Y must remain stable"

```systemverilog
property p_data_stable_during_valid;
    @(posedge clk) disable iff (!rst_n)
        valid && !ready |=> $stable(data);
endproperty
```

### "Mutex — never both"

```systemverilog
assert property (@(posedge clk) !(read_en && write_en));
```

## Reading

- Cummings *SVA Design Tricks and Bind Files*, SNUG-2009.
- Spear *SV for Verification* ch.9 (assertions).
- IEEE 1800-2017 §16 (concurrent assertions).

## Cross-links

- `[[coverage_functional_vs_code]]` — `cover property` complements
  `assert property`.
- `[[multibit_handshake_cdc]]` — handshake assertion bundle uses
  these operators.
- `[[ready_valid_handshake]]`
