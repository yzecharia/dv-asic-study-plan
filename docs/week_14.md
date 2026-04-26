# Week 14 (Bonus): Design Closure — Synthesis, PPA, FPGA Implementation

## Why This Matters
The 12-week core plan focused on **simulation** — but real chips also have to
synthesize cleanly, hit timing, fit in area, and run on FPGA for prototyping.
This bonus week teaches the design-closure side that academic ASIC courses
emphasize and that **interviewers ask about even for DV roles** ("what's your
critical path? what would you optimize?").

Goals after this week:
1. **Synthesize** your week-7/8 RISC-V CPU with an open-source flow (yosys)
   and read the resulting netlist + report.
2. **PPA analysis**: identify the critical path, understand area numbers, and
   reason about tradeoffs.
3. **FPGA implementation**: take any of your previous designs to actual
   bitstream on a Basys3 board (or simulate the flow if you don't have one).
4. **Synthesis constraints**: understand `create_clock`, `set_input_delay`,
   `set_false_path`, `set_multicycle_path`.

## What to Study

### Reading
- **Dally & Harting ch.14-15** (timing analysis, critical paths, retiming)
- **Cliff Cummings papers**:
  - *"SystemVerilog Synthesis Coding Styles for Efficient Designs"* (essential)
  - *"Coding And Scripting Techniques For FSM Designs With Synthesis-Optimized,
    Glitch-Free Outputs"* (worth reading once for design instincts)
- **Xilinx UG901**: *Vivado Design Suite User Guide — Synthesis* (skim ch.1-3
  for the synthesis flow vocabulary)
- **Yosys manual**: short and free at [yosyshq.net/yosys/](https://yosyshq.net/yosys/)

### Videos
- **VLSI System Design YouTube channel** — short clips on synthesis flow
- **Xilinx training**: free Vivado synthesis videos (search "Vivado Synthesis
  101")

### Reference
- **OpenSTA** (static timing analysis, open source)
- **Yosys + nextpnr** for fully open FPGA flow
- The Basys3 board you used in self-learning — Vivado already supports it

---

## Homework

### HW1: Synthesize your RISC-V CPU with yosys
Take your week-7 single-cycle CPU. Synthesize it:

```bash
yosys -p "read_verilog rv32i_top.sv; \
          synth -top rv32i_top; \
          stat; \
          write_verilog rv32i_synth.v"
```

Capture the `stat` output — it gives you cell counts (FFs, LUTs, multipliers,
etc.). This is your **area** number.

Repeat for the **week-8 pipelined** CPU. Compare the cell counts. The
pipelined version should have more FFs (pipeline registers) but possibly
similar LUT count.

**Deliverable**: a small markdown table comparing single-cycle vs pipelined:
- # of FFs
- # of LUTs / cells
- Brief commentary on why each number changed

### HW2: Critical Path Analysis (Pen + Paper + STA)
For your single-cycle CPU, identify the critical path **on paper**:
1. Start from the clock edge that latches the PC.
2. Walk through: I-Mem → decoder → reg-file read → ALU → branch logic →
   PC mux → PC register input.
3. Estimate the delay of each stage from the gate-level netlist (yosys's
   `stat` plus typical ASIC cell delays of 50-100 ps).

Now run **OpenSTA** on the synthesized netlist:
```bash
sta
read_verilog rv32i_synth.v
read_liberty <some_open_lib.lib>
create_clock -period 5 [get_ports clk]
report_checks
```

Compare your hand-calculated critical path against what STA reports. Did you
identify the right path?

### HW3: FPGA Implementation on Basys3
Take any of your designs (week 4 ALU, week 9 UART, or the single-cycle CPU)
and bring it up on a real Basys3 (or simulate the flow if you don't have one):

1. Create a Vivado project, add the design + a constraint file (`.xdc`)
   mapping your ports to actual Basys3 pins (switches, LEDs, buttons).
2. Run **Synthesize** → **Implement** → **Generate Bitstream**.
3. Read the **Timing Report** — note the worst negative slack (WNS).
   If WNS is negative, your design fails timing at the requested clock; lower
   the clock until it passes.
4. (If you have a Basys3) — flash the bitstream and toggle the inputs.

**Deliverable**:
- The `.xdc` constraints file
- Screenshot of the Vivado timing report
- Brief markdown noting the achieved Fmax

### HW4: Synthesis Constraint Cheat-Sheet
Build a small reference document for yourself listing the 8-10 most common
`xdc` / `sdc` constraints with one-line explanations:
- `create_clock -period <ns> [get_ports clk]`
- `set_input_delay -clock clk <ns> [get_ports {data*}]`
- `set_output_delay -clock clk <ns> [get_ports {result*}]`
- `set_false_path -from [get_clocks clk_a] -to [get_clocks clk_b]`
- `set_multicycle_path -setup 2 -from [get_pins .../pipe1*]`
- `set_clock_groups -asynchronous -group {clk_a} -group {clk_b}`
- `set_max_delay`, `set_min_delay`
- `set_case_analysis` for mode pins

This goes in your cheatsheets folder. You'll need it again for any synthesis
question in interviews.

### HW5 (optional): Retiming Experiment
Take an unbalanced pipeline (e.g., a multiplier with a long stage and a short
stage). Apply yosys's `retime` pass and measure the WNS before/after.
Demonstrate that retiming moved registers to balance the stages.

---

## Self-Check Questions
1. What's the difference between **WNS** and **WHS**? Which one is harder to
   fix and why?
2. What is `set_false_path` and when do you use it?
3. What's the difference between **synthesis** and **implementation** in the
   Vivado flow?
4. Why does pipelining typically *not* shrink the critical path of a single
   stage but does increase total throughput?
5. What does `(* keep = "true" *)` do and when would you ever use it?
6. Power: difference between **dynamic** and **static** (leakage) power, and
   which one dominates at advanced nodes (7nm, 5nm)?

---

## Checklist
- [ ] Read Dally ch.14-15
- [ ] Read Cummings synthesis-coding-styles paper
- [ ] Skimmed Vivado UG901 ch.1-3
- [ ] Skimmed yosys manual basics
- [ ] Completed HW1 (yosys synth + cell-count comparison single vs pipelined)
- [ ] Completed HW2 (Critical-path analysis pen + STA)
- [ ] Completed HW3 (Basys3 implementation: .xdc + timing report + Fmax)
- [ ] Completed HW4 (Synthesis-constraint cheat-sheet → `cheatsheets/`)
- [ ] *(Optional)* Completed HW5 (Retiming experiment)
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: You can talk about timing, area, and synthesis in interview
  questions — even as a verification engineer.**
