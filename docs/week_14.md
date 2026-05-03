# Week 14 (Bonus): Advanced UVM — RAL + Multi-UVC

## Why This Matters

The 12-week core plan gets you a working junior DV foundation.
This bonus week closes two gaps that **academic DV courses cover
explicitly** and **Israeli senior DV teams ask about in
interviews**:

1. **UVM RAL (Register Abstraction Layer)** — model DUT registers
   as a first-class testbench object with auto-generated read/write
   APIs.
2. **Multi-UVC integration** — wire up an env containing agents
   from multiple independent UVCs (e.g., AXI + UART), all driven
   by a coordinated virtual sequence.

After this week you can claim "I have hands-on experience with RAL
and multi-agent UVM environments" — which most junior candidates
can't.

## What to Study

### Reading — Verification

- **Rosenberg & Meade *A Practical Guide to Adopting the UVM*
  (2nd ed)** — the primary source for everything below:
  - **ch.7** ⭐ — Register Abstraction Layer. The most thorough
    textbook treatment available.
  - **ch.5** — sequence layering, sequence libraries.
  - **ch.13** (multi-UVC patterns) — virtual sequencer +
    coordinated stimulus across agents.
- **Verification Academy UVM Cookbook**:
  - **Register Layer** chapter ⭐ — the industry-standard online
    reference.
  - **Multi-Agent Environments** chapter.
- **ChipVerify** — search "UVM RAL" — quick syntax reference for
  `uvm_reg`, `uvm_reg_field`, `uvm_reg_block`.
- **Mentor whitepaper**: *"UVM Register Layer Quick Start"*
  (Google it; free). Concise top-to-bottom example.
- **Sutherland *SV for Design* ch.10 — Interfaces**: refresher,
  because the RAL adapter (`uvm_reg_adapter`) needs to translate
  between `uvm_reg_bus_op` and your bus's transaction shape, which
  in turn rides over your bus interface's modports.

### Tool Setup

- xsim with `-L uvm`.
- Optional: the `tools/ralgen.py` from your `uvm_framework`
  generates a basic RAL model from `regs.json`. HW1 hand-writes
  one anyway, to ensure you understand every line.

---

## Verification Homework

### Drills (per-component RAL warmups)

- **Drill — `uvm_reg_field` mechanics (Rosenberg ch.7)**
  *File:* `homework/verif/per_chapter/hw_ral_reg_field/reg_field.sv`
  Build one `uvm_reg` with three `uvm_reg_field`s of different
  access types (RW, RO, W1C). Drive `reset()`, `set()`, `get()`,
  `predict()` from a small TB; print mirrored vs desired values
  after each. No bus, no DUT — pure object-level RAL.

- **Drill — `uvm_reg_block` minimum (Rosenberg ch.7)**
  *File:* `homework/verif/per_chapter/hw_ral_reg_block/reg_block.sv`
  Two registers (`CTRL`, `STATUS`) in a `uvm_reg_block` with a
  `default_map` (`UVM_LITTLE_ENDIAN`, 4-byte addressing). Verify
  `lock_model()` succeeds and `print()` shows both registers at
  the right offsets.

- **Drill — `uvm_reg_adapter` (Rosenberg ch.7, Sutherland ch.10)**
  *File:* `homework/verif/per_chapter/hw_ral_adapter/reg_adapter.sv`
  Implement `reg2bus()` and `bus2reg()` between
  `uvm_reg_bus_op` and a tiny `apb_transaction` class. Unit test
  it with hand-built `bus_op` structs.

- **Drill — Frontdoor write/read sequence (Rosenberg ch.7)**
  *File:* `homework/verif/per_chapter/hw_ral_seq/ral_seq.sv`
  ```systemverilog
  class ctrl_write_seq extends uvm_sequence #(uvm_reg_item);
      uvm_reg_block model;
      task body();
          uvm_status_e status;
          model.CTRL.write(status, 32'hCAFE_F00D);
          model.CTRL.read (status, val);
          // assert val == 0xCAFE_F00D
      endtask
  endclass
  ```

- **Drill — Virtual sequencer skeleton (Rosenberg ch.5 + ch.13)**
  *File:* `homework/verif/per_chapter/hw_virtual_sqr/virt_sqr.sv`
  ```systemverilog
  class virt_sequencer extends uvm_sequencer;
      `uvm_component_utils(virt_sequencer)
      alu_sequencer  alu_sqr;
      fifo_sequencer fifo_sqr;
      function new(...); ... endfunction
  endclass
  ```
  Plus a virtual sequence whose body forks ALU and FIFO sub-seqs
  in parallel.

### Main HWs

#### HW1: Hand-written UVM RAL block
*Folder:* `homework/verif/connector/hw1_ral_handwritten/`

**No code generation.** Pick a 4-register set (e.g., `CTRL`,
`STATUS`, `INTR_EN`, `INTR_STATUS`) and write the RAL model
entirely by hand. Goal: understand every line.

Required:
- `my_ctrl_reg extends uvm_reg` with R/W fields.
- `my_status_reg extends uvm_reg` (read-only fields).
- `my_intr_en_reg`, `my_intr_status_reg` (W1C on the status).
- `my_reg_block extends uvm_reg_block` containing all four,
  with a `default_map` (`UVM_LITTLE_ENDIAN`, 4 bytes/addr).

Required exercises:
- `reg_block.CTRL.write(status, 32'h0001)`
- `reg_block.STATUS.read(status, val)`
- `reg_block.CTRL.set(0xCAFE); reg_block.CTRL.update(status);`
- `reg_block.CTRL.predict(...)` and `get_mirrored_value()`
- W1C on `INTR_STATUS`.

#### HW2: RAL adapter wired into a real driver
*Folder:* `homework/verif/connector/hw2_ral_adapter_wired/`

Take the AXI-Lite slave from W11 (or the agent in your
`uvm_framework` repo). Build `axi_reg_adapter extends
uvm_reg_adapter`:
- `reg2bus()`: `uvm_reg_bus_op` → `axi_lite_seq_item`.
- `bus2reg()`: reverse.

Wire it up:
```systemverilog
reg_block.default_map.set_sequencer(env.axi_agt.sqr, env.adapter);
reg_block.default_map.set_auto_predict(1);
```

Verify: a sequence that does `reg_block.CTRL.write(...)` produces
real AXI write transactions on the bus that hit the DUT exactly
as if you'd hand-coded them.

#### HW3: Multi-UVC environment
*Folder:* `homework/verif/connector/hw3_multi_uvc/`

Two independent DUTs, two agents, one virtual sequencer.

Pick two of: ALU (W4), UART (W12), FIFO (W13), AXI-Lite (W11).
Recommended pair: **AXI-Lite (with RAL from HW2) + UART**.

```
multi_dut_env
   ├── axi_agent          (drives AXI-Lite slave)
   ├── uart_agent         (drives UART)
   ├── reg_block          (RAL on the AXI side)
   ├── axi_scoreboard
   ├── uart_scoreboard
   └── virtual_sequencer  ← coordinates both
```

Required:
- A `top_multi.sv` instantiating both DUTs and both interfaces.
- `multi_dut_env extends uvm_env` wiring up both agents + RAL.
- `virt_sequencer` with handles to `axi_sqr` and `uart_sqr`.
- A virtual sequence that fork-joins:
  ```systemverilog
  fork
      `uvm_do_on(axi_seq,  p_sequencer.axi_sqr)
      `uvm_do_on(uart_seq, p_sequencer.uart_sqr)
  join
  ```
- A `multi_test` that starts the virtual sequence.

This is the single most CV-impactful demo from the bonus weeks.

#### HW4: Built-in RAL sequences
*Folder:* `homework/verif/connector/hw4_ral_builtin_seqs/`

Run the four standard built-in RAL sequences on the model from
HW1+HW2:
- `uvm_reg_hw_reset_seq` — verifies every register's reset value.
- `uvm_reg_bit_bash_seq` — toggles every bit of every R/W
  register.
- `uvm_reg_access_seq` — exercises each field's R/W policy.
- `uvm_mem_walk_seq` (if you add a `uvm_mem`) — walks every
  memory address.

Each is one line:
```systemverilog
seq = uvm_reg_hw_reset_seq::type_id::create("seq");
seq.model = reg_block;
seq.start(null);
```

These four are 90% of register verification in real chips.

### Stretch (optional)

- **Stretch — RAL backdoor access (Rosenberg ch.7)**
  Add a backdoor `peek`/`poke` path via `uvm_hdl_*` to your
  DUT's register array. Verify a backdoor write is visible on a
  frontdoor read.

- **Stretch — Multi-UVC with shared clock/reset (Rosenberg
  ch.13)**
  Add a shared `clk_rst_agent` and use `uvm_config_db` so all
  agents see the same clock/reset signals.

---

## Self-Check Questions

1. What's the difference between `set/get` (frontdoor) and
   `peek/poke` (backdoor) on a `uvm_reg`?
2. What does `set_auto_predict(1)` do, and when would you turn it
   off?
3. What does `uvm_reg_adapter` exist to convert?
4. In a multi-UVC env, where do shared resources (clock, reset,
   config) live so all agents can access them?
5. What's a virtual sequencer? Why isn't a regular sequencer good
   enough?
6. What's the bit-bash sequence checking for?

---

## Checklist

### Verification Track
- [ ] Read Rosenberg ch.7 (RAL) ⭐
- [ ] Read Rosenberg ch.5 (sequence layering)
- [ ] Read Rosenberg ch.13 (multi-UVC patterns)
- [ ] Read VerificationAcademy "Register Layer" cookbook
- [ ] Read VerificationAcademy "Multi-Agent" cookbook
- [ ] Read Mentor "RAL Quick Start" whitepaper
- [ ] Drill: uvm_reg_field mechanics
- [ ] Drill: uvm_reg_block minimum
- [ ] Drill: uvm_reg_adapter
- [ ] Drill: frontdoor write/read sequence
- [ ] Drill: virtual sequencer skeleton
- [ ] HW1: hand-written RAL block (4 registers)
- [ ] HW2: RAL adapter wired to real bus driver
- [ ] HW3: multi-UVC env with virtual sequencer
- [ ] HW4: 4 built-in RAL sequences clean
- [ ] Can answer all self-check questions
- [ ] **MILESTONE: register + multi-IP UVM — daily bread of
  mid-level DV.**

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_14_advanced_uvm/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 14 — Week 14 (Bonus): Advanced UVM — RAL + Multi-UVC

> **Phase 4 — Portfolio + Advanced** · canonical syllabus: [`docs/week_14.md`](../docs/week_14.md) · ⬜ Not started

The 12-week core plan gets you a working junior DV foundation.
This bonus week closes two gaps that **academic DV courses cover
explicitly** and **Israeli senior DV teams ask about in
interviews**:

## Prerequisites

See [`docs/ROADMAP.md`](../docs/ROADMAP.md) §"Hard prerequisites" for
the dependency list. Refresh the relevant concept notes in
[`docs/concepts/`](../docs/concepts/) before starting.

## Estimated time split (24h total)

```
Reading        6h
Design         8h
Verification   8h
AI + Power     2h
```

(Adjust per week — UVM-heavy weeks shift hours into Verification;
RTL-heavy weeks shift into Design.)

## Portfolio value (what this week proves)

> Fill in 2–3 bullets when you start the week. The rule of thumb:
> what could you put on your CV after this week that you couldn't
> the week before?

## Iron-Rule deliverables

- [ ] **(a)** RTL committed and lint-clean.
- [ ] **(b)** Gold-TB PASS log captured to `sim/<topic>_pass.log`.
- [ ] **(c)** `verification_report.md` written.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_14.md`](../docs/week_14.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 14 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_14.md`](../docs/week_14.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 5 — Waveform / debug summary (RAL backdoor vs frontdoor access)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

Mock interview #1 — UVM focus (40 min self-mock)

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 14 — Homework

The canonical homework list lives at
[`docs/week_14.md`](../docs/week_14.md). When you start
the week, port the **Drills**, **Main HWs**, and **Stretch** sections
here — but with explicit file paths, acceptance criteria, and run
commands using the `homework/` folder structure that already exists
in this repo.

## Per-chapter drills (TODO)

> Table: chapter → file path → 3-line spec → acceptance criteria.

## Connector exercise (TODO)

> Tie design + verif. Same DUT, both sides.

## Big-picture exercise (TODO)

> Mini-project within this week's scope only.

## Self-check questions (TODO)

> 5–8 questions answerable without looking. Answer keys at the
> bottom of this file once written.

## Run commands

```bash
cd week_14_*

# Native arm64 sim (Phase 1/2 default)
verilator --lint-only -Wall <rtl_file>.sv
iverilog -g2012 -o /tmp/sim <tb_file>.sv && vvp /tmp/sim

# UVM (Phase 3, when needed)
bash ../run_xsim.sh -L uvm <files>

# Yosys schematic
bash ../run_yosys_rtl.sh <rtl_file>.sv
```

> ℹ️ Auto-generated stub. Replace with concrete homework content
> when you start the week.


---

### `checklist.md`

# Week 14 — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_14.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_14.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 5 — Waveform / debug summary (RAL backdoor vs frontdoor access)
- [ ] **Power-skill task** — Mock interview #1 — UVM focus (40 min self-mock)
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.


---

### `notes.md`

# Week 14 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

