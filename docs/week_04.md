# Week 4: UVM Architecture & Components

## Why This Matters

UVM (Universal Verification Methodology) is the industry standard. Every DV
job listing in Israel mentions UVM. This week you internalize **the
architecture** — the factory pattern, uvm_test, uvm_components, and uvm_env.
You won't touch sequences, TLM, or transactions yet — those come in weeks 5
and 6. The scope is deliberately narrow so each concept clicks fully.

## What to Study (Salemi ch.9-14 only)

This week's reading is **the first half of UVM**: building the static
hierarchy. Sequences, TLM, and transactions wait for weeks 5-6.

### Reading — Verification

- **Salemi *The UVM Primer***:
  - **ch.9 The Factory Pattern** ⭐ — core abstraction; `\`uvm_object_utils`, `type_id::create`, `set_type_override`
  - **ch.10 An Object-Oriented Testbench** — pre-UVM bridge: tester + scoreboard + coverage classes
  - **ch.11 UVM Tests** ⭐ — `uvm_test`, `run_test()`, `+UVM_TESTNAME` plusarg
  - **ch.12 UVM Components** ⭐ — class lineage, the 9 phases, reporting macros
  - **ch.13 UVM Environments** ⭐ — `uvm_env`, abstract base class + factory override pattern
  - **ch.14 A New Paradigm** — short philosophical wrap-up; what UVM gives you over plain OOP
- **Verification Academy**: "UVM Basics" course — start from lesson 1
- **ChipVerify**: [uvm-introduction](https://www.chipverify.com/uvm/uvm-introduction), [uvm-testbench-architecture](https://www.chipverify.com/uvm/uvm-testbench-architecture), [uvm-component](https://www.chipverify.com/uvm/uvm-component), [uvm-factory](https://www.chipverify.com/uvm/uvm-factory)
- **Cheatsheet** (your repo): [cheatsheets/salemi_uvm_ch9-13.sv](../cheatsheets/salemi_uvm_ch9-13.sv)
- **Consolidation PDF** (your repo): [docs/uvm_consolidation_salemi_ch9-15.pdf](uvm_consolidation_salemi_ch9-15.pdf)

### Reading — Design

- **Dally & Harting ch.10** — Arithmetic Circuits: ripple-carry adder, subtractor, comparator, multipliers (shift-add)
- **Dally & Harting ch.12** — Fast Arithmetic: carry-lookahead adders, Wallace trees, barrel shifters
- **Dally & Harting ch.13** — Arithmetic Examples (worked designs)
- **Sutherland *SystemVerilog for Design* ch.4-5** — SV interfaces, modports, clocking blocks
- **Cliff Cummings** *"Synthesis Coding Styles for Efficient Designs"*
- **Cheatsheet**: [cheatsheets/spear_ch4_interfaces.sv](../cheatsheets/spear_ch4_interfaces.sv)

### Tool Setup

- **Vivado xsim (Docker)** — your existing setup. UVM-capable with `-L uvm`.
- **EDA Playground** — fallback for any UVM weirdness.
- **Run helpers**: `xvlog_lint.sh`, `run_xsim.sh`

---

## Verification Homework

### Per-chapter (small focused exercises — one per Salemi chapter)

Each per-chapter HW is **10-30 lines** of code. Goal: feel each concept
under your fingers, isolated from the others.

- **HW ch.9 — Factory pattern**
  *File:* `homework/verif/per_chapter/hw_ch09_factory_pattern/factory_demo.sv`
  Recreate the animal/lion/chicken example from Salemi ch.9. Register two
  classes with `\`uvm_object_utils`, instantiate via `type_id::create`,
  demonstrate one `set_type_override`. No UVM components yet — just the
  factory mechanism.

- **HW ch.10 — Object-Oriented Testbench (no UVM)**
  *File:* `homework/verif/per_chapter/hw_ch10_oo_testbench/oo_tb_demo.sv`
  Build a non-UVM testbench: a `testbench` class composing a `tester` +
  `scoreboard`, all communicating via direct method calls. Use
  `fork/join_none`. Pure SV classes, no UVM imports. The point is to feel
  the pattern UVM later standardizes.

- **HW ch.11 — UVM Tests**
  *File:* `homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv`
  Write a minimal `uvm_test` that prints `"Hello UVM"` in `run_phase`. Run
  with `+UVM_TESTNAME=my_test`. No env, no components — just `top` calling
  `run_test()`.

- **HW ch.12 — UVM Components**
  *File:* `homework/verif/per_chapter/hw_ch12_uvm_components/phases_demo.sv`
  Write a `uvm_component` subclass that prints a labeled message in
  `build_phase`, `connect_phase`, `run_phase`, and `report_phase`. Build
  it inside a `uvm_test`. Observe the phase order in the log.

- **HW ch.13 — UVM Environments**
  *File:* `homework/verif/per_chapter/hw_ch13_uvm_environments/env_demo.sv`
  Write a `uvm_env` that builds 2-3 `uvm_component` children. Print the
  topology with `uvm_top.print_topology()` in `start_of_simulation_phase`.

- **HW ch.14 — A New Paradigm (reflective)**
  *File:* `homework/verif/per_chapter/hw_ch14_new_paradigm/NOTES.md`
  Write a half-page reflection: *what does UVM give you that plain SV
  classes don't?* Mention factory, phases, hierarchical naming, and
  reusability. No code.

### Connector — tie all 6 chapters together

- **Connector HW — Salemi-ch.13-style UVM testbench (no sequences)**
  *Folder:* `homework/verif/connector/`
  Build a complete UVM testbench for the ALU DUT (from your design HW)
  using ONLY ch.9-14 concepts:
    - `uvm_test` → `uvm_env` → abstract `base_tester` + `scoreboard` +
      `coverage` (all `uvm_component` subclasses)
    - Stimulus generated **inside the tester component** (no sequences,
      no TLM, no analysis ports — those are weeks 5-6)
    - Two concrete tester classes (e.g., `random_tester`, `directed_tester`)
    - The test installs `set_type_override` to swap testers
  Goal: prove you can build the static UVM hierarchy end-to-end.

### Big picture — stretch within scope

- **Big-picture HW — Architecture diagram from memory** (already done ✅)
  *Folder:* `homework/verif/big_picture/architecture_diagram/`
  Drew the canonical UVM architecture from memory, exported as PNG.

- **Big-picture HW — Factory override demo**
  *Folder:* `homework/verif/big_picture/factory_override_demo/`
  Standalone factory-override exercise (decoupled from the connector HW).
  A `slow_driver` and `fast_driver`; the test picks one via override.
  Salemi-style minimal example to drill the override mechanic.

---

## Design Homework

Same per-chapter / connector / big-picture format applied to RTL design.

### Per-chapter

- **HW Dally ch.10 — Ripple-carry adder**
  *Folder:* `homework/design/per_chapter/hw_dally_ch10_arithmetic_basics/`
  Build a parameterized ripple-carry adder + simple TB.

- **HW Dally ch.12 — Carry-lookahead adder**
  *Folder:* `homework/design/per_chapter/hw_dally_ch12_fast_arithmetic/`
  Build a 4-bit CLA adder. Compare gate count and critical-path delay
  vs ripple-carry (paper analysis).

- **HW Sutherland ch.4 — SV interface for the ALU**
  *Folder:* `homework/design/per_chapter/hw_sutherland_ch4_interfaces/`
  Write the `alu_if` interface with modports (`dut`, `tb`, `monitor`) and
  a clocking block. (You've practiced this in `spear_and_tumbush/ch4/ex1`
  — apply it to the ALU specifically.)

### Connector — combines arithmetic + interface

- **Connector HW — ALU DUT**
  *Folder:* `homework/design/connector/`
  Build a parameterized ALU with registered outputs (1-cycle latency),
  valid handshake, ops: ADD, SUB, AND, OR, XOR. Wire it through the
  interface from the per-chapter HW. Sanity TB to drive a few transactions.

### Big picture — stretch within scope

- **Big-picture HW — Sequential shift-add multiplier**
  *Folder:* `homework/design/big_picture/shift_add_multiplier/`
  Multi-cycle multiplier with FSM (IDLE → COMPUTE → DONE). Test corner
  cases. Bonus: Booth's algorithm for signed.

- **Big-picture HW — Barrel shifter**
  *Folder:* `homework/design/big_picture/barrel_shifter/`
  Single-cycle barrel shifter using cascaded MUX layers. Supports
  SLL/SRL/SRA. Test with various shift amounts.

---

## Self-Check Questions

After all reading + HW, you should be able to answer these without looking:

1. What's the difference between `uvm_object` and `uvm_component`?
2. Why use `type_id::create()` instead of `new()`?
3. What are the 9 UVM phases and in what order do they execute?
4. What's the difference between an active agent and a passive agent?
5. What does `uvm_config_db` do? (preview for week 5)
6. Why is the abstract-base-class + factory-override pattern useful?
   (Hint: same env, multiple stimulus styles, picked at runtime.)

---

## Checklist

### Verification Track
- [ ] Read Salemi *UVM Primer* ch.9 (factory)
- [ ] Read Salemi *UVM Primer* ch.10 (OO testbench)
- [ ] Read Salemi *UVM Primer* ch.11 (uvm_test)
- [ ] Read Salemi *UVM Primer* ch.12 (uvm_components)
- [ ] Read Salemi *UVM Primer* ch.13 (uvm_environments)
- [ ] Read Salemi *UVM Primer* ch.14 (a new paradigm)
- [ ] Watched Verification Academy UVM Basics
- [ ] Read ChipVerify UVM intro / architecture / component / factory pages
- [ ] Per-chapter HW ch.9 (factory pattern)
- [ ] Per-chapter HW ch.10 (OO testbench)
- [ ] Per-chapter HW ch.11 (uvm_test)
- [ ] Per-chapter HW ch.12 (uvm_components)
- [ ] Per-chapter HW ch.13 (uvm_environments)
- [ ] Per-chapter HW ch.14 (reflection)
- [ ] Connector HW (Salemi-ch.13-style TB, no sequences)
- [x] Big-picture HW: architecture diagram from memory
- [ ] Big-picture HW: factory override demo
- [ ] Can answer all self-check questions

### Design Track
- [ ] Read Dally ch.10 (arithmetic circuits)
- [ ] Read Dally ch.12 (fast arithmetic)
- [ ] Read Sutherland ch.4-5 (SV interfaces, modports, clocking)
- [ ] Per-chapter HW: ripple-carry adder
- [ ] Per-chapter HW: carry-lookahead adder + comparison
- [ ] Per-chapter HW: ALU SV interface
- [ ] Connector HW: ALU DUT (registered, valid handshake)
- [ ] Big-picture HW: shift-add multiplier
- [ ] Big-picture HW: barrel shifter
