# Week 15 (Bonus): Design Closure — Synthesis, PPA, FPGA

## Why This Matters

The 12-week core plan focused on **simulation**. Real chips also
have to synthesize cleanly, hit timing, fit area, and run on FPGA
for prototyping. Interviewers ask about this even for DV roles
("what's your critical path? what would you optimize?").

This is mostly a **tools week** — Yosys, OpenSTA, Vivado / Yosys
+ nextpnr. The textbook anchor is Dally's timing chapters, but
most of the work is hands-on with synthesis flows.

Goals after this week:
1. **Synthesize** your W8/W9 RISC-V CPU with Yosys; read the
   resulting netlist + cell-count report.
2. **PPA**: identify the critical path; reason about area / power
   / performance tradeoffs.
3. **FPGA**: take any earlier design to a real bitstream on a
   Basys3 (or simulate the flow).
4. **Constraints**: understand `create_clock`, `set_input_delay`,
   `set_false_path`, `set_multicycle_path`.

## What to Study

### Reading — Design

- **Dally & Harting ch.15 — Timing Constraints** ⭐ — clock
  period, setup/hold, slack. The textbook anchor for this week.
- **Dally & Harting ch.14 — Sequential Logic**: setup/hold from
  first principles.
- **Dally & Harting ch.5-6 — CMOS / Power** *(optional skim)* —
  dynamic vs static power.
- **Sutherland *RTL Modeling with SystemVerilog* (this is a
  different Sutherland book — *not* *SV for Design*) ch.7-8** —
  combinational + sequential RTL coding rules for synthesis.
  This is the book that replaces the (incorrect) "SV for Design
  ch.13" citation that appeared in earlier drafts of this plan.
  *SV for Design* has only 12 chapters; the synthesis-style guide
  lives in the *RTL Modeling* book.
- **Sutherland *SV for Design* ch.6 — Procedural Blocks**: the
  `always_comb` / `always_ff` / `always_latch` rules every
  synthesizer interprets unambiguously.
- **Sutherland *SV for Design* ch.8 — FSM Modeling**: the
  synthesis-friendly FSM patterns.
- **Cliff Cummings**:
  - *"SystemVerilog Synthesis Coding Styles for Efficient
    Designs"* ⭐ (the canonical paper).
  - *"Coding And Scripting Techniques For FSM Designs With
    Synthesis-Optimized, Glitch-Free Outputs"*.
- **Xilinx UG901**: *Vivado Design Suite User Guide — Synthesis*
  (skim ch.1-3 for the synthesis-flow vocabulary).
- **Yosys manual** — short and free at
  [yosyshq.net/yosys/](https://yosyshq.net/yosys/).

### Reading — Verification

> **No new verification material this week.** Synthesis is a
> design-side topic. Your existing W12/W13 testbenches are how
> you'd verify the synthesized netlist if you wanted to (just
> re-point the TB at the post-synth Verilog).

### Tool Setup

- **Yosys** — `brew install yosys` or build from source.
- **OpenSTA** — open-source static timing analyzer.
- **Yosys + nextpnr** for fully open FPGA flow (optional).
- **Vivado** — already installed if you've used the Basys3 board.

---

## Design Homework

### Drills (per-tool warmups)

- **Drill — `yosys synth` on a small module (Yosys manual)**
  *Folder:* `homework/design/per_chapter/hw_yosys_smoke/`
  Run `yosys -p "read_verilog rv32i_alu.sv; synth -top
  rv32i_alu; stat"`. Capture the cell-count output. Repeat with
  `synth_ice40` to target a real cell library.

- **Drill — `always_ff` vs latch inference (Sutherland ch.6,
  Cummings paper)**
  *Folder:* `homework/design/per_chapter/hw_latch_demo/`
  Write two tiny modules:
  - `always_comb` with all branches assigned (clean
    combinational).
  - `always_comb` with one missing assignment (yosys complains;
    inferred latch).
  Show the yosys output for each.

- **Drill — Constraint-file basics (Dally ch.15)**
  *Folder:* `homework/design/per_chapter/hw_xdc_skeleton/`
  Hand-write a minimal `.xdc` file for a 50 MHz clock and a
  `set_input_delay`/`set_output_delay` pair. Annotate with
  comments for what each line does.

- **Drill — OpenSTA report (Dally ch.15)**
  *Folder:* `homework/design/per_chapter/hw_opensta_smoke/`
  Run OpenSTA on a tiny synthesized netlist (`rv32i_alu` or
  smaller), `report_checks` on a simulated 5 ns clock. Identify
  the WNS in the output.

### Main HWs

#### HW1: Yosys synthesis — single-cycle vs pipelined CPU
*Folder:* `homework/design/connector/hw1_yosys_compare/`

Synthesize both CPUs:

```bash
yosys -p "read_verilog rtl/*.sv; synth -top rv32i_top; stat; \
          write_verilog rv32i_synth.v"
```

Run once for the W8 single-cycle, once for the W9 pipelined.
Capture `stat` cell counts. Deliverable — a markdown table:

| Design        | FFs | LUTs | Cells (total) |
|---------------|-----|------|---------------|
| Single-cycle  |   ? |    ? |             ? |
| Pipelined     |   ? |    ? |             ? |

Plus a short commentary: pipelined should have more FFs (pipeline
registers) but similar combinational LUT count.

#### HW2: Critical-path analysis
*Folder:* `homework/design/connector/hw2_critical_path/`

For the **single-cycle CPU**:
1. **On paper**: starting at the clock edge that latches PC,
   walk through I-Mem → decoder → reg-file read → ALU → branch
   logic → PC mux → PC register input. Estimate per-stage delay
   from typical ASIC cell delays (50-100 ps).
2. **With OpenSTA** on the synthesized netlist:
   ```
   sta
   read_verilog rv32i_synth.v
   read_liberty <some_open.lib>
   create_clock -period 5 [get_ports clk]
   report_checks -path_delay max
   ```
3. Compare hand-calculated path vs STA-reported path. Did you
   pick the right one?

Deliverable: a 1-page write-up with both paths side by side.

#### HW3: FPGA implementation on Basys3
*Folder:* `homework/design/connector/hw3_fpga_basys3/`

Pick one design (W4 ALU, W10 UART, or single-cycle CPU) and bring
it up:
1. Vivado project, design + `.xdc` mapping ports to switches /
   LEDs / buttons.
2. **Synthesize** → **Implement** → **Generate Bitstream**.
3. Read the **Timing Report**; note WNS. If negative, lower the
   clock until it passes.
4. (If you have a Basys3): flash the bitstream and toggle inputs.

Deliverable: the `.xdc`, a screenshot of the timing report,
markdown noting the achieved Fmax.

#### HW4: Constraint cheat-sheet
*Folder:* `cheatsheets/synthesis_constraints.md` (root of repo,
not under homework — this is reference material).

The 8-10 most common `xdc` / `sdc` constraints with one-line
explanations:
- `create_clock -period <ns> [get_ports clk]`
- `set_input_delay  -clock clk <ns> [get_ports {data*}]`
- `set_output_delay -clock clk <ns> [get_ports {result*}]`
- `set_false_path -from [get_clocks clk_a] -to [get_clocks clk_b]`
- `set_multicycle_path -setup 2 -from [get_pins .../pipe1*]`
- `set_clock_groups -asynchronous -group {clk_a} -group {clk_b}`
- `set_max_delay`, `set_min_delay`
- `set_case_analysis` for mode pins

Lives in `cheatsheets/`. You'll want it again for any synthesis
question in interviews.

### Stretch (optional)

- **Stretch — Retiming experiment**
  Take a deliberately unbalanced pipeline (e.g., a multiplier
  with a long combinational stage and a short one). Apply yosys's
  `retime` pass; measure WNS before vs after.

- **Stretch — Power analysis**
  Run Vivado's power estimator on your pipelined CPU. Identify
  dominant power consumer (clock tree? memories? logic?).
  Touches Dally ch.5-6.

---

## Self-Check Questions

1. Difference between **WNS** and **WHS**? Which is harder to fix
   and why?
2. What is `set_false_path` and when do you use it?
3. Difference between **synthesis** and **implementation** in the
   Vivado flow?
4. Why does pipelining typically *not* shrink the critical path
   of a single stage but *does* increase total throughput?
5. What does `(* keep = "true" *)` do and when would you use it?
6. **Dynamic** vs **static (leakage)** power — which dominates at
   advanced nodes (7nm, 5nm)?

---

## Checklist

### Design Track
- [ ] Read Dally ch.14 (sequential logic / setup-hold)
- [ ] Read Dally ch.15 (timing constraints) ⭐
- [ ] *(Optional)* Read Dally ch.5-6 (CMOS / power)
- [ ] Read Sutherland *RTL Modeling* ch.7-8 (combinational +
  sequential synthesis coding)
- [ ] Read Sutherland *SV for Design* ch.6 (procedural blocks)
- [ ] Read Sutherland *SV for Design* ch.8 (FSM modeling)
- [ ] Read Cummings synthesis-coding-styles paper
- [ ] Skim Vivado UG901 ch.1-3
- [ ] Skim Yosys manual
- [ ] Drill: yosys synth on a small module
- [ ] Drill: latch-inference demo
- [ ] Drill: minimal `.xdc`
- [ ] Drill: OpenSTA smoke run
- [ ] HW1: yosys synth — single vs pipelined CPU comparison
- [ ] HW2: critical-path analysis (paper + OpenSTA)
- [ ] HW3: Basys3 implementation (.xdc, timing report, Fmax)
- [ ] HW4: constraint cheat-sheet → `cheatsheets/`
- [ ] *(Optional)* Stretch: retiming or power experiment
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: You can talk about timing, area, and synthesis
  in interviews — even as a verification engineer.**
