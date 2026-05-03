# FPGA Debug — On-Chip Visibility

**Category**: Synthesis · **Used in**: W15 · **Type**: authored

Once your design is on real silicon, `$display` doesn't work. You
need on-chip debug primitives to see what's happening: ILA
(integrated logic analyser), VIO (virtual I/O), JTAG-served signal
captures.

## Debug strategy hierarchy

1. **Simulate first**. 99% of bugs are reproducible in sim.
2. **LEDs and pins**. The cheapest debug — drive a status signal to
   an LED.
3. **Debug UART**. Add a simple TX-only UART instance. Print
   internal state to a host terminal.
4. **ILA / Vivado debug core**. Capture-on-trigger. Slow but powerful.

## Vivado ILA (W15 stretch)

ILA is a configurable logic analyser inserted as IP. You choose
which signals to capture, depth of capture buffer, and trigger
condition. After bitstream load, Vivado's hardware manager streams
captured samples back over JTAG.

Tcl flow:

```tcl
# Mark signals for debug in the synthesis flow
set_property MARK_DEBUG true [get_nets state]
set_property MARK_DEBUG true [get_nets data_valid]

# Vivado then auto-instantiates an ILA core; or instantiate manually
ila_0 u_ila (
    .clk    (clk),
    .probe0 (state),
    .probe1 (data_valid)
);
```

## Common pitfalls

- **Trigger never fires** — your trigger condition references a
  signal that's optimised out. Either add `(* keep = "true" *)` or
  `KEEP_HIERARCHY`.
- **Capture too short** — ILA buffers are LUT-RAM, expensive. 1024
  samples is typical; for slow protocols, drop the sample clock.
- **Debug-vs-non-debug mismatch** — the debug instance changes timing
  / placement. Always re-test the design without the ILA before
  signing off.

## Open-source FPGA debug

For iCE40 / ECP5 with nextpnr there is no equivalent of ILA. The
practical options:

- Drive internal signals to spare pins; capture with an external
  Saleae or sigrok logic analyser.
- Use Glasgow Interface Explorer or Project Lattice's debug tools.
- Embed a tiny RISC-V soft core with a debug ROM that streams
  internal state over a debug UART.

## Reading

- Xilinx UG908 — *Vivado Programming and Debugging*.
- Chu *FPGA Prototyping* — has a chapter on tying internal signals
  to pins for board-level debug.

## Cross-links

- `[[synthesis_basics]]`
- `[[timing_constraints_sdc]]` — debug instances need their own
  constraints.
