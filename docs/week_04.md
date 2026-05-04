# Week 4: UVM Architecture & Components

## Why This Matters

UVM is the industry standard. Every DV job listing in Israel mentions
it. This week you internalize **the static architecture**: the factory
pattern, `uvm_test`, `uvm_component`, and `uvm_env`. You won't touch
sequences, TLM, transactions, or analysis ports yet — those come in
weeks 5-6. The scope is deliberately narrow so each concept clicks
fully.

## What to Study (Salemi ch.9-14 only)

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.9 The Factory Pattern** ⭐ — Salemi builds a *plain SV* factory
    using a static method on `animal_factory` plus a `case` statement
    and `$cast`. The UVM factory macros (`uvm_object_utils`,
    `uvm_component_utils`, `type_id::create`, `set_type_override`) are
    introduced in **later** chapters (11+). Don't try to use them in
    your ch.9 drill — recreate the pattern Salemi actually shows.
  - **ch.10 An Object-Oriented Testbench** — pre-UVM bridge: a
    `testbench` class composes `tester` + `scoreboard` + `coverage`,
    each holding a `virtual tinyalu_bfm` handle, all launched from a
    single `execute()` method via `fork/join_none`.
  - **ch.11 UVM Tests** ⭐ — `uvm_test`, `\`uvm_component_utils`,
    `run_phase`, objections (`raise_objection` / `drop_objection`),
    `run_test()` reading `+UVM_TESTNAME`, and `uvm_config_db::set` /
    `get` for passing the BFM down.
  - **ch.12 UVM Components** ⭐ — class lineage, the **5** UVM phases
    Salemi names (`build_phase`, `connect_phase`,
    `end_of_elaboration_phase`, `run_phase`, `report_phase`) — but only
    `build_phase` and `run_phase` are *used* in the chapter. Salemi
    explicitly defers `connect_phase` to a later chapter.
  - **ch.13 UVM Environments** ⭐ — `uvm_env`, the abstract
    `base_tester` + factory override pattern (`set_type_override`).
    *This* is where the UVM factory mechanics finally appear in real
    use.
  - **ch.14 A New Paradigm** — short philosophical wrap-up; what UVM
    gives you over plain OOP.
- **Verification Academy**: "UVM Basics" course — start from lesson 1
- **ChipVerify**: [uvm-introduction](https://www.chipverify.com/uvm/uvm-introduction), [uvm-testbench-architecture](https://www.chipverify.com/uvm/uvm-testbench-architecture), [uvm-component](https://www.chipverify.com/uvm/uvm-component), [uvm-factory](https://www.chipverify.com/uvm/uvm-factory)
- **Cheatsheet**: [cheatsheets/salemi_uvm_ch9-13.sv](../cheatsheets/salemi_uvm_ch9-13.sv)
- **Consolidation PDF**: [docs/uvm_consolidation_salemi_ch9-15.pdf](uvm_consolidation_salemi_ch9-15.pdf)

### Reading — Design

- **Dally & Harting ch.10 — Arithmetic Circuits**: ripple-carry adder,
  subtractor, comparator, shift-add multiplier
- **Dally & Harting ch.12 — Fast Arithmetic**: carry-lookahead adders,
  Wallace trees, barrel shifters
- **Dally & Harting ch.13 — Arithmetic Examples**: worked designs
- **Sutherland *SV for Design* (2nd ed) ch.10 — Interfaces**: `interface`,
  `modport`, port direction, `clocking` block. (The *SV for Design*
  book has 12 chapters total — interfaces live in ch.10, not ch.4-5.)
- **Cliff Cummings** *"Synthesis Coding Styles for Efficient Designs"*

### Tool Setup

- **Vivado xsim (Docker)** — UVM-capable with `-L uvm`. Use the VSCode
  task `🧪 FLOW: XSIM UVM`.
- **EDA Playground** — fallback when xsim chokes.

---

## Verification Homework

### Drills (per-chapter warmups)

> Small (~10-30 lines), one per chapter. Do them while reading the
> chapter — the goal is to feel each concept under your fingers in
> isolation, not to build a real testbench.

- **Drill ch.9 — Plain-SV factory** ✅ already done
  *Files:* `homework/verif/per_chapter/hw_ch09_factory_pattern/`
  Recreate Salemi's animal/lion/chicken factory **as Salemi writes it**:
  an `animal_factory` class with a static `make_animal(string species,
  ...)` method that uses a `case` statement and returns the base
  `animal`. Demonstrate `$cast` from the returned `animal` into `lion`
  / `chicken`. **No UVM macros, no `type_id::create`, no
  `set_type_override`** — those belong to ch.11+ drills.

- **Drill ch.10 — OO testbench (no UVM)** ✅ partly done
  *File:* `homework/verif/per_chapter/hw_ch10_oo_testbench/oo_tb_demo.sv`
  Build a `testbench` class composing `tester` + `scoreboard` +
  `coverage` (all plain SV classes). Each holds `virtual <bfm>`. The
  `testbench::execute()` launches each child's `execute()` via
  `fork/join_none`. Pure SV classes, no `import uvm_pkg`.

- **Drill ch.11 — Hello UVM**
  *File:* `homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv`
  A minimal `uvm_test` whose `run_phase` raises an objection, prints
  `"Hello UVM"` via `\`uvm_info`, and drops the objection. `top`
  module calls `run_test()` (no string) and you select the test with
  `+UVM_TESTNAME=hello_uvm_test`.

- **Drill ch.12 — UVM component phases**
  *File:* `homework/verif/per_chapter/hw_ch12_uvm_components/phases_demo.sv`
  Define `my_component extends uvm_component`. Override **only**
  `build_phase` (print `"build"`) and `run_phase` (raise objection,
  print `"run"`, drop objection). These are the only two phases Salemi
  *uses* in ch.12. Optional bonus: also override `connect_phase` and
  `report_phase` with `\`uvm_info` prints purely to **observe phase
  ordering** in the log — Salemi names them in ch.12 but says you'll
  use `connect_phase` "in a future chapter," so don't try to do real
  work in them yet.

- **Drill ch.13 — Abstract base_tester + factory override** ⭐
  *File:* `homework/verif/per_chapter/hw_ch13_uvm_environments/base_tester_override.sv`
  Define a virtual `base_tester extends uvm_component` with two pure
  virtual methods: `function int get_op()` and `function byte
  get_data()`. Its `run_phase` calls `get_op()` / `get_data()` in a
  loop and prints them. Two concrete subclasses: `random_tester` (uses
  `$random`) and `add_tester` (returns a fixed op). Build a `uvm_env`
  that creates a `base_tester` via the factory in `build_phase`. In
  the `uvm_test::build_phase`, call
  `base_tester::type_id::set_type_override(random_tester::get_type())`
  **before** creating the env. This is the pattern ch.13 actually
  teaches.

### Main HWs

#### HW1: Architecture diagram from memory ✅ done
*Folder:* `homework/verif/big_picture/architecture_diagram/`
Drew the canonical UVM architecture (test → env → agent
{seq+drv+mon} + scoreboard + coverage) from memory and exported as
PNG.

#### HW2: ALU UVM testbench, Salemi-ch.13 style (no sequences)
*Folder:* `homework/verif/connector/hw2_alu_uvm_tb/`

Build a complete UVM testbench for the ALU DUT (from Design HW1) using
**only ch.9-14 concepts**. Architecture:

```
alu_test (uvm_test)
  └── alu_env (uvm_env)
        ├── tester_h    (abstract base_tester subclass — random or directed)
        ├── scoreboard_h (uvm_component, holds virtual alu_if directly)
        └── coverage_h   (uvm_component, holds virtual alu_if directly)
```

Constraints (these match what Salemi has *actually* taught by ch.14):

- Stimulus is generated **inside the tester component's `run_phase`**
  by calling `bfm.send_op(...)` directly — no sequencer, no driver,
  no `seq_item_port`.
- Scoreboard and coverage each grab the `virtual alu_if` from
  `uvm_config_db` in their own `build_phase` (Salemi does this in
  ch.12). They peek at the BFM's signals directly — no analysis
  ports, no `uvm_subscriber`. (Those are W5.)
- The test installs `set_type_override` for `base_tester` *before*
  creating the env.
- Two concrete tester classes; two `uvm_test` subclasses
  (`random_test`, `add_test`) that differ only in the override they
  install. Same compile, switch via `+UVM_TESTNAME=...`.

When you finish, run both tests against one compile and confirm the
log shows the expected stimulus.

#### HW3: Standalone factory override demo
*Folder:* `homework/verif/big_picture/factory_override_demo/`

A second, simpler take on the override mechanism, fully decoupled
from the ALU TB:

- `slow_driver extends uvm_component` whose `run_phase` prints
  `"SLOW: tick"` every 10 time units, 5 times.
- `fast_driver extends slow_driver` overrides `run_phase` to print
  `"FAST: tick"` every 1 time unit, 5 times.
- Two tests, identical in every way except one installs
  `slow_driver::type_id::set_type_override(fast_driver::get_type())`
  in `build_phase` and the other doesn't.

Goal: see the override flip behavior with zero changes to the env code.

### Stretch (optional)

- **Topology print**: in your HW2 env, add an
  `end_of_elaboration_phase` that calls `uvm_top.print_topology()`.
  Salemi doesn't show this directly, but it's the standard sanity
  check. (Footnoted as stretch because it's not in the book.)

---

## Design Homework

### Drills (per-chapter warmups)

- **Drill Dally ch.10 — Ripple-carry adder**
  *Folder:* `homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/`
  Parameterized N-bit ripple-carry adder, simple TB driving a few
  vectors.

- **Drill Dally ch.12 — Carry-lookahead adder**
  *Folder:* `homework/design/per_chapter/hw_dally_ch12_fast_arithmetic/`
  4-bit CLA adder. Compare gate count and critical-path delay vs
  ripple-carry on paper.

- **Drill Sutherland ch.10 — ALU SV interface**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch10_interfaces/`
  Write `alu_if` with `modport dut`, `modport tb`, `modport monitor`,
  and a `clocking` block. (Note: the Sutherland *SV for Design* book's
  Interfaces chapter is ch.10 — not ch.4-5 as earlier drafts of this
  doc claimed.)

### Main HWs

#### HW1: ALU DUT
*Folder:* `homework/design/connector/alu/`

```systemverilog
module alu #(
    parameter WIDTH = 8
)(
    input  logic                clk, rst_n,
    input  logic [WIDTH-1:0]    operand_a, operand_b,
    input  logic [2:0]          operation,   // ADD, SUB, AND, OR, XOR
    input  logic                valid_in,
    output logic [WIDTH:0]      result,      // extra bit for carry
    output logic                valid_out
);
```

Industry practices:
- Registered outputs (1-cycle latency)
- `valid_in` / `valid_out` handshake
- Parameterized width
- `always_ff` for the result register; `always_comb` for the op MUX

This is the DUT for Verif HW2 above.

#### HW2: Sequential shift-add multiplier
*Folder:* `homework/design/big_picture/shift_add_multiplier/`

Multi-cycle multiplier using an FSM (IDLE → COMPUTE → DONE). WIDTH
clock cycles per multiply. Test corner cases: 0×N, 1×N, MAX×MAX, plus
100 random pairs compared against the `*` operator.

Bonus: Booth's algorithm for signed multiplication. (FSM control is
covered more deeply in Dally ch.16, which arrives in W5 — the FSM
here is small enough that you can derive it from ch.10's text + the
FSM coding you did in W3.)

#### HW3: Barrel shifter
*Folder:* `homework/design/big_picture/barrel_shifter/`

Single-cycle barrel shifter, `log2(WIDTH)` cascaded MUX layers.
Supports SLL / SRL / SRA. Test with various shift amounts and the
sign-bit fill on SRA.

---

## Self-Check Questions

After all reading + HW, you should answer these without looking:

1. What's the difference between `uvm_object` and `uvm_component`?
2. Why use `type_id::create()` instead of `new()`?
3. Which UVM phases does Salemi ch.12 actually *use* (vs just *name*)?
4. In Salemi's ch.13 architecture, which class installs the factory
   override — the `uvm_env` or the `uvm_test`? Why?
5. What does `uvm_config_db` do, and why does ch.11's `top` module
   need it?
6. Why is the abstract-base-class + factory-override pattern useful?
   (Hint: same env, different stimulus styles, picked at runtime.)

---

## Checklist

### Verification Track
- [x] Read Salemi *UVM Primer* ch.9 (factory)
- [x] Read Salemi *UVM Primer* ch.10 (OO testbench)
- [x] Read Salemi *UVM Primer* ch.11 (uvm_test)
- [x] Read Salemi *UVM Primer* ch.12 (uvm_components)
- [x] Read Salemi *UVM Primer* ch.13 (uvm_environments)
- [x] Read Salemi *UVM Primer* ch.14 (a new paradigm)
- [ ] Watched Verification Academy UVM Basics
- [x] Drill ch.9 (factory pattern — UVM-style)
- [x] Drill ch.10 (OO testbench, no UVM)
- [x] Drill ch.11 (hello UVM)
- [x] Drill ch.12 (component phases — build + run only)
- [x] Drill ch.13 (abstract base_tester + factory override)
- [x] HW1: architecture diagram from memory
- [ ] HW2: ALU UVM TB, Salemi-ch.13 style (no sequences)
- [ ] HW3: standalone factory override demo
- [ ] Can answer all self-check questions

### Design Track
- [x] Read Dally ch.10 (arithmetic circuits)
- [x] Read Dally ch.12 (fast arithmetic)
- [ ] Read Sutherland *SV for Design* ch.10 (interfaces)
- [x] Drill Dally ch.10 (ripple-carry adder)
- [x] Drill Dally ch.12 (carry-lookahead adder)
- [x] Drill Sutherland ch.10 (ALU SV interface)
- [x] HW1: ALU DUT (registered, valid handshake)
- [ ] HW2: shift-add multiplier
- [ ] HW3: barrel shifter

<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->

## Daily-driver views

*Auto-mirrored from `week_04_uvm_architecture/` — edit those files, then run `python3 tools/sync_week_docs.py` to refresh this section.*


---

### `README.md`

# Week 4 — UVM Architecture & Components

> **Phase 2 — UVM Methodology** · Salemi ch.9–14 · 🟡 In progress (verif done; design TODO)

The week where the UVM static architecture clicks: factory pattern,
`uvm_test`, `uvm_component`, `uvm_env`. Sequences, TLM, transactions
are **deliberately deferred to W5–W6** — keep scope tight.

## Prerequisites

- [[week_01_sv_oop]] — classes, inheritance, virtual methods
- [[week_02_constrained_random]] — randomization basics
- [[week_03_coverage_assertions]] — covergroups, SVA
- Concept notes: [[concepts/uvm_phases]], [[concepts/uvm_factory_config_db]],
  [[concepts/interfaces_modports]]

## Estimated time split (24h total)

```
Reading        6h   Salemi ch.9-14 + Sutherland Design ch.10 + ChipVerify
Design         8h   Dally ch.10/12 drills + ALU + multiplier + barrel shifter
Verification   8h   Salemi drills (ch.9-13 done) + ALU UVM TB + override demo
AI + Power     2h   AI: interview Qs on UVM phases; Power: STAR — UVM bug
```

## Portfolio value (what this week proves)

- You can build a UVM environment from scratch using only the static
  architecture (no sequences).
- You understand the factory pattern at the **plain SV level first**
  (Salemi ch.9), then with UVM macros (ch.13).
- You can apply `set_type_override` to swap stimulus styles without
  touching env code — the single most reusable UVM pattern.

## Iron-Rule deliverables

- [x] **(b)** Gold TB PASS log — Salemi drills ch.9–13 PASS captured.
- [ ] **(a)** RTL committed — ALU + adders + multiplier + barrel shifter (in progress).
- [ ] **(b)** Gold TB PASS log — ALU UVM TB run.
- [ ] **(c)** `verification_report.md` — UVM env walkthrough + factory override flip evidence.

## Daily-driver files

- [[learning_assignment]] — page-precise reading + AI productivity task
- [[homework]] — exercise list with acceptance criteria
- [[checklist]] — daily checkboxes
- [[notes]] — your freeform notes

Canonical syllabus: [`docs/week_04.md`](../docs/week_04.md).


---

### `learning_assignment.md`

# Week 4 — Learning Assignment

## Reading — Verification

Anchor: **Salemi *The UVM Primer* ch.9–14**.

| # | Chapter | Why |
|---|---|---|
| ch.9 | The Factory Pattern (in plain SV) | Understand the *mechanism* before UVM macros. Salemi builds an `animal_factory` with a static method + `case` + `$cast`. |
| ch.10 | An OO Testbench | Pre-UVM bridge: `testbench` class composing `tester`/`scoreboard`/`coverage` via `fork/join_none`. |
| ch.11 | UVM Tests ⭐ | `uvm_test`, `\`uvm_component_utils`, `run_phase`, objections, `+UVM_TESTNAME`, `uvm_config_db`. |
| ch.12 | UVM Components ⭐ | The 5 phases Salemi names; only `build_phase` and `run_phase` are *used* in the chapter — don't try to do real work in the others yet. |
| ch.13 | UVM Environments ⭐ | `uvm_env` + abstract `base_tester` + factory override. The first time UVM macros pay off. |
| ch.14 | A New Paradigm | Short philosophical close — what UVM gives you over plain OOP. |

**Page-precise refs**: see canonical `docs/week_04.md` — Yuval's
already-confirmed chapter list. (Page numbers TBD; `TO VERIFY` open
on whether Salemi 1st ed ch.13 begins at p.103 or p.110 — confirm
when reading.)

Concept notes to skim/update:
- [[concepts/uvm_phases]]
- [[concepts/uvm_factory_config_db]]
- [[concepts/interfaces_modports]] — for the ALU `alu_if`
- [[concepts/sva_assertions]] — for the assertion bundle on the ALU

## Reading — Design

| Source | Why |
|---|---|
| Dally & Harting ch.10 — Arithmetic Circuits | Ripple-carry adder, subtractor, comparator, shift-add multiplier. **TO VERIFY** — confirm chapter contents before writing the W4 design HW. |
| Dally & Harting ch.12 — Fast Arithmetic | CLA, Wallace trees, barrel shifters. |
| Sutherland *SV for Design* (2e) ch.10 — Interfaces | `interface`, `modport`, `clocking`. The Sutherland *SV for Design* book interfaces chapter is **ch.10** — earlier drafts of this plan said ch.4-5; that was wrong. |
| Cummings *Synthesis Coding Styles for Efficient Designs* (SNUG-2012) | Synthesis-friendly RTL idioms for the ALU. |

Concept notes: [[concepts/adders_carry_chain]], [[concepts/multipliers]],
[[concepts/interfaces_modports]], [[concepts/synthesis_basics]].

Cheatsheets to skim:
- `cheatsheets/salemi_uvm_ch9-13.sv` — your own UVM reference card.
- `cheatsheets/spear_ch4_interfaces.sv` — interfaces + clocking blocks
  (despite the filename, this is the right reference for the
  Sutherland ch.10 material too).

## Tool setup

UVM weeks need Vivado xsim Docker (open-source UVM support is
incomplete). Use the per-week VSCode task **🧪 FLOW: XSIM UVM** or
the CLI:

```bash
cd week_04_uvm_architecture
bash ../run_xsim.sh -L uvm homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv
```

EDA Playground fallback: paste the same files; pick "Aldec Riviera" or
"Synopsys VCS" with UVM 1.2.

## AI productivity task (this week)

**Type 4 — Interview Questions** (per `docs/AI_LEARNING_GUIDE.md` §3).

Prompt: copy [`docs/prompts/interview-questions.md`](../docs/prompts/interview-questions.md),
fill the topic as `UVM phases, factory pattern, uvm_config_db`. Generate
10 questions. Write your own answers in `notes.md` first; only then
ask AI for its answers and compare.

Time budget: 30 min. Output goes to `notes.md` under
`## AI interview Qs — UVM`.

## Power-skill task (this week)

Per `docs/POWER_SKILLS.md` §1: draft your **first STAR story** about a
UVM bug. The example STAR in `concepts/star_stories_template.md` is
literally the `uvm_config_db` typo bug — if that one resonates with
your own debug, use it as the seed. Otherwise pick a different ch.9-13
drill and write your own.

Output: `docs/star_stories/01_uvm_config_db.md` (folder doesn't exist
yet — create it when you write the first story).

Time budget: 30 min.


---

### `homework.md`

# Week 4 — Homework

State as of bootstrap: 5 verif drills DONE, design side stubbed.
Continue from where the canonical syllabus leaves off.

## Per-chapter drills — Verification

| Chapter | File path | Status | Acceptance |
|---|---|---|---|
| Salemi ch.9 | `homework/verif/per_chapter/hw_ch09_factory_pattern/factory_demo_pkg.sv` + `factory_demo_top.sv` | ✅ DONE | Animal factory using plain SV `case`+`$cast`; no UVM macros. |
| Salemi ch.10 | `homework/verif/per_chapter/hw_ch10_oo_testbench/oo_tb_demo.sv` | ✅ DONE | `testbench` class composes `tester`/`scoreboard`/`coverage`; `execute()` via `fork/join_none`. |
| Salemi ch.11 | `homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv` | ✅ DONE | Minimal `uvm_test`; `+UVM_TESTNAME` selection works. |
| Salemi ch.12 | `homework/verif/per_chapter/hw_ch12_uvm_components/phases_demo.sv` | ✅ DONE | `my_component` overrides `build_phase` + `run_phase` only. |
| Salemi ch.13 | `homework/verif/per_chapter/hw_ch13_uvm_environments/base_tester_override.sv` | ✅ DONE | Abstract `base_tester` with `random_tester` and `add_tester` subclasses; `set_type_override` flips behaviour. |

## Per-chapter drills — Design (TODO — Yuval's current focus)

| Chapter | File path | Status | Acceptance |
|---|---|---|---|
| Dally ch.10 | `homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/ripple_carry_adder.sv` + `_tb.sv` | ⬜ TODO | Parameterised N-bit ripple-carry adder; TB drives a few vectors and asserts sum. |
| Dally ch.12 | `homework/design/per_chapter/hw_dally_ch12_fast_arithmetic/cla_adder.sv` + `_tb.sv` | ⬜ TODO | 4-bit CLA. Compare gate count and critical-path delay vs ripple-carry on paper (write up in `notes.md`). |
| Sutherland ch.10 | `homework/design/per_chapter/hw_sutherland_ch4_interfaces/alu_if.sv` | ⬜ TODO | `alu_if` with `modport dut`, `modport tb`, `modport monitor`, `clocking` block. (Folder slug says `ch4` but reading is ch.10 — beta filename artefact; don't rename, just use it.) |

## Connector exercise — Design

### `homework/design/connector/alu/alu.sv` ⬜ TODO

Spec (industry style):

```systemverilog
module alu #(
    parameter int WIDTH = 8
)(
    input  logic                  clk, rst_n,
    input  logic [WIDTH-1:0]      operand_a, operand_b,
    input  logic [2:0]            operation,    // ADD, SUB, AND, OR, XOR
    input  logic                  valid_in,
    output logic [WIDTH:0]        result,       // extra bit for carry
    output logic                  valid_out
);
```

- Registered outputs (1-cycle latency).
- `valid_in` / `valid_out` handshake.
- `always_ff` for the result register; `always_comb` for the op MUX.
- Lint-clean: `verilator --lint-only -Wall alu.sv` → zero warnings.

This DUT is reused by Verif HW2 below.

## Connector exercise — Verification

### `homework/verif/connector/hw2_alu_uvm_tb/` ⬜ IN PROGRESS

Build a UVM TB for the ALU **using only ch.9–14 concepts** (no
sequences, no TLM, no analysis ports — those are W5).

```
alu_test (uvm_test)
  └── alu_env (uvm_env)
        ├── tester_h     (abstract base_tester subclass)
        ├── scoreboard_h (uvm_component, holds virtual alu_if directly)
        └── coverage_h   (uvm_component, holds virtual alu_if directly)
```

Two concrete tester classes; two `uvm_test` subclasses (`random_test`,
`add_test`) differing only in the `set_type_override` they install.
Same compile, switch via `+UVM_TESTNAME=...`.

Acceptance: log shows expected stimulus per test; both tests PASS in
one regression.

## Big-picture exercises — Design

### `homework/design/big_picture/shift_add_multiplier/shift_add_multiplier.sv` ⬜ TODO

Multi-cycle multiplier using FSM (IDLE → COMPUTE → DONE). WIDTH cycles
per multiply. Test corner cases: 0×N, 1×N, MAX×MAX, plus 100 random
pairs cross-checked against the `*` operator.

### `homework/design/big_picture/barrel_shifter/barrel_shifter.sv` ⬜ TODO

Single-cycle barrel shifter, `log2(WIDTH)` cascaded MUX layers. SLL /
SRL / SRA. Test sign-fill on SRA.

## Big-picture exercise — Verification

### `homework/verif/big_picture/factory_override_demo/` ⬜ TODO

Standalone factory-override demo, decoupled from the ALU TB:

- `slow_driver extends uvm_component` — `run_phase` prints `"SLOW: tick"`
  every 10 time units, 5 times.
- `fast_driver extends slow_driver` — overrides `run_phase` to print
  `"FAST: tick"` every 1 time unit, 5 times.
- Two tests, identical except one installs
  `slow_driver::type_id::set_type_override(fast_driver::get_type())`
  in `build_phase` and the other doesn't.

Goal: see the override flip behaviour with **zero** changes to env
code.

## Self-check questions

After all reading + HW, answer these without looking:

1. What's the difference between `uvm_object` and `uvm_component`?
2. Why use `type_id::create()` instead of `new()`?
3. Which UVM phases does Salemi ch.12 actually *use* (vs just *name*)?
4. In ch.13's architecture, which class installs the factory override
   — the `uvm_env` or the `uvm_test`? Why?
5. What does `uvm_config_db` do, and why does ch.11's `top` module
   need it?
6. Why is the abstract-base-class + factory-override pattern useful?

## Run commands

### Verif drills (already passing)

```bash
cd week_04_uvm_architecture
bash ../run_xsim.sh -L uvm homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv
```

### Design drills (when ready)

```bash
cd week_04_uvm_architecture
verilator --lint-only -Wall homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/ripple_carry_adder.sv
iverilog -g2012 -o /tmp/rca homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/ripple_carry_adder_tb.sv
vvp /tmp/rca
```

### Yosys schematic (W4 reuse)

```bash
bash ../run_yosys_rtl.sh homework/design/connector/alu/alu.sv
# → builds alu.svg in build_rtl/
```

## Stretch (optional)

- **Topology print**: in HW2 env, add `end_of_elaboration_phase` that
  calls `uvm_top.print_topology()`. Standard sanity check.
- **Booth multiplier** for Dally ch.10: signed multiplication via
  Booth encoding (W16 preview).


---

### `checklist.md`

# Week 4 — Checklist

State as of bootstrap (2026-05-03): 48% done per badge.

## Verification track

- [x] Read Salemi *UVM Primer* ch.9 (factory)
- [x] Read Salemi *UVM Primer* ch.10 (OO testbench)
- [x] Read Salemi *UVM Primer* ch.11 (uvm_test)
- [x] Read Salemi *UVM Primer* ch.12 (uvm_components)
- [x] Read Salemi *UVM Primer* ch.13 (uvm_environments)
- [x] Read Salemi *UVM Primer* ch.14 (a new paradigm)
- [ ] Watched Verification Academy UVM Basics
- [x] Drill ch.9 (factory pattern — plain SV)
- [x] Drill ch.10 (OO testbench, no UVM)
- [x] Drill ch.11 (hello UVM)
- [x] Drill ch.12 (component phases — build + run only)
- [x] Drill ch.13 (abstract base_tester + factory override)
- [x] HW1: architecture diagram from memory
- [ ] HW2: ALU UVM TB, Salemi-ch.13 style (no sequences)
- [ ] HW3: standalone factory override demo
- [ ] Can answer all self-check questions

## Design track

- [x] Read Dally ch.10 (arithmetic circuits)
- [x] Read Dally ch.12 (fast arithmetic)
- [ ] Read Sutherland *SV for Design* ch.10 (interfaces)
- [x] Drill Dally ch.10 (ripple-carry adder)
- [x] Drill Dally ch.12 (carry-lookahead adder)
- [x] Drill Sutherland ch.10 (ALU SV interface)
- [x] HW1: ALU DUT (registered, valid handshake)
- [ ] HW2: shift-add multiplier
- [ ] HW3: barrel shifter

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean (`verilator --lint-only -Wall`)
- [x] (b) Gold-TB PASS log captured for verif drills (`sim/uvm_drills_pass.log`)
- [ ] (b) Gold-TB PASS log captured for ALU TB (`sim/alu_uvm_pass.log`)
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Interview Qs on UVM phases (per
  `learning_assignment.md`). Output to `notes.md` under
  `## AI interview Qs — UVM`.
- [ ] **Power-skill task** — Draft first STAR story:
  `docs/star_stories/01_uvm_config_db.md`.
- [ ] `notes.md` updated with at least 3 entries this week.

## Daily breakdown (suggested)

```
Day 1 (Mon)  Read Salemi ch.14 (close out ch.9-14). Skim Sutherland ch.10.
Day 2 (Tue)  Drill Dally ch.10 ripple-carry adder + TB.
Day 3 (Wed)  Drill Dally ch.12 CLA + TB. Write paper comparison in notes.md.
Day 4 (Thu)  Drill Sutherland ch.10 alu_if. Implement HW1 ALU DUT.
Day 5 (Fri)  HW2 ALU UVM TB connector — wire scoreboard/coverage.
Day 6 (Sat)  HW3 factory override demo. Run both tests; capture PASS log.
Day 7 (Sun)  Big-picture: shift-add multiplier OR barrel shifter (pick one).
             AI task + STAR story + verification_report.md.
```

Skip a day, don't skip the week. Skip a week, don't skip the phase.


---

### `notes.md`

# Week 4 — Notes

## Open questions

- (none yet — add as they come up while reading or coding)

## Aha moments

- (none yet)

## AI corrections

> Track here any time AI confidently said something the book
> contradicted. Include the source (chat date, book chapter,
> page).

## AI interview Qs — UVM

> Output of this week's AI productivity task. Question first, your
> answer second, AI's suggested answer third, your reflection last.

## Methodology lessons

> One paragraph per debug session worth remembering. Feeds your STAR
> story bank in `docs/star_stories/`.

