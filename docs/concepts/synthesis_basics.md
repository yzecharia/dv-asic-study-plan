# Synthesis Basics

**Category**: Synthesis · **Used in**: W15, W20 · **Type**: authored

Synthesis is the translation from RTL to a gate-level netlist
mapped to a target technology library. The synthesis tool optimises
for area, timing, and power within the constraints you give it.
What you write in `always_ff` becomes flip-flops; what you write in
`always_comb` becomes combinational gates. Anything ambiguous —
incomplete `case`, missing `else` in a comb block, asynchronous
loops — produces *latches* or *unsynthesisable warnings* that you
should treat as errors.

## What synthesises and what doesn't

| Construct | Synthesisable? | Notes |
|---|---|---|
| `always_ff @(posedge clk)` | ✅ | flip-flop |
| `always_comb` (complete) | ✅ | combinational |
| `always_comb` (incomplete assignment) | ✅ as a **latch** (likely a bug) | always investigate |
| `always_latch` | ✅ | rare; explicit latch |
| `case` (full coverage) | ✅ | combinational |
| `case` (missing default) | ✅ as latch | add default |
| `for` with bounded range | ✅ | unrolls |
| `while`/`forever` | ❌ | testbench-only |
| `initial` | ❌ | testbench-only |
| `$display`, `$finish`, `$random` | ❌ | testbench-only |
| `assert property` | ⚠️ | synthesisable in formal flows; ignored in standard synth |

## Open-source flow on arm64

```bash
# Synthesise to generic gates and report area
yosys -p "read_verilog top.sv; synth; stat" -p "write_json top.json"

# Visualize the gate-level RTL
bash run_yosys_rtl.sh top.sv

# Place-and-route on a small FPGA (iCE40 / ECP5)
nextpnr-ice40 --hx8k --json top.json --pcf top.pcf --asc top.asc
icepack top.asc top.bin
```

For larger / Vivado-only flows, use Docker'd Vivado in the W15 HW.

## Coding rules that pay off

- Always assign every output in `always_comb` (default first, then
  override).
- Never read a `logic` without writing it from a single `always`
  block.
- Prefer `case` over priority-encoded `if-else if-else` for many-way
  selects.
- Use `unique case` / `unique0 case` to let the synthesis tool
  optimise to parallel logic instead of priority logic — but only
  when the cases are genuinely mutually exclusive (else simulation
  fails).
- Keep clocks unmolested — never gate by `&'ing` a logic signal with
  the clock; use clock-enable inputs to flops instead.

## Reading

- Cummings *SystemVerilog Synthesis Coding Styles for Efficient
  Designs*, SNUG-2012.
- Sutherland *RTL Modeling with SystemVerilog* — the entire book is
  about writing synthesisable RTL.
- Yosys manual, [yosyshq.net/yosys/documentation.html](https://yosyshq.net/yosys/documentation.html).

## Cross-links

- `[[ppa_tradeoffs]]`
- `[[timing_constraints_sdc]]`
- `[[fpga_debug]]`
