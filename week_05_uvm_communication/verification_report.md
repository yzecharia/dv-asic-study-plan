# Week 5 — Verification Report

Per-drill verification artifacts for Salemi *UVM Primer* ch.15–19. Each
chapter's drill gets its own section as it lands. The W5 anchor in
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
