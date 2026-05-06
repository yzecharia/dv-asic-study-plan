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
- [x] Drill ch.9 (factory pattern — plain SV)
- [x] Drill ch.10 (OO testbench, no UVM)
- [x] Drill ch.11 (hello UVM)
- [x] Drill ch.12 (component phases — build + run only)
- [x] Drill ch.13 (abstract base_tester + factory override)
- [x] HW1: architecture diagram from memory
- [x] HW2: ALU UVM TB, Salemi-ch.13 style (no sequences)
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

> **Phase 2 — UVM Methodology** · Salemi ch.9–14 · 🟡 In progress (verif drills + ALU UVM TB done; design big-picture HWs + Iron-Rule (a) lint TODO)

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
- [x] **(b)** Gold TB PASS log — ALU UVM TB random + directed (`sim/connector_alu_*_pass.log`).
- [x] **(c)** `verification_report.md` — UVM env walkthrough, factory override flip evidence, bug log.

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
already-confirmed chapter list.

Concept notes to skim/update:
- [[concepts/uvm_phases]]
- [[concepts/uvm_factory_config_db]]
- [[concepts/interfaces_modports]] — for the ALU `alu_if`
- [[concepts/sva_assertions]] — for the assertion bundle on the ALU

## Reading — Design

| Source | Why |
|---|---|
| Dally & Harting ch.10 — Arithmetic Circuits | Ripple-carry adder, subtractor, comparator, shift-add multiplier. |
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

State as of 2026-05-04: verif per-chapter drills RESET — Yuval is
redoing them from scratch after a break to re-anchor ch.9–13 before
moving to HW2 (ALU UVM TB). Design side stubbed.

## Per-chapter drills — Verification

| Chapter | File path | Status | Acceptance |
|---|---|---|---|
| Salemi ch.9 | `homework/verif/per_chapter/hw_ch09_factory_pattern/factory_demo_pkg.sv` + `factory_demo_top.sv` | ✅ DONE | Animal factory using plain SV `case`+`$cast`; no UVM macros. |
| Salemi ch.10 | `homework/verif/per_chapter/hw_ch10_oo_testbench/oo_tb_demo.sv` | ✅ DONE | `testbench` class composes `tester`/`scoreboard`/`coverage`; `execute()` via `fork/join_none`. |
| Salemi ch.11 | `homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.svh` | ✅ DONE | Minimal `uvm_test`; `+UVM_TESTNAME` selection works. |
| Salemi ch.12 | `homework/verif/per_chapter/hw_ch12_uvm_components/phase_demo.sv` | ✅ DONE | `my_component` overrides `build_phase` + `run_phase` only. |
| Salemi ch.13 | `homework/verif/per_chapter/hw_ch13_uvm_environments/{base_tester,random_tester,add_tester,env,random_test,add_test}.svh + ch13_pkg.svh + top.sv` | ✅ DONE | Abstract `base_tester` with `random_tester` and `add_tester` subclasses; `set_type_override` flips behaviour. |

## Per-chapter drills — Design

| Chapter | File path | Status | Acceptance |
|---|---|---|---|
| Dally ch.10 | `homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/ripple_carry_adder.sv` + `_tb.sv` | ✅ DONE | Parameterised N-bit ripple-carry adder; TB drives a few vectors and asserts sum. |
| Dally ch.12 | `homework/design/per_chapter/hw_dally_ch12_fast_arithmetic/cla_adder.sv` + `_tb.sv` | ✅ DONE | 4-bit CLA. Compare gate count and critical-path delay vs ripple-carry on paper (write up in `notes.md`). |
| Sutherland ch.10 | `homework/design/per_chapter/hw_sutherland_ch4_interfaces/alu_if.sv` | ✅ DONE | `alu_if` with `modport dut`, `modport tb`, `modport monitor`, `clocking` block. (Folder slug says `ch4` but reading is ch.10 — beta filename artefact; don't rename, just use it.) |

## Connector exercise — Design

### `homework/design/connector/alu/alu.sv` ✅ DONE

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

### `homework/verif/connector/` ✅ DONE
(files live directly under `connector/`, not under `hw2_alu_uvm_tb/`
as the original spec sketched — beta naming artefact, kept flat.)

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
- [x] HW2: ALU UVM TB, Salemi-ch.13 style (no sequences)
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
- [x] (b) Gold-TB PASS log captured for ALU TB
  (`sim/connector_alu_random_pass.log`,
  `sim/connector_alu_directed_pass.log`)
- [x] (c) `verification_report.md` written

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

## Salemi ch.10 — OO Testbench

### File / class roles (pp. 59–65)

- **top** — top-level module. Where the DUT, BFM, and testbench class
  are instantiated; the `initial` block fires up the run by calling
  `testbench_h = new(bfm); testbench_h.execute();`.
- **testbench** — top-level class. Composes `tester`, `scoreboard`,
  and `coverage` **directly** — flat hierarchy, no env layer in ch.10.
  (`uvm_env` is introduced in ch.13.)
- **tester** — generates **and** drives stimulus via the BFM. The
  pre-UVM equivalent of "sequence + sequencer + driver" rolled into a
  single class. UVM later splits this responsibility three ways.
- **scoreboard** — holds the **reference model** and compares DUT
  actual outputs against expected values.
- **coverage** — wraps a `covergroup`, samples bins per transaction.

### Corrections to my first paraphrase (2026-05-06)

- I said the testbench "instantiates the env" — wrong. No env class
  exists until ch.13. In ch.10, testbench composes tester /
  scoreboard / coverage directly.
- I said tester == "driver in industry terms" — too narrow. UVM
  industry pattern splits stimulus generation (sequence), arbitration
  (sequencer), and pin driving (driver) into three classes. The
  Salemi tester is all three combined.

### What the top module does (pp. 65–66)

- **Module-scope instantiations** (compile/elaboration time):
  - DUT (`tinyalu DUT (...)`) wired through the BFM signals.
  - BFM/interface (`tinyalu_bfm bfm()`).
  - Testbench class **handle** (`testbench testbench_h;`) — the
    object is null at this point; only the handle exists.
- **Imports**: `import oo_tb_pkg::*;` — the project package, which
  carries `operation_t` and `` `include`s all class .svh files.
- **`initial` block** (simulation time):
  - Construct: `testbench_h = new(bfm);`
  - Launch:    `testbench_h.execute();`

### Corrections — second paraphrase (2026-05-06)

- I said we "instantiate the testbench" alongside the DUT and BFM.
  Wrong mechanism: classes are not instantiated like modules.
  Module-scope can only hold the **handle** declaration; the **object
  construction** (`new(...)`) must be inside `initial` (or a task /
  function that runs at sim time). Don't put `testbench testbench_h
  = new(bfm);` at module scope.
- I said we "import the UVM package and macros" in the ch.10 top.
  Wrong chapter — ch.10 is pre-UVM by design. UVM (`uvm_pkg::*` +
  `uvm_macros.svh`) doesn't enter until ch.11. The ch.10 top imports
  only the project package.

### `execute()` vs UVM phases (p.65)

The `initial` block does two things:

1. **Construct** the testbench — `testbench_h = new(bfm);` — which
   triggers the testbench constructor's `new` calls for tester /
   scoreboard / coverage children, wiring the BFM into each.
2. **Launch** — `testbench_h.execute();` — which forks the three
   children's `execute()` tasks.

OO ch.10 ↔ UVM ch.11+ mapping:

| OO ch.10 | UVM ch.11+ |
|---|---|
| `testbench_h = new(bfm)` (children's `new`s run inline) | factory `create()` + `build_phase` + `connect_phase` |
| `testbench_h.execute()` | `run_phase` only |
| (none) | `extract_phase` → `check_phase` → `report_phase` → `final_phase` |

So `execute()` is **just `run_phase`**, not "all the phases." UVM's
phase machine exists because production envs need deterministic
build/connect ordering across many components; ch.10 doesn't need
that — wiring is manual and fork-join is enough.

### Corrections — third paraphrase (2026-05-06)

- I said `execute()` corresponds to "all the phases in actual UVM."
  Wrong scope. `execute()` ≈ `run_phase` only. Build/connect work
  happens in `new()` for the OO version; extract/check/report/final
  have no OO analog at all.
- "Instantiate the testbench with the interface" again — class
  **construction** via `new(bfm)`, not module-style instantiation.
  Same correction as the previous note; muscle-memory it.

### What the testbench class does (p.62, p.65)

- The OO testbench is **both** entry point (the `initial` constructs
  it and calls `execute()`) **and** structural container (it owns
  `tester_h`, `scoreboard_h`, `coverage_h`). UVM later splits these
  responsibilities into `uvm_test` (entry / per-run intent) and
  `uvm_env` (reusable container).
- "Connecting" the children in ch.10 means **passing the shared BFM**
  into each child's constructor. The three children **do not talk to
  each other** — they each independently access the BFM. Class-to-
  class wiring via analysis ports starts in ch.16.

OO ch.10 ↔ UVM mapping:

| OO ch.10 | UVM equivalent |
|---|---|
| `top` module | `top` module (same) |
| `testbench` class | `uvm_test` **+** `uvm_env` combined |
| `tester` class | `uvm_sequence` + `uvm_sequencer` + `uvm_driver` combined |
| `scoreboard` class | `uvm_scoreboard` |
| `coverage` class | `uvm_subscriber#(T)` |
| BFM (interface w/ tasks) | `interface` + `uvm_driver` + `uvm_monitor` (split in UVM) |

### Corrections — fourth paraphrase (2026-05-06)

- I said the testbench class "is basically the env." Closer to
  **env + test combined**. The OO testbench is the entry point AND
  the container; UVM separates those two roles for reuse.
- I said the testbench "connects them together." In ch.10 the three
  children are **peers around the BFM**, not connected to each
  other. Cross-class TLM wiring is a ch.16 concept.

### `virtual` interface — what it actually means (p.62)

The interface **does exist at compile time** — it's the
`tinyalu_bfm bfm()` line in `top`. What doesn't exist yet is the
**class instance**. Classes and modules/interfaces live in two
different worlds:

- **Static world** — modules and interfaces, elaborated once, wired
  with `.signal(...)`.
- **Dynamic world** — classes, constructed at runtime via `new()`,
  live on the heap.

A class can't directly bind to a static-world interface. The bridge
is a **handle** — `virtual tinyalu_bfm bfm` means "a phone number
that points at some `tinyalu_bfm` instance over there."

Mechanics for `function new(virtual tinyalu_bfm b); bfm = b; endfunction`:

1. `b` is the constructor arg — a handle the caller passed in.
2. `bfm` is the class member — also a handle.
3. `bfm = b;` copies **the handle (phone number), not the interface**
   itself. Both refer to the same single interface in `top`.
4. Calls like `bfm.send_op(...)` dereference the handle and run the
   actual interface's task.

```
   top.bfm  (THE interface — one instance in the static world)
       ▲     ▲     ▲
       │     │     │  (handles — all point at the same instance)
   tester_h.bfm  scoreboard_h.bfm  coverage_h.bfm
```

**Without `virtual`** (i.e. `tinyalu_bfm bfm;` inside a class) →
compile error. You can't put a static-world citizen into a
dynamic-world container.

### Corrections — fifth paraphrase (2026-05-06)

- I said `virtual` "tells the compiler there isn't an interface
  passed at compilation but there will be one in the future." Wrong
  framing. The interface DOES exist at compile time (it's in `top`).
  What `virtual` does is allow a class (dynamic-world object) to
  hold a **handle** pointing at a static-world interface instance.
  The "virtual" keyword here is about *indirection*, not "later".

### Salemi's actual ch.10 testbench pattern (p.65 — verified from book)

The constructor just stashes the BFM handle. All the real work
(creating children + forking) happens inside `execute()`:

```systemverilog
class testbench;
    virtual tinyalu_bfm bfm;
    tester     tester_h;
    coverage   coverage_h;
    scoreboard scoreboard_h;

    function new (virtual tinyalu_bfm b);
        bfm = b;
    endfunction : new

    task execute();
        tester_h     = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);

        fork
            tester_h.execute();
            coverage_h.execute();
            scoreboard_h.execute();
        join_none
    endtask : execute
endclass : testbench
```

Two valid OO design choices for where children get created:

| Pattern | Constructor | execute() | Salemi uses |
|---|---|---|---|
| **A — Salemi style (ch.10)** | only stores BFM handle | creates children, then forks | ✓ |
| **B — build/run-separated** | stores BFM + creates children | only forks | (closer to UVM phase model) |

Both are correct in pre-UVM OO. Salemi picks A for compactness; UVM
later mandates B because production envs need deterministic
elaboration order.

### `join_none` vs the scaffolded top (gotcha for our HW)

Salemi's `execute()` ends with **plain `join_none`** — no
`wait fork`. His top.sv also has **no `$finish`**, so the forked
children just keep running and the simulator decides when to stop.

But the scaffolded `oo_tb_demo.sv` for our HW has:

```systemverilog
initial begin
    testbench_h = new(bfm);
    testbench_h.execute();
    $display("OO TB DEMO PASS");
    $finish;
end
```

With `join_none` and no `wait fork`, `execute()` returns at time 0
and `$finish` fires before any stimulus runs — sim "passes" with
zero work.

Fix: add **`wait fork;`** after `join_none` inside
`testbench::execute()`. Now the parent task blocks until the three
children finish; the top's `$display(PASS); $finish;` runs only
after real stimulus + checking has happened.

### Build/run mapping to UVM (still useful)

Even with Salemi's pattern A, the build-vs-run distinction is real —
it's just that build happens in the first three lines of `execute()`
instead of in `new()`. The conceptual mapping holds:

| OO ch.10 (whichever style) | UVM equivalent |
|---|---|
| BFM handle wiring | `build_phase` |
| child `new()` calls | `build_phase` |
| forking children's `execute()` | `run_phase` |

### Correction-of-correction — sixth paraphrase revisited (2026-05-06)

Yuval's note was right; my previous response was wrong. **Salemi
puts the children's creation inside `execute()`, not in `new()`.**
The "Canonical shape" code block I appended earlier showed creation
in `new()` — that's a valid alternative pattern, but it's NOT what
the book teaches. The actual pattern is the one shown directly above.

Yuval's homework should follow Salemi's pattern A and add
`wait fork;` after `join_none` to play nicely with the scaffolded
`$finish` in `oo_tb_demo.sv`.

### `fork ... join` variants — reference

| Construct | Behaviour | Use when |
|---|---|---|
| `fork ... join` | spawn N threads, **block until ALL finish** | every child must complete before continuing |
| `fork ... join_any` | spawn N threads, **block until FIRST finishes**, others keep running | racing two things (stimulus vs watchdog) |
| `fork ... join_none` | spawn N threads, **don't block** — children run in background | parent has more work after fork, or children own their own lifetime |

**Why Salemi picks `join_none` in ch.10:**

The three children (tester, scoreboard, coverage) own their own
lifetimes — each runs until it decides to exit. The parent doesn't
need a synchronous handle on them. This is a deliberate teaching
rehearsal for UVM's `run_phase` model, where many components run in
parallel and the test ends when **objections drop**, not when any
one task finishes.

**`wait fork`** — after `fork ... join_none`, the forked threads are
still alive. `wait fork;` blocks until every thread previously
forked off in this scope completes. Necessary when the parent must
synchronise back (e.g. before letting the top hit `$finish`).

## Salemi ch.11 — UVM Tests

### `uvm_config_db` — what it is and the API (p.~70)

`uvm_config_db` is **not a global variable.** It's a hierarchically-
scoped key/value store. Components SET values at a path with a
field name; other components GET values from a path matching the
field name. Lookup rules: most-specific-match-wins, wildcards
allowed in paths.

Full API:

```systemverilog
// SET
uvm_config_db#(T)::set(
    uvm_component cntxt,     // context component (or null for absolute path)
    string        inst_name, // path under cntxt; supports "*"
    string        field_name,// the lookup key
    T             value      // the data being stored
);

// GET
bit found = uvm_config_db#(T)::get(
    uvm_component cntxt,     // usually `this`
    string        inst_name, // usually ""
    string        field_name,// must match the SET's field_name
    ref T         value      // out-arg
);
```

`get` returns 0 on miss — **always check the return** or you use an
uninitialised handle silently. The non-negotiable pattern in
`build_phase`:

```systemverilog
if (!uvm_config_db#(virtual tinyalu_bfm)::get(this, "", "bfm", bfm))
    `uvm_fatal("NOVIF", "bfm not set in config_db")
```

### Decoding `uvm_config_db#(virtual tinyalu_bfm)::set(null, "*", "bfm", bfm);`

| Arg | Value | Meaning |
|---|---|---|
| `cntxt` | `null` | no context component; treat `inst_name` as absolute path |
| `inst_name` | `"*"` | wildcard — match every hierarchical path |
| `field_name` | `"bfm"` | the lookup key components will GET by |
| `value` | `bfm` | the virtual interface handle from the top module |

Combined effect: the BFM handle is reachable from anywhere in the
UVM hierarchy under the field name `"bfm"`.

### Why config_db instead of ch.10's constructor passing

In ch.10, the testbench passed the BFM into each child's
constructor. In UVM, you SET it once at the top and every component
GETs it where needed. Three wins:

- **Decoupling** — no threading through five layers.
- **Per-instance overrides** — different agents can get different
  BFMs (multi-protocol envs).
- **Test-time config** — tests change what components see without
  touching env/agent code.

### Corrections — first ch.11 paraphrase (2026-05-06)

- I called `uvm_config_db` a "global variable." Wrong abstraction.
  It's a **hierarchically-scoped key/value store** with wildcard
  matching — that scoping is exactly what makes per-instance
  overrides possible. Don't import "global variable" intuitions.

### `run_test()` and the factory (p.~70)

The flow:

1. `top.initial` calls `run_test()`.
2. `run_test()` reads the `+UVM_TESTNAME=<class_name>` plusarg from
   the simulator command line.
3. `run_test()` asks the **factory** to create an instance of that
   class by string name — the same factory pattern from ch.9, but
   string-keyed and macro-registered instead of hand-rolled `case`.
4. The phase machine kicks in: `build_phase → connect_phase →
   end_of_elaboration_phase → start_of_simulation_phase → run_phase
   → extract_phase → check_phase → report_phase → final_phase`.
5. `run_phase` blocks until all objections drop.

### Factory registration via `uvm_component_utils`

For `run_test()` to find a test class, the class must be registered
with the factory. One macro:

```systemverilog
class my_test extends uvm_test;
    `uvm_component_utils(my_test)    // adds my_test to factory string registry
    ...
endclass
```

Same machinery as ch.9's animal factory:
- ch.9: hand-rolled `case (spe) LION: new lion(); ...`
- UVM: string-keyed associative array, macro-registered, looked up via `+UVM_TESTNAME`

The macros hide the plumbing; the underlying mechanism is identical.

### Corrections — second ch.11 paraphrase (2026-05-06)

- I said `run_test()` "instantiates the object of the test" without
  naming the mechanism. The mechanism is the **UVM factory** (ch.9
  pattern in disguise) — `create_object_by_name(<string>)`. The
  factory is what makes string-driven test selection possible.
- `\`uvm_component_utils(<class>)` is the registration step that
  makes a class findable by the factory. Without it, the factory
  doesn't know your class exists and `run_test()` fails to find it.

### Standard `uvm_test` skeleton

```systemverilog
class random_test extends uvm_test;
    `uvm_component_utils(random_test)

    virtual tinyalu_bfm bfm;

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual tinyalu_bfm)::get(this, "", "bfm", bfm))
            `uvm_fatal("NOVIF", "Failed to get BFM from config_db")
    endfunction : build_phase

endclass : random_test
```

Five rules in this skeleton:

1. **`virtual tinyalu_bfm bfm;`** — the `interface` keyword is
   redundant; canonical is `virtual <iface_name> <handle>`.
2. **`parent = null` default** — required so the factory can call
   `new` with no parent (top-level test has no parent).
3. **`new()` does only `super.new(...)`** — no real work. Real work
   goes in `build_phase`.
4. **Config_db `get` goes in `build_phase`, not `new`** — UVM's
   phase machine guarantees `set` happens before `build_phase`. If
   you `get` in `new`, you race the phase ordering.
5. **`\`uvm_fatal` not `$fatal`** — UVM-native macro routes through
   the reporting infrastructure (severity counters, verbosity); the
   SV `$fatal` system task bypasses all of that.

### `get` patterns

| Pattern | Meaning |
|---|---|
| `get(this, "", "bfm", bfm)` | "from my own scope, look up `bfm`" — most explicit, recommended |
| `get(null, "*", "bfm", bfm)` | "search the whole hierarchy" — works but less precise |

### Corrections — third ch.11 paraphrase (2026-05-06)

- I said we "override the `new` function." Constructors aren't
  virtual in SV; you **implement** a constructor for the subclass
  that delegates to `super.new`. "Override" implies polymorphic
  dispatch, which doesn't apply to constructors.
- I put the `uvm_config_db::get` call inside `new()`. Wrong phase.
  The config_db lookup belongs in **`build_phase`** because UVM's
  phase machine is designed to guarantee all `set` calls happen
  before any component's `build_phase` runs.
- I used `$fatal` instead of `` `uvm_fatal ``. The macro is UVM-
  aware; the system task is not.
- I wrote `virtual interface tinyalu_bfm bfm;` — the `interface`
  keyword is redundant. Canonical: `virtual tinyalu_bfm bfm;`.
- I omitted the `= null` default on the `parent` argument, which
  breaks the standard factory creation pattern.

