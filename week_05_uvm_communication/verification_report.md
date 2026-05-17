# Week 5 — Verification Report

Per-drill verification artifacts for Salemi *UVM Primer* ch.15–19. Each
chapter's drill — and each connector HW (HW1, HW2) — gets its own
section as it lands. The W5 anchor in
chapter 15 is the dice-roller — first introduction to
`uvm_analysis_port` + `uvm_subscriber` (Observer pattern). No real DUT;
the "DUT" is the analysis fan-out itself.

---

## ch.15 — Dice-roller analysis port

**Block under verification**: the analysis-port broadcast topology.
Producer is `dice_roller` (a `uvm_component` with `rand bit [3:0]
die1, die2;` constrained `inside {[1:6]}`). The producer holds a
`uvm_analysis_port #(int)` and writes the sum on every roll. Three
`uvm_subscriber #(int)` consumers (`average`, `coverage_mon`,
`histogram`) wire to the port via `connect_phase`.

**Testbench**: `week_05_uvm_communication/homework/verif/per_chapter/hw_ch15_tlm_basics/`
— flat package (`dice_pkg`) including all six classes plus a `top.sv`
that calls `run_test()`.

```
                          ┌─→ average        (running sum + count → mean)
   dice_roller            │
   ap (uvm_analysis_port#int)
                          ├─→ coverage_mon   (cg_dice / cp_sum bins[2:12])
                          │
                          └─→ histogram      (int roles[int] — assoc array)
```

### What was verified

- **Analysis-port fan-out**: a single `ap.write(sum)` synchronously
  invokes all three subscribers' `write()` callbacks in connect order.
  Verified by the matched sample counts across all three subscribers:
  `average.count = coverage hits = histogram total = 20`.
- **Subscriber type-strictness**: the `uvm_analysis_port #(int)`
  parameter and the `uvm_subscriber #(int)` parameter are bound at
  compile time. A mismatched parameter would have been caught by xelab
  before run time; clean elaboration confirms the contract held.
- **Constrained randomisation**: 20 rolls of 2d6 with constraint
  `dieN inside {[1:6]}`. Sums observed within `[2:12]`. No
  out-of-range writes (verified by `histogram.roles[int]` having no
  keys outside 2–12).
- **Coverage sampling**: `cg_dice.cp_sum` covers each integer 2–12
  via `bins sum[] = {[2:12]}` (auto-array form: 11 individual bins).
  `roll_val` is updated **before** `cg_dice.sample()`, avoiding the
  stale-class-field trap documented in
  `docs/concepts/covergroup_sampling.md`.
- **Reporting hygiene**: every subscriber emits a single `\`uvm_info`
  in `report_phase`, building multi-line output via `$sformatf` +
  `\n` so the UVM header doesn't fragment the histogram.

### Results

| Test        | Txns | UVM_ERROR | UVM_FATAL | `cg_dice` inst cov | Mean roll | Log |
|-------------|------|-----------|-----------|--------------------|-----------|-----|
| `dice_test` | 20   | 0         | 0         | **63.64 %**        | **7.65**  | `sim/dice_test_pass.log` |

Pass criterion: `UVM_ERROR + UVM_FATAL == 0` and the histogram
demonstrates a multi-bin distribution (not collapsed to one value —
that's the failure mode the xsim bug below produced).

Theoretical mean of 2d6 is 7.0; observed 7.65 is within expected
variance for N=20 (σ_mean ≈ 2.4/√20 ≈ 0.54, so 7.65 is +1.2σ).

Histogram (from log):

```
 4: ## (2)     7: ##### (5)    10: ##### (5)
 5: ## (2)     8:    ## (2)    11:    ## (2)
 6: ## (2)
```

### Holes / known limitations

- **Bins 2, 3, 9, 12 not hit at N=20.** Sum=2 has probability 1/36
  (≈2.8%); expected miss rate at 20 samples is `(35/36)^20 ≈ 56%`.
  This is statistical, not a coverage gap. To close the bins, raise
  the loop to ~150 rolls or seed-vary across runs. **Not done** —
  the drill anchors on Salemi's 20-roll example for fidelity.
- **No null-handle defensive test.** The TB assumes `connect_phase`
  succeeded and `ap.write()` always finds the subscribers. A
  forgotten `connect()` call would silently produce no subscriber
  hits — caught only by the 20/20 sample-count cross-check, not by
  any explicit assertion.
- **No multi-instance cross-check.** With one `histogram_h` instance,
  `cg_dice.get_inst_coverage()` and `coverage_mon::get_coverage()`
  return identical numbers. The instance-vs-type distinction
  (covered in `docs/concepts/covergroup_query_api.md`) isn't
  exercised.
- **No `iff` qualifier.** Coverage samples on every `write()`
  unconditionally. A real protocol coverage subscriber would gate on
  `valid && !reset_n` etc. — out of scope here.

### Self-critique on the design

The drill matches Salemi ch.15 to the line, which was the right
priority for a textbook anchor. If I were writing this for a real
agent I'd reach for **Form C `with function sample(int roll)`** on
the covergroup so `coverage_mon` doesn't need the `int roll_val;`
class field — the field-update-before-sample pattern is a known
junior footgun. I'd also replace `int dice_total` with `longint` for
any sample count that could exceed 2^31 (overkill at 20 rolls, real
at 1M+), and prefer `longint counts[2:12]` over `int roles[int]` for
the histogram once the bin set is fixed and known: associative arrays
hide out-of-range writes that direct-indexed arrays would surface as
out-of-bounds errors.

### Bug log (this iteration)

- **xsim 2024.1 bug — bare `randomize()` no-op.** Spent ~1h debugging
  "all zeros" before isolating it: bare `randomize()` inside a
  `uvm_component` task method silently resolves to `std::randomize()`
  (no-op returning 1) instead of `this.randomize()` per IEEE
  1800-2017 §18.5. The `\`uvm_fatal` check passes meaninglessly. Fix
  is mandatory `this.` prefix at every call site. Documented in
  `docs/concepts/xsim_randomize_quirk.md` with diagnostic procedure
  and a project-wide grep recipe.
- **Stale-snapshot trap.** xsim runner's "(reusing existing snapshot)"
  message hid post-edit changes from the simulator twice during this
  drill. Added `♻️ UVM REBUILD` task in `.vscode/tasks.json`
  (chains clean → compile → run via `dependsOn`) so the from-scratch
  path is one click instead of three commands.
- **Trailing `;` after UVM macros.** Caught and removed after a strict
  parser would have flagged them inside if/else. Recorded in the
  Form B vs Form C covergroup discussion.

### Run commands

```bash
# clean + compile + run
cd week_05_uvm_communication/homework/verif/per_chapter/hw_ch15_tlm_basics
../../../../../run_xsim_clean.sh .
../../../../../run_xsim_uvm_compile_auto.sh top.sv
../../../../../run_xsim_uvm_test.sh dice_test

# or: VS Code → Tasks: Run Task → ♻️ UVM REBUILD
```

---

## HW1 — Analysis path on the ALU TB

**Block under verification**: the 4-operation ALU DUT from W4
(`OP_ADD`/`OP_AND`/`OP_XOR`/`OP_MUL`; single-issue, in-order;
ADD/AND/XOR single-cycle, MUL three-cycle). The W4 HW2 testbench is
refactored to the Salemi ch.16 analysis-path pattern — coverage and
scoreboard no longer peek at the BFM directly; they subscribe to
analysis ports.

**Testbench**: `homework/verif/connector/hw1_alu_analysis_path/` —
`alu_pkg` includes the `alu_classes/` hierarchy; `alu_if` carries the
BFM; `alu_tb_top` generates clk/reset and calls `run_test()`.

```
   base_tester ── bfm.send_op ──▶ DUT
                                   │  (BFM always blocks, edge-detected)
                       ┌───────────┴────────────┐
                command_monitor            result_monitor
                    │ ap (uvm_analysis_port)        │ ap
            ┌───────┴────────┐                      │
            ▼                ▼                      ▼
        coverage   scoreboard.cmd_fifo     scoreboard.analysis_export
                   (uvm_tlm_analysis_fifo)
```

### What was verified

- **DUT functional correctness** — `random_test` (1000 random
  commands) and `add_test` (1000 ADD commands). The scoreboard's
  `predict()` recomputes the expected result and compares against the
  DUT; every command matched.
- **Analysis-path fan-out** — `command_monitor`/`result_monitor`
  broadcast via `uvm_analysis_port`; `coverage` and `scoreboard`
  subscribe via `uvm_subscriber`. One `ap.write()` reaches every
  subscriber in connect order, in zero simulation time.
- **Two-input scoreboard pairing** — a result triggers `write()`; the
  matching command is pulled from a `uvm_tlm_analysis_fifo` with
  `try_get`. In-order single-issue means FIFO order == issue order;
  verified because no `try_get` ever returned a mismatch.
- **BFM edge detection** — the `new_command`/`new_result` one-shot
  latches fire exactly once per rising edge of `start`/`done`, even
  though `start` is held high across the 3-cycle MUL. A multi-fire bug
  would have stuffed phantom commands into the FIFO and the scoreboard
  would have errored — it did not.
- **Coverage** — `cg_alu`: `cp_op`, `cp_a`, `cp_b` (5 bins each),
  `cp_a_eq_b`, `cp_carry`, and `cross_op_a_b`.

### Results

| Test | Cmds | UVM_ERROR | UVM_FATAL | Scoreboard | `cg_alu` inst cov | Log |
|---|---|---|---|---|---|---|
| `random_test` | 1000 | 0 | 0 | **PASS 1000/1000** | **89.67 %** | `sim/hw1_alu_analysis_path_random_test_pass.log` |
| `add_test`    | 1000 | 0 | 0 | **PASS 1000/1000** | **73.50 %** | `sim/hw1_alu_analysis_path_add_test_pass.log` |

Pass criterion: `UVM_ERROR + UVM_FATAL == 0` and scoreboard `fail == 0`.

### Holes / known limitations

- **`cross_op_a_b` not closed** — 4×5×5 = 100 cross bins; 1000 random
  commands leave ~10 % unhit. Random stimulus cannot saturate the
  corner cross-bins — closing them needs directed stimulus, not more
  iterations.
- **`add_test` 73.50 % is expected-lower** — ADD-only stimulus
  collapses `cp_op` to one of four bins and the cross to a quarter.
  Not a gap; the number is correct for the stimulus.
- **Reset exercised once** — asserted at time 0, never re-applied
  mid-traffic. No reset-recovery test.
- **No illegal-stimulus test** — the tester always honours the
  wait-for-`done` contract; a `start`-during-busy case is never
  driven, so the DUT's command-drop behaviour is unverified.
- **In-order assumption is implicit** — the scoreboard's FIFO pairing
  assumes single-issue order; correct for this DUT, but guarded by a
  comment, not an assertion.

### Self-critique on the design

The refactor cleanly stratifies the testbench: the BFM owns the
protocol, monitors are dumb broadcasters, subscribers are leaf
consumers — each layer has exactly one job. The weak spot is coverage
signoff: 89.67 % with a large cross that random stimulus structurally
cannot close. A real signoff adds constrained/directed stimulus aimed
at the unhit cross-bins, or trims the cross to the bins that carry
verification value. The scoreboard's reliance on FIFO order should be
an explicit SVA assertion, not a comment.

### Bug log (HW1)

Four traps, all silent-failure class — the code compiles and runs and
produces wrong results without raising an error:

- **BFM latch lifetime** — `new_command` declared inside the `always`
  block gets automatic lifetime on some simulators, re-zeroing every
  activation; the edge detector never holds. Moved to interface scope
  (static). → `docs/concepts/bfm_edge_detector.md`
- **`cp_carry` width truncation** — `cmd.a + cmd.b > 8'hFF` evaluates
  the `+` at 8-bit self-determined width; the carry is dropped *inside*
  the expression and the `carry` bin is unreachable. Fixed with
  `{1'b0, ...}` zero-extension to 9 bits.
  → `docs/concepts/sv_expression_width_context.md`
- **First-cycle X-propagation** — `logic start` defaults to `X`; `!X`
  is falsy, so the detector never arms and the first command vanishes.
  Fixed with `initial start = 1'b0;`.
- **NBA collision** — the tester driving `start <= 0` then
  `start <= 1` in one timestep loses the `0` (last write wins); the
  BFM never sees a falling edge. Fixed with a clocking-block wait
  between iterations.

Full implementation-session Q&A: `hw1_qa.md`.

### Run commands

```bash
UVM_TESTNAME=random_test ./xflow.sh sim \
  week_05_uvm_communication/homework/verif/connector/hw1_alu_analysis_path/alu_tb_top.sv
UVM_TESTNAME=add_test ./xflow.sh sim \
  week_05_uvm_communication/homework/verif/connector/hw1_alu_analysis_path/alu_tb_top.sv
```

---

## HW2 — Tester/driver split (ch.18)

**Block under verification**: the same ALU DUT, re-verified through the
Salemi ch.18 architecture. HW1's analysis path is retained unchanged;
the monolithic tester is split into a stimulus-only `base_tester`
(generates `command_t`, `put`s into a `uvm_tlm_fifo`) and a `driver`
(`get`s commands, calls the BFM `send_op` task).

**Testbench**: `homework/verif/per_chapter/hw_ch18_put_get/`

```
 random_tester / add_tester                            driver
   uvm_put_port ─put─▶ uvm_tlm_fifo #(command_t) ─get─▶ uvm_get_port
                          (env, depth 1)                   │ aluif.send_op
                                                           ▼
                                                          DUT
                                          ┌─ BFM always blocks (HW1 path) ─┐
                                   command_monitor                  result_monitor
                                          ↓                                ↓
                                coverage / scoreboard.cmd_f            scoreboard
```

### What was verified

- **The ch.18 stimulus split** — the tester is now purely
  transactional: no virtual interface, no clock awareness. The driver
  owns the vif and all protocol timing. Both tests passing with the
  split in place confirms the `send_op` BFM task and the put/get
  plumbing are correct.
- **Interthread transfer via `uvm_tlm_fifo`** — the tester `put`s, the
  driver `get`s; the depth-1 fifo backpressures the tester so stimulus
  is generated eagerly but applied at DUT pace. No command is lost or
  duplicated — the scoreboard would catch either.
- **Factory override path** — `random_test` runs the env-default
  `random_tester`; `add_test` installs `random_tester → add_tester`.
  Override correctness was confirmed *by the coverage delta* (see Bug
  log).
- **Reset ownership** — the driver waits `@(cb iff cb.reset_n)` before
  its `forever get` loop; the tester is reset-agnostic, exactly as a
  transactional component should be.
- **DUT correctness at scale** — 10000 random + 10000 ADD commands,
  scoreboard 10000/10000 PASS on each run.

### Results

| Test | Cmds | UVM_ERROR | UVM_FATAL | Scoreboard | `cg_alu` inst cov | Log |
|---|---|---|---|---|---|---|
| `random_test` | 10000 | 0 | 0 | **PASS 10000/10000** | **94.50 %** | `sim/hw_ch18_put_get_random_test_pass.log` |
| `add_test`    | 10000 | 0 | 0 | **PASS 10000/10000** | **74.33 %** | `sim/hw_ch18_put_get_add_test_pass.log` |

### Holes / known limitations

- **`cross_op_a_b` still not closed** — 94.50 % at 10000 random
  commands. The 5.5 % gap is the same un-closable corner cross-bins as
  HW1; ten-times-more random stimulus does not close them.
- **`add_test` 74.33 %** — correct for ADD-only stimulus (`cp_op` at
  25 %, cross at ~¼). This number is the *evidence* that the factory
  override fires.
- **Stimulus fifo depth fixed at 1** — strict ping-pong
  tester↔driver. A deeper fifo allowing real tester run-ahead is not
  exercised.
- **Single reset** — same as HW1; no mid-test reset.

### Self-critique on the design

The tester/driver split is the right abstraction — `uvm_tlm_fifo`
decouples *what stimulus* from *how it is applied*, which is exactly
what `uvm_sequence`/`uvm_sequencer` formalise later. But the headline
94.50 % (vs HW1's 89.67 %) is **not better verification — it is a
longer run**: same covergroup, same un-closable cross, ten-times the
random samples. Honest signoff is directed stimulus for the cross
corners, not more iterations. The sharper lesson is the `add_test`
override bug: a test that passes 10000/10000 while silently exercising
the wrong stimulus — the *only* tell was coverage. Pass count proves
the DUT did not break; coverage proves *what was actually tested*.
They are not interchangeable.

### Bug log (HW2)

- **Pure-virtual syntax** — `pure virtual <type> function name()` is
  wrong; the `function` keyword precedes the return type.
  → `docs/concepts/uvm_tester_component.md`
- **Null `uvm_tlm_fifo` handles** — `env.cmd_f` and `scoreboard.cmd_f`
  were declared but never constructed; `connect_phase` dereferenced
  null and crashed the xsim kernel at time 0. Fixed with
  `new("cmd_f", this)` in each `build_phase`.
  → `docs/concepts/uvm_put_get_tlm_fifo.md`
- **Factory override mistargeted** — `add_test` overrode `base_tester`,
  but `env` creates `random_tester`; the override never fired and
  `add_test` silently ran random stimulus. Identical 94.50 % coverage
  was the tell. Fixed by overriding `random_tester`.
  → `docs/concepts/uvm_factory_config_db.md`
- **Stale `xsim.dir`** — "Failed to compile generated C file" from a
  leftover snapshot; a clean rebuild resolves it.
- **`xflow.sh` `.svh` regression (HW1 collateral)** — the
  Salemi-convention fix (skip non-package `.svh` from standalone
  compile) broke HW1, whose interface was `alu_if.svh`. Resolved by
  renaming HW1's interface to `alu_if.sv` — `.sv` = compilation unit,
  `.svh` = include-only.

### Run commands

```bash
UVM_TESTNAME=random_test ./xflow.sh sim \
  week_05_uvm_communication/homework/verif/per_chapter/hw_ch18_put_get/alu_tb_top.sv
UVM_TESTNAME=add_test ./xflow.sh sim \
  week_05_uvm_communication/homework/verif/per_chapter/hw_ch18_put_get/alu_tb_top.sv
```
