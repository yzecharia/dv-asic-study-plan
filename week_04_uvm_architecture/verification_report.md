# Week 4 — Verification Report

**Block under verification**: `alu` (8-bit registered ALU with valid
handshake) at `week_04_uvm_architecture/homework/verif/connector/alu.sv`
(reuse of Design HW1).

**Testbench**: connector UVM TB at
`week_04_uvm_architecture/homework/verif/connector/`. Architecture
follows Salemi ch.13 — abstract `alu_base_tester` + factory override,
no sequences, no TLM, no analysis ports (those land in W5).

```
alu_random_test                            alu_directed_test
        \                                          /
         \                                        /
          alu_base_tester::type_id::set_type_override(...)
                              |
                              v
                  alu_env (uvm_env)
                  ├── alu_base_tester  (overridden -> random | directed)
                  ├── alu_scoreboard   (virtual alu_if, monitor_cb)
                  └── alu_coverage     (virtual alu_if, monitor_cb)
```

## What was verified

- **Functional**: ADD / SUB / AND / OR / XOR across 1000 random
  transactions (`alu_random_test`) and 1000 ADD-only transactions
  (`alu_directed_test`). Scoreboard recomputes the expected value from
  the sampled operands at the same `monitor_cb` edge that captures
  `result` / `valid_out` and flags any mismatch with `\`uvm_error`.
- **Handshake**: every drive uses the `valid_in -> valid_out` 1-cycle
  registered protocol. The driver waits for `valid_out` via
  `@(driver_cb iff driver_cb.valid_out)` between transactions, so a
  dropped or never-asserted `valid_out` would manifest as a UVM
  objection timeout, not as a silent miscompare.
- **Coverage**: `cg_alu` covers
  - `cp_op` (5 bins: ADD..XOR),
  - `cp_operand_a` (3 corner bins: zero / ones / mid),
  - `cp_operand_b` (3 corner bins),
  - `cross_op_opera_operb` with `[mid,mid]` rows ignored.
- **Reset behaviour**: stimulus is gated on `wait(rst_n === 1)` so the
  pre-reset window is no-op; the scoreboard / coverage only fire on
  `iff valid_out` so they cannot sample garbage during reset.

## Results

| Test                | Txns | UVM_ERROR | UVM_FATAL | cg_alu inst cov | Log |
|---------------------|------|-----------|-----------|------------------|-----|
| `alu_random_test`   | 1000 | 0         | 0         | **100.00 %**     | `sim/connector_alu_random_pass.log` |
| `alu_directed_test` | 1000 | 0         | 0         | **60.00 %**      | `sim/connector_alu_directed_pass.log` |

Banner line `ALU_TB PASS  cov=<x>%` is emitted from
`alu_env::report_phase`, gated on `UVM_ERROR + UVM_FATAL == 0`, so the
PASS line is deterministic and grepable from the log.

The 60 % on the directed run is expected and the *correct* signal: the
directed tester only issues ADD, so `cp_op` saturates 1 / 5 bins and
the relevant cross slice fills accordingly. This confirms the override
is actually flipping behaviour at the leaf — not a miscompiled
plus-arg.

## Holes / known limitations

- **Reset coverage**: only one reset event (cold reset at t=0). No
  mid-test reset is exercised. Acceptable for ch.9–14 scope, must be
  added when sequences land in W5.
- **No SVA**: protocol assertions on `valid_in / valid_out` would catch
  pulse-width and ordering bugs the scoreboard cannot. Owed for W5.
- **Coverage closure**: the cross with `[mid,mid]` ignored is a
  **declared** hole — there is real arithmetic state in
  `(mid op mid)` (e.g. carry out, overflow on signed interpretation)
  that is not being checked. ADD-only directed test does not lift
  this, by design. Either drop the ignore-bin or add a directed test
  that walks specific mid×mid pairs.
- **No randomisation seed control**: tests rely on default `$urandom`
  seeding. Reproducibility for triage requires `-sv_seed <N>`; not
  wired into a regression script yet.
- **No `\`uvm_info` chatter from the driver**: passing log is silent
  apart from the PASS banner. Fine for passing runs, weak for
  debugging — would add per-transaction `UVM_HIGH` prints before W5.

## Self-critique on the design

The DUT is correct under this stimulus, but not robust:

1. **`result` is not reset-cleared between transactions**. After
   `valid_out` deasserts, `result` lingers at the last computed value
   on the bus. Cosmetic on this DUT, but a real bus would want
   `result` driven `'0` (or `'X` in sim) outside `valid_out` to flag
   misuse downstream.
2. **The `default` arm of the op `case` collapses both `op_valid` and
   `result_reg` to zero via `{op_valid, result_reg} = '0;`**. Cute,
   but it depends on the relative bit ordering of the LHS
   concatenation — a future engineer adding a flag to the LHS is
   walking into a bug. Prefer two explicit assignments.
3. **`operand_a` / `operand_b` are zero-extended into a `WIDTH+1`
   adder and the same path is used for AND / OR / XOR**. The
   bit-extension on bitwise ops costs nothing here but obscures intent;
   a clean ALU would route bitwise ops through a separate `WIDTH`-wide
   path and zero-extend only the result.
4. **No SUB underflow / signedness hint**. SUB of e.g. `8'h00 - 8'h01`
   produces `9'h1FF`, which the scoreboard accepts as the natural
   wrap. That matches the spec but the spec itself is silent on
   signed vs unsigned — the DUT and TB would diverge the moment a
   downstream consumer interprets the result as signed.

None of these block the connector deliverable; all are flagged for the
W7 full-environment rebuild.

## Bug log (this iteration)

| # | Symptom                                         | Root cause                                                                                | Fix                                                                                                |
|---|-------------------------------------------------|-------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| 1 | `xsim` ran past `[RNTST]` and hung; no PASS, no `$finish`. | `alu_base_tester::run_phase` started driving at `t=0` while `rst_n=0`. The first `valid_in` pulse landed inside the reset window; DUT never registered it; `@(driver_cb iff valid_out)` blocked forever. | Added `wait (aluif.rst_n === 1'b1); @(aluif.driver_cb);` between `raise_objection` and the `repeat` loop. New concept note: `docs/concepts/uvm_reset_synchronisation.md`. |
| 2 | No deterministic PASS / FAIL line in the run log; user had to read the report-server severity table to confirm. | Env never printed an end-of-test banner.                                              | Added `alu_env::report_phase` that queries `uvm_report_server` and prints `ALU_TB PASS cov=...%` or `ALU_TB FAIL errors=N`. |

## Run commands

```bash
cd week_04_uvm_architecture/homework/verif/connector

# compile once
../../../../run_xsim_uvm_compile.sh alu.sv alu_if.sv alu_pkg.sv alu_tb_top.sv

# run each test against the same snapshot
../../../../run_xsim_uvm_test.sh alu_random_test
../../../../run_xsim_uvm_test.sh alu_directed_test
```

Logs land in `week_04_uvm_architecture/sim/connector_alu_*.log`.
