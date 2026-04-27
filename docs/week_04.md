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
- [ ] Read Dally ch.10 (arithmetic circuits)
- [ ] Read Dally ch.12 (fast arithmetic)
- [ ] Read Sutherland *SV for Design* ch.10 (interfaces)
- [ ] Drill Dally ch.10 (ripple-carry adder)
- [ ] Drill Dally ch.12 (carry-lookahead adder)
- [ ] Drill Sutherland ch.10 (ALU SV interface)
- [ ] HW1: ALU DUT (registered, valid handshake)
- [ ] HW2: shift-add multiplier
- [ ] HW3: barrel shifter
