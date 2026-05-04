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
