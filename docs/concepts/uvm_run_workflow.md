# UVM Run Workflow (Vivado xsim via Docker)

**Category**: Toolchain / UVM · **Used in**: every UVM week (W4–W7, W12, W14, W20) · **Type**: authored

The standard Salemi pattern is **"compile once, run many tests."** This note documents how to do that with the repo's three Vivado-xsim-via-Docker wrappers and the matching VS Code tasks. Use this as a runbook when you're setting up a new HW folder or starting a fresh `+UVM_TESTNAME` debug session.

## Two-step model

```
   Edit code
     │
     ▼
   COMPILE  ← slow (~30–60s)  - xvlog + xelab inside Docker; produces snapshot at ./xsim.dir/sim/
     │
     ▼
   RUN TEST  ← fast (~5s each) - xsim against existing snapshot, with +UVM_TESTNAME picking the class
     │
     ▼
   (run another test? → loop on RUN, no recompile)
   (edited code? → loop back to COMPILE)
```

Splitting compile from run is the whole reason `+UVM_TESTNAME` exists. The book-quote framing: **"same compiled image, different test classes selected via the command line."**

## The three wrapper scripts at the repo root

| Script | What it does | Use when |
|---|---|---|
| `run_xsim.sh` | full pipeline (xvlog + xelab + xsim) and **deletes the snapshot** after | one-shot single-test run |
| `run_xsim_uvm_compile.sh` | xvlog + xelab only — **keeps** the snapshot | start of a debug session, after edits |
| `run_xsim_uvm_test.sh <test_name> [project_dir]` | xsim against existing snapshot with `+UVM_TESTNAME=<test_name>` | every test run after compile |
| `run_xsim_uvm_compile_auto.sh <tb_file>` | wrapper around compile that auto-globs `*_pkg.{sv,svh}` siblings | typical compile invocation from a TB folder |

## Compile flow — three equivalent ways

### Way 1 — VS Code task

Open any source file in the HW folder, then:

```
Cmd+Shift+P → Tasks: Run Task → 🔨 UVM COMPILE (snapshot — compile once, auto-include *_pkg.{sv,svh})
```

The task uses `${file}` (currently-open file) and auto-globs `*_pkg.{sv,svh}` siblings.

### Way 2 — auto wrapper from terminal

```bash
cd <hw_folder>
/Users/yuval/sv_projects/study_plan_2.0/run_xsim_uvm_compile_auto.sh top.sv
```

### Way 3 — explicit file list

```bash
cd <hw_folder>
/Users/yuval/sv_projects/study_plan_2.0/run_xsim_uvm_compile.sh ch13_pkg.svh top.sv
```

All three leave a snapshot at `<hw_folder>/xsim.dir/sim/`. Don't delete it between test runs.

## Run flow — two equivalent ways

### Way 1 — VS Code task (prompts for test name + verbosity + seed)

```
Cmd+Shift+P → Tasks: Run Task → ▶️ UVM RUN TEST (against existing snapshot)
```

Prompts pop up:
- **uvmTestName** — type `random_test` or `add_test` etc.
- **uvmVerbosity** — pick-list (UVM_LOW / UVM_MEDIUM / UVM_HIGH / UVM_FULL / UVM_DEBUG; leave blank for default)
- **svSeed** — integer or empty

### Way 2 — terminal

```bash
cd <hw_folder>
/Users/yuval/sv_projects/study_plan_2.0/run_xsim_uvm_test.sh random_test
```

With knobs:

```bash
UVM_VERBOSITY=UVM_HIGH SV_SEED=42 \
    /Users/yuval/sv_projects/study_plan_2.0/run_xsim_uvm_test.sh random_test
```

## The three knobs you tune at run time

| Knob | What it controls | Examples |
|---|---|---|
| `UVM_TESTNAME` | which test class the factory creates | `random_test`, `add_test`, `error_test` |
| `UVM_VERBOSITY` | how chatty UVM's reporter is | `UVM_NONE` (silent), `UVM_LOW`, `UVM_MEDIUM` (default), `UVM_HIGH`, `UVM_FULL`, `UVM_DEBUG` |
| `SV_SEED` | deterministic randomization for `$random` / `randomize()` | any int (e.g. `42`, `1234`) — same seed → same stimulus |

These map to `+plusargs` inside the simulator:

| Env var | Becomes plusarg |
|---|---|
| `UVM_TESTNAME=foo` | `+UVM_TESTNAME=foo` |
| `UVM_VERBOSITY=UVM_HIGH` | `+UVM_VERBOSITY=UVM_HIGH` |
| `SV_SEED=42` | xsim flag `-sv_seed 42` |

## Why the env-var indirection?

The wrapper scripts read env vars and translate them into the right xsim flags. xsim's flag syntax differs from Questa's (`+UVM_TESTNAME=` vs `-testplusarg UVM_TESTNAME=`). The env-var layer hides that — same `UVM_TESTNAME=foo` invocation works whether the underlying simulator changes someday.

## Salemi-vs-yours simulator command translation

When the book shows:

```bash
vsim +UVM_TESTNAME=random_test top         # Mentor Questa
```

The xsim equivalent in this repo is:

```bash
UVM_TESTNAME=random_test bash run_xsim.sh top.sv
```

The plusarg lands inside the simulation identically; only the launcher syntax differs.

## Typical debug loop

```
1. Open top.sv
2. Run "🔨 UVM COMPILE"          ← slow, do once
3. Run "▶️ UVM RUN TEST"          ← enter "random_test"
4. Inspect output
5. Run "▶️ UVM RUN TEST" again   ← enter "add_test" (no recompile cost)
6. (Found a bug? Edit code.)
7. Goto step 2.
```

For tighter dev loops, raise verbosity to see UVM_INFO messages from your components:

```
▶️ UVM RUN TEST → uvmTestName=random_test, uvmVerbosity=UVM_HIGH
```

## Common gotchas

- **`UVM_FATAL [NOCOMP] No components instantiated`** — you forgot `UVM_TESTNAME`. The plusarg didn't reach `run_test()`. Set the env var or the task input.
- **`factory: cannot find type 'foo_test'`** — your test class isn't compiled. Check the package's `\`include` order and that the file actually exists at the path.
- **PASS prints at time 0** — your `run_phase` returned without ever doing real work. In OO ch.10-style code, `fork ... join_none` without `wait fork` does this. In ch.12+ component code, missing `phase.raise_objection(this)` does this.
- **Recompiled and now sim "passes" with no output** — you compiled with no top file (typo in the file list, etc.). `run_test()` had nothing to invoke. Check the `Files:` line in the wrapper's banner output.
- **`wait fork;` after `join_none` hangs the sim** — children that `forever`-loop don't exit, so `wait fork` never unblocks. The stimulus driver must `phase.drop_objection(this)` to end the run; passive observers (scoreboard, coverage) never raise objections.
- **`xsim.dir/` shows up in `git status`** — already gitignored at the repo root; if a fresh clone shows it, run `git status --ignored` to confirm.

## Reading

- Salemi *UVM Primer* ch.11–12 (UVM tests + components — where `run_test()` and the phase machine are introduced), pp. 67–81.
- Vivado xsim user guide UG900 — `xelab` / `xsim` flags reference.
- IEEE 1800-2017 §22.4 — `$value$plusargs` (the underlying mechanism that reads `+UVM_TESTNAME`).

## Cross-links

- `[[uvm_test]]` · `[[uvm_testbench_skeleton]]` — what the test class looks like that `+UVM_TESTNAME` selects.
- `[[uvm_factory_config_db]]` — the factory mechanism behind `run_test()`'s name → class lookup.
- `[[uvm_phases]]` — what runs after `run_test()` is called and the test class is created.
- `[[sv_packages]]` · `[[testbench_top]]` — file structure expected by the compile flow.
