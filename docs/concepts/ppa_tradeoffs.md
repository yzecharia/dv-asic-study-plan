# PPA — Power, Performance, Area Trade-offs

**Category**: Synthesis · **Used in**: W15, W20 · **Type**: authored

Three knobs, three quantities. Move one and you usually pay
something on the others. Knowing the trade-offs is what separates a
junior who says "make it faster" from one who says "I'll trade 15%
area for the extra 200 MHz."

## The three quantities

| Knob | What it costs you | What you gain |
|---|---|---|
| **Pipeline more deeply** | latency, area, power | higher Fmax (throughput) |
| **Parallelise** (e.g. 4-wide adder tree) | area, power | latency, throughput |
| **Wider data path** | area, power | throughput per cycle |
| **Lower frequency** | latency budget tightens elsewhere | lower power, easier timing |
| **Clock gating** | small area for the gate logic | dynamic power |
| **Operand isolation** (zero unused inputs) | small area | dynamic power |

## Yosys + nextpnr workflow (open-source)

```bash
# Generic synth → see gate count
yosys -p "read_verilog top.sv; synth; stat"

# Target a specific FPGA family for area & Fmax estimates
yosys -p "read_verilog top.sv; synth_ice40; stat; write_json top.json"
nextpnr-ice40 --hx8k --json top.json --pcf top.pcf --freq 100 --report report.json
```

The report gives you LUT count, FF count, and the maximum clock
frequency the place-and-route tool could actually close timing on.

## Worked example — UART core (W15)

Imagine the W15 synth report shows:

| Metric | Baseline | After pipelining baud divider |
|---|---|---|
| LUTs | 142 | 156 (+10%) |
| FFs | 89 | 110 (+24%) |
| Fmax | 180 MHz | 240 MHz (+33%) |

Trade-off: 14 extra LUTs for 60 MHz of Fmax. Worth it on a clocked-
fast SoC; not worth it on a low-power IoT design.

## When to retime

If WNS comes from a long combinational chain (multiplier → adder →
adder), retiming (moving flops across logic) lets the synthesis tool
balance critical paths. Yosys: `yosys -p "synth -retime"`. Vivado:
synthesis directive `RETIMING_FORWARD` / `RETIMING_BACKWARD`.

## Reading

- Cummings SNUG-2012 — synth coding styles for efficient designs.
- Chu *FPGA Prototyping* ch.6 — area estimation for FPGA primitives.
- Yosys manual (`SYNTH_*` commands per family).

## Cross-links

- `[[synthesis_basics]]`
- `[[timing_constraints_sdc]]`
- `[[static_timing_analysis]]`
