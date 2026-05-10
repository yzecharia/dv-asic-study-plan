# Vivado xsim Quirk — Bare `randomize()` Silently Calls `std::randomize()`

**Category**: Toolchain · **Used in**: every UVM week using xsim where a `uvm_component` or `uvm_object` calls `randomize()` (W4–W7, W12, W14, W17, W18, W20) · **Type**: authored

Vivado xsim 2024.1 has a parser conformance bug: a bare `randomize()` call inside a class method does **not** resolve to `this.randomize()` as IEEE 1800-2017 §18.5 mandates. Instead, xsim resolves it to the global `std::randomize()` — a no-op that returns `1` without touching any class fields. The result is silent, deterministic, hours-eating: your test runs, no fatal fires, every random field stays at its initial value (typically 0), and your stimulus is degenerate. This note documents the failure mode, the workaround, and the diagnostic procedure that surfaces it in five minutes instead of half a day.

## The failure signature

```systemverilog
class dice_roller extends uvm_component;
    rand bit [3:0] die1, die2;
    constraint c_face { die1 inside {[1:6]}; die2 inside {[1:6]}; }

    task run_phase(uvm_phase phase);
        repeat (20) begin
            if (!randomize()) `uvm_fatal("RAND", "randomize failed")   // ← xsim bug
            ap.write(die1 + die2);
        end
    endtask
endclass
```

**On any conformant simulator (VCS, Questa, Xcelium):** prints 20 sums in `[2:12]`. Histogram is bell-shaped.

**On xsim 2024.1:** prints 20 zeros. No `\`uvm_fatal` fires. Coverage is 0 %. Histogram is "20 hits in bin 0".

The defect is silent — exit code 0, no warnings, no error messages. The only signal is degenerate output values.

## Why it happens

Per IEEE 1800-2017 §18.5, when `randomize()` appears unqualified inside a class method:

1. The compiler first searches for a class-scoped `randomize` virtual method.
2. Every class transitively derived from `uvm_object` / `uvm_component` inherits one (the SystemVerilog-generated solver invocation).
3. Bare `randomize()` MUST therefore resolve to `this.randomize()`.

xsim 2024.1 skips step 2 in this codepath and falls through to **`std::randomize()`** — the standalone form that takes a list of variables and randomises them via inline constraints. With no argument list, `std::randomize()` is effectively a no-op: it returns 1 without doing anything observable.

The result: `if (!randomize())` evaluates to `if (!1)` → `if (0)` → `\`uvm_fatal` never fires. The class's `rand` fields are never solved. They keep whatever value they had — usually the implicit `0`-initialisation from class construction.

## The workaround — always use `this.` explicitly

```systemverilog
if (!this.randomize()) `uvm_fatal("RAND", "randomize failed")
```

The explicit `this.` forces xsim's parser into the class-scoped resolution path it should have taken automatically. With this prefix, the constraint solver fires, fields are randomised, and the fatal correctly triggers on actual solver failure.

Apply the same fix to **every** randomize call site — including `void'(this.randomize())`, `if (this.randomize() with { ... })`, and any helper functions that wrap randomization:

```systemverilog
// ✓ correct on xsim
if (!this.randomize() with { die1 == 6; }) `uvm_fatal("RAND", "...")
void'(this.randomize());
return this.randomize();

// ✗ silently no-ops on xsim 2024.1
if (!randomize() with { die1 == 6; }) `uvm_fatal("RAND", "...")
void'(randomize());
return randomize();
```

`std::randomize(var1, var2)` with explicit args is unaffected — that form is unambiguously the global function and works correctly. The bug only manifests with the no-argument form intended to mean `this.randomize()`.

## Diagnostic procedure — five minutes from "all zeros" to root cause

When stimulus collapses to a single value (all zeros, all default-init values, all the same constant) and **no `\`uvm_fatal` fires**:

1. **Add a debug print of the rand fields immediately after the randomize call.** If they're stuck at 0 / default, the solver didn't run.

   ```systemverilog
   bit ok;
   ok = this.randomize();
   `uvm_info("DBG", $sformatf("ok=%0d die1=%0d die2=%0d", ok, die1, die2), UVM_LOW)
   ```

2. **If `ok=1` but the fields are 0, you're hitting this bug.** The randomize call returned success but did nothing — that's the `std::randomize()` no-op signature.

3. **Add `this.` to the randomize call** and re-run. If output now varies in the constrained range, you've confirmed the diagnosis.

4. **Audit every other randomize call site in the touched code path** for the same pattern.

The bug never produces wrong values — only stuck values. If you see varied wrong values (e.g. die1=15), the bug is something else (constraint mismatch, type width, etc.).

## Why this is hard to spot without the workaround

Three things conspire to hide the bug from junior engineers:

- **The textbook examples work on Salemi's reference simulator** (he developed against Mentor/Cadence flows, where bare `randomize()` is fine). Your `dice_roller` looks identical to ch.15's; you assume your code is wrong, not the simulator.
- **The `if (!randomize()) `uvm_fatal` idiom** is meant to catch exactly this class of failure — but the bug bypasses the check by returning success.
- **Coverage and average reports show plausible numbers** (0 % coverage and 0.00 average aren't UVM errors — they're just the reports doing their job on stuck data).

You only catch this by either inspecting the rand-field values directly or noticing that the histogram landed entirely in one bin.

## Pitfalls (related forms that also misbehave)

| Form | xsim 2024.1 behaviour | Conformant simulator |
|---|---|---|
| `randomize()` | no-op, returns 1 | calls `this.randomize()` |
| `randomize() with { ... }` | inline constraints applied to **nothing** — no-op, returns 1 | applies to `this`'s rand fields |
| `void'(randomize())` | no-op, return discarded | calls `this.randomize()` |
| `assert(randomize())` | passes (`std::randomize()` returns 1) | conformant |
| `this.randomize()` | works | works |
| `obj.randomize()` (explicit handle) | works | works |
| `std::randomize(var1, var2) with { ... }` | works (intended use of global form) | works |

Anywhere your code reads bare `randomize(`, audit it.

## Cross-tool portability

The `this.` prefix is **never wrong** on a conformant simulator. Adding it as a project-wide convention has no downside other than two extra characters per call site. The CLAUDE.md / coding-standards rule for this repo is therefore: **always use `this.randomize()` explicitly**, and treat any bare `randomize()` review-comment-worthy.

If your project switches off xsim later (e.g. moves to Questa for regressions), the `this.` prefix remains correct and consumes no performance.

## Reading

- IEEE 1800-2017 §18.5 — *Randomize Methods*. Specifies bare `randomize()` resolution rules; xsim violates these.
- IEEE 1800-2017 §18.12 — *Random Number System Functions*. Describes `std::randomize()` and its argument forms.
- AMD/Xilinx UG900 — Vivado Logic Simulation User Guide. Documents xsim's UVM support (does not document this defect).

## Cross-links

- `[[xsim_vif_quirks]]` — sibling note on parameterised-interface limitations in the same simulator.
- `[[randomization_rand_randc]]` — the underlying SV randomisation mechanics this bug breaks.
- `[[uvm_run_workflow]]` — the xsim-Docker flow where this bug manifests in this repo.
