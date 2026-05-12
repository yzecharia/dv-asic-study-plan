# Week 5: UVM Communication — Analysis Ports, TLM, Reporting

## Why This Matters

In W4 you built the static UVM hierarchy (test → env → components,
each grabbing the BFM directly). This week you make components **talk
to each other** through UVM communication primitives:

- **Analysis ports** (Salemi ch.15-16) — the Observer pattern: a
  monitor broadcasts to N subscribers (scoreboard, coverage, …).
- **Put / Get ports + TLM FIFOs** (Salemi ch.17-18) — interthread
  communication; how a tester hands data to a driver across threads.
- **UVM reporting** (Salemi ch.19) — `\`uvm_info` etc. and the
  verbosity ceiling.

The take-away: by the end of W5 the only things still using the BFM
directly are the BFM-side monitor `always` blocks. Everything else
flows through UVM ports.

## What to Study (Salemi ch.15-19)

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.15 Talking to Multiple Objects** ⭐ — introduces
    `uvm_analysis_port` + `uvm_subscriber` via a *dice-roller*
    example. The subscriber gives you a built-in `analysis_export`
    and a `write()` method you must implement. (Note: Salemi uses
    `uvm_subscriber`, **not** the lower-level `uvm_analysis_imp` you
    might have heard of — both work, but the book sticks with the
    subscriber.)
  - **ch.16 Using Analysis Ports in a Testbench** — applies the
    pattern to TinyALU. Two BFM-side monitors (`command_monitor`,
    `result_monitor`) write to analysis ports; coverage and
    scoreboard subscribe. The scoreboard subscribes to *two* ports —
    Salemi solves that with `uvm_tlm_analysis_fifo`.
  - **ch.17 Interthread Communication** ⭐ — the producer/consumer
    pattern with `uvm_put_port`, `uvm_get_port`, and `uvm_tlm_fifo`
    (which holds **one** element). Blocking (`put()` / `get()`)
    blocks; non-blocking is `try_put()` / `try_get()`.
  - **ch.18 Put and Get Ports in Action** — *applies* ch.17 to
    TinyALU by splitting the tester into a `tester` (chooses ops) +
    `driver` (drives BFM) connected through a `uvm_tlm_fifo`. No
    new classes, just an architectural use of ch.17 ports.
  - **ch.19 UVM Reporting** ⭐ — the four macros (`\`uvm_info`,
    `\`uvm_warning`, `\`uvm_error`, `\`uvm_fatal`), six verbosity
    levels (`UVM_NONE` → `UVM_DEBUG`), the `+UVM_VERBOSITY` plusarg,
    and `set_report_verbosity_level_hier()` /
    `set_report_severity_action_hier()`.
- **Verification Academy**: UVM Cookbook → "Analysis Components" +
  "Reporting" sections
- **ChipVerify**: [uvm-tlm](https://www.chipverify.com/uvm/uvm-tlm),
  [uvm-analysis-port](https://www.chipverify.com/uvm/uvm-analysis-port),
  [uvm-config-db](https://www.chipverify.com/uvm/uvm-config-db)

### Reading — Design

- **Dally & Harting ch.16 — Datapath Sequential Logic**: registers,
  pipelines, datapath control
- **Dally & Harting ch.24 — Interconnect**: this is where valid/ready
  handshakes belong (you previewed them in W3 from external sources;
  now they have a textbook home)
- **Sutherland *SV for Design* ch.5 — Arrays, Structures, Unions**:
  packed/unpacked structs, packed/unpacked arrays, unions,
  `foreach`, array query functions, `$bits`.
- **Cliff Cummings** *"Asynchronous FIFO Design"* — read for theory
  this week; you build it in W7

### Tool Setup

- xsim with `-L uvm` (same as W4)
- For verbosity demos: `+UVM_VERBOSITY=UVM_HIGH` on the command line

---

## Verification Homework

### Drills (per-chapter warmups)

> One per chapter, ~20-40 lines each. Code to feel each primitive.

- **Drill ch.15 — Dice-roller analysis port** ⭐
  *File:* `homework/verif/per_chapter/hw_ch15_analysis_ports/dice_roller.sv`
  Recreate Salemi's exact example. A `dice_roller` `uvm_component`
  with a `uvm_analysis_port #(int) roll_ap` rolls 2d6 20 times and
  calls `roll_ap.write(sum)`. Three `uvm_subscriber #(int)`s
  (`average`, `histogram`, `coverage`) connect via
  `roll_ap.connect(sub.analysis_export)` in `connect_phase` and each
  prints its summary in `report_phase`.

- **Drill ch.16 — Analysis port in a TB**
  *Folder:* `homework/verif/per_chapter/hw_ch16_analysis_ports/` (split into `analysis_pkg.svh`, `producer.svh`, `printer_a.svh`, `printer_b.svh`, `analysis_test.svh`, `top.sv`)
  Build a tiny `producer` `uvm_component` that fires 5 `command_s`
  structs through an `analysis_port`, and two
  `uvm_subscriber #(command_s)`s that just print what they receive.
  This is the structural pattern ch.16 uses on TinyALU before you
  apply it to your ALU.

- **Drill ch.17 — Producer/consumer with put/get + tlm_fifo**
  *File:* `homework/verif/per_chapter/hw_ch17_put_get_fifo/prod_cons.sv`
  Producer with `uvm_put_port #(int)`, consumer with
  `uvm_get_port #(int)`, connected via `uvm_tlm_fifo #(int)` in the
  test's `connect_phase` (`fifo.put_export` to producer port,
  `fifo.get_export` to consumer port). Send 5 ints. Then add a
  variant where the consumer uses `try_get()` on a clock edge — copy
  Salemi's 14ns / 17ns example.

- **Drill ch.18 — Tester/driver split via FIFO**
  *File:* `homework/verif/per_chapter/hw_ch18_tester_driver_split/split_demo.sv`
  Take your W4 HW2 tester. Split it into `tester` (puts a
  `command_s` into a `uvm_put_port`) and `driver` (gets it from a
  `uvm_get_port` and calls `bfm.send_op`). Wire them in env via
  `uvm_tlm_fifo`. Same stimulus, new architecture.

- **Drill ch.19 — Reporting macros + verbosity**
  *File:* `homework/verif/per_chapter/hw_ch19_reporting/report_demo.sv`
  In one `uvm_test::run_phase`, fire `\`uvm_info("ID", "lo", UVM_LOW)`,
  `\`uvm_info("ID", "med", UVM_MEDIUM)`, `\`uvm_info("ID", "hi",
  UVM_HIGH)`, plus one each of `\`uvm_warning`, `\`uvm_error`,
  `\`uvm_fatal` (comment out fatal except when demonstrating).
  Run with no plusarg, then with `+UVM_VERBOSITY=UVM_HIGH`. Bonus:
  in `end_of_elaboration_phase`, call
  `set_report_verbosity_level_hier(UVM_HIGH)` on a sub-tree and
  `set_report_severity_action_hier(UVM_ERROR, UVM_NO_ACTION)` to
  silence errors in one component (Salemi ch.19 examples).

### Main HWs

#### HW1: Add the analysis path to the W4 ALU TB
*Folder:* `homework/verif/connector/hw1_alu_analysis_path/`

Take your W4 HW2 testbench. The scoreboard and coverage currently
peek at the BFM directly; replace that with the proper ch.16 pattern:

- Two new BFM-side monitors: `command_monitor` (samples
  `valid_in`+operands+op on the rising edge) and `result_monitor`
  (samples `valid_out`+result). Each has a
  `uvm_analysis_port #(...)` and an `always` block in the BFM that
  calls `write_to_monitor(...)` whenever a transaction happens.
- `coverage` becomes `uvm_subscriber #(command_s)` — its `write(t)`
  samples the covergroup.
- `scoreboard` subscribes to **two** analysis ports: result through
  its own `analysis_export` (extends `uvm_subscriber #(result_t)`)
  and command via a `uvm_tlm_analysis_fifo #(command_s)` whose
  `analysis_export` is connected to the command monitor. The
  scoreboard's `write()` (called on results) does
  `cmd_f.try_get(cmd)` to grab the matching command.
- Wire it all in `env::connect_phase`.

This is the exact pattern Salemi shows in ch.16.

#### HW2: Tester/driver split on the ALU TB
*Folder:* `homework/verif/connector/hw2_tester_driver_split/`

Apply ch.18 to your TB. Replace the in-tester `bfm.send_op(...)`
with:
- `tester` puts a `command_s` into a `uvm_put_port`
- `driver` gets from a `uvm_get_port`, calls `bfm.send_op`
- env declares `uvm_tlm_fifo #(command_s) cmd_f` and connects
  `tester.put_port` ↔ `cmd_f.put_export`,
  `driver.get_port` ↔ `cmd_f.get_export`.

Run all the W4 tests against this new architecture; behavior should
be identical, structure cleaner.

#### HW3: Polish reporting throughout
*Folder:* `homework/verif/connector/hw3_reporting_polish/`

Sweep through the TB and replace every `$display` with the
appropriate `\`uvm_info` / `\`uvm_warning` / `\`uvm_error`. Use
`UVM_LOW` for headlines, `UVM_HIGH` for chatty per-transaction
debug. Verify behavior under `+UVM_VERBOSITY=UVM_HIGH` and
`UVM_LOW`.

### Stretch (optional)

- **Stretch — config_db-driven test selection**
  *Folder:* `homework/verif/big_picture/config_db_test/`
  Use `uvm_config_db #(int)::set` from the test to pass
  `num_transactions` to the tester. Run two tests with different
  values without recompiling. Salemi ch.22 explores this more
  fully — this is a preview.

---

## Design Homework

### Drills (per-chapter warmups)

- **Drill Dally ch.16 — Datapath shift register**
  *Folder:* `homework/design/per_chapter/hw_dally_ch16_shift_register/`
  Parameterized shift register with serial-in/serial-out and
  parallel-load.

- **Drill Dally ch.24 — Valid/ready handshake**
  *Folder:* `homework/design/per_chapter/hw_dally_ch24_handshake/`
  Producer/consumer pair with valid/ready. Test back-pressure: drop
  `ready` mid-stream. (You've seen this in W3 from external sources;
  Dally ch.24 is its proper textbook home.)

- **Drill Sutherland ch.5 — Packed struct port**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch5_structs/`
  Build a small RTL block whose port is a packed `struct`. Bundle
  5+ signals cleanly.

### Main HWs

#### HW1: True dual-port RAM
*Folder:* `homework/design/connector/hw1_dual_port_ram/`

Parameterized DPRAM (port A + port B, each can read & write
independently). Combines sequential logic + handshake + struct
port. Document the read-during-write behavior choice
(write-first / read-first / undefined) — this is a real RTL
design decision.

#### HW2: Round-robin arbiter
*Folder:* `homework/design/connector/hw2_round_robin_arbiter/`

4-input round-robin arbiter with rotating priority mask. Builds on
the W3 fixed-priority arbiter. Test fairness: under sustained
contention, every input gets granted in a bounded number of cycles.

---

## Self-Check Questions

1. What's the difference between `uvm_analysis_port` and
   `uvm_put_port`? When do you use which?
2. How does a `uvm_subscriber` differ from a plain `uvm_component`?
3. What is `uvm_tlm_analysis_fifo` and why does Salemi reach for it
   in the scoreboard?
4. Blocking vs non-blocking: when must you use `try_get()` instead of
   `get()`?
5. What are the four UVM reporting severities? Which one silently
   exits the simulation?
6. How does `+UVM_VERBOSITY=UVM_HIGH` change which messages print?
   Does it affect `\`uvm_error`?

---

## Checklist

### Verification Track
- [x] Read Salemi ch.15 (analysis ports, dice example)
- [x] Read Salemi ch.16 (analysis ports in TinyALU)
- [ ] Read Salemi ch.17 (put/get + tlm_fifo)
- [ ] Read Salemi ch.18 (tester/driver split)
- [ ] Read Salemi ch.19 (UVM reporting)
- [x] Drill ch.15 (dice roller)
- [x] Drill ch.16 (analysis port in TB)
- [ ] Drill ch.17 (producer/consumer)
- [ ] Drill ch.18 (tester/driver split toy)
- [ ] Drill ch.19 (reporting + verbosity)
- [ ] HW1: full analysis path on ALU TB
- [ ] HW2: tester/driver split on ALU TB
- [ ] HW3: reporting polish
- [ ] Can answer all self-check questions

### Design Track
- [x] Read Dally ch.16 (datapath sequential)
- [ ] Read Dally ch.24 (interconnect / handshake)
- [ ] Read Sutherland ch.5 (arrays, structs, unions)
- [ ] Read Cummings async FIFO paper (theory only — build is W7)
- [x] Drill Dally ch.16 (shift register)
- [ ] Drill Dally ch.24 (valid/ready handshake)
- [ ] Drill Sutherland ch.5 (packed struct port)
- [ ] HW1: dual-port RAM
- [ ] HW2: round-robin arbiter

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_05_uvm_communication/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 5 — Week 5: UVM Communication — Analysis Ports, TLM, Reporting

> **Phase 2 — UVM Methodology** · canonical syllabus: [`docs/week_05.md`](../docs/week_05.md) · 🟡 Active (kicked off 2026-05-07)

In W4 you built the static UVM hierarchy (test → env → components,
each grabbing the BFM directly). This week you make components **talk
to each other** through UVM communication primitives:

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

Canonical syllabus: [`docs/week_05.md`](../docs/week_05.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.


---

### `learning_assignment.md`

# Week 5 — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_05.md`](../docs/week_05.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**Type 5 — Waveform / debug summary (TLM analysis-port broadcast trace)**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

LinkedIn About update mentioning current phase (UVM)

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.


---

### `homework.md`

# Week 5 — Homework

The canonical homework list lives at
[`docs/week_05.md`](../docs/week_05.md). When you start
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
cd week_05_*

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

# Week 5 — Checklist

## Verification track

- [x] Read Salemi ch.15 (analysis ports, dice example)
- [x] Read Salemi ch.16 (analysis ports in TinyALU)
- [ ] Read Salemi ch.17 (put/get + tlm_fifo)
- [ ] Read Salemi ch.18 (tester/driver split)
- [ ] Read Salemi ch.19 (UVM reporting)
- [x] Drill ch.15 (dice roller)
- [x] Drill ch.16 (analysis port in TB)
- [ ] Drill ch.17 (producer/consumer + tlm_fifo)
- [ ] Drill ch.18 (tester/driver split toy)
- [ ] Drill ch.19 (reporting + verbosity)
- [ ] HW1: full analysis path on ALU TB (extends W4 HW2)
- [ ] HW2: tester/driver split on ALU TB (extends HW1)
- [ ] HW3: reporting polish (extends HW2)
- [ ] Can answer all self-check questions

## Design track

- [x] Read Dally ch.16 (datapath sequential)
- [ ] Read Dally ch.24 (interconnect / handshake)
- [ ] Read Sutherland *SV for Design* ch.5 (arrays, structs, unions)
- [ ] Read Cummings async FIFO paper (theory only — build is W7)
- [x] Drill Dally ch.16 (shift register)
- [ ] Drill Dally ch.24 (valid/ready handshake)
- [ ] Drill Sutherland ch.5 (packed struct port)
- [ ] HW1: true dual-port RAM
- [ ] HW2: round-robin arbiter

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean (`verilator --lint-only -Wall`)
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 5 — Waveform / debug summary (TLM analysis-port broadcast trace) → `notes.md`
- [ ] **Power-skill task** — LinkedIn About update mentioning current phase (UVM)
- [ ] `notes.md` updated with at least 3 entries this week

## Daily breakdown (suggested)

```
Session 1   Read Salemi ch.15+16, drill ch.15.
            Read Dally ch.16, drill ch.16 (shift register).
Session 2   Drill ch.16, read Sutherland ch.5, drill struct port.
            Start HW1 verif (full analysis path on ALU TB).
Session 3   Finish HW1 verif. Read Salemi ch.17+18, drill ch.17.
            Read Dally ch.24, drill valid/ready handshake.
Session 4   Drill ch.18. HW2 verif (tester/driver split).
            HW1 design (true dual-port RAM).
Session 5   Read Salemi ch.19, drill ch.19, HW3 verif (reporting polish).
            HW2 design (round-robin arbiter). Self-check Qs.
```

Skip a day, don't skip the week. Skip a week, don't skip the phase.


---

### `notes.md`

# Week 5 — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

### `unique case` / `priority case` — case statement modifiers

A `unique` or `priority` keyword before `case` is a contract with the simulator and the synthesizer about how the case items relate to each other.

```systemverilog
case      (sel) ...   // plain — first match wins, no checks
unique case (sel) ...  // exactly one item matches (else: sim warning)
priority case (sel) ...// at least one item matches, listed order is the priority
```

**Why it matters:**
- *Simulation*: `unique` flags zero-match OR multi-match as a runtime warning — catches upstream bugs (e.g., a non-one-hot select from a broken arbiter) instead of silently picking the first match.
- *Synthesis*: tells the tool the items are mutually exclusive → builds a flat parallel mux instead of a priority encoder. Smaller, faster gates.

**When to use which:**
| Situation | Use |
|---|---|
| One-hot signals (arbiter output, decoded enum) | `unique case` |
| Items can overlap, listed order = priority | `priority case` |
| Complete enum table, you trust the input | plain `case` |
| You want fall-through with no warning | plain `case` |

**Same idea for `if`:**
```systemverilog
unique if (rst)        next = '0;
else if (load)         next = in;
else if (up || down)   next = outpm1;
```
Promises at-most-one branch is true; sim flags overlap.

**Concrete use** — saw this in the `Mux7` for Dally's UnivShCnt: the arbiter outputs a one-hot `sel`, the mux uses `unique case (sel)` so a non-one-hot value triggers a sim warning instead of corrupting state silently. Free insurance, zero hardware cost.

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.

