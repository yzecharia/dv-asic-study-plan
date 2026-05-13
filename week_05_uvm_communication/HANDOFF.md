# Week 5 — Session 3 Handoff (2026-05-13)

> Snapshot of where HW1 (analysis-path ALU testbench) stands, plus
> open toolchain decisions. Read this first when resuming.

---

## Session 3 progress summary

**Did today:**
- Set up `hw1_alu_analysis_path/` folder
- Drafted `alu_pkg.svh` (typedefs)
- Drafted `alu_if.svh` (interface with `command_t`/`result_t` signals + DUT modport)
- Drafted `alu.sv` (DUT — 2-block FSM, ADD/AND/XOR/MUL, with bugs to fix)
- Fixed three flow-script bugs:
  - `run_check.sh` — added package-keyword detection so `alu_pkg.svh` compiles before `alu_if.svh` regardless of alphabetic order
  - `run_check.sh` — always passes `-L uvm` so UVM-importing packages compile
  - `run_check.sh` — auto-detects `*_tb_top.sv` / `*_top.sv` as elaboration root (handles modules with interface ports)
  - `run_xsim_folder.sh` — same `.svh` + package-detection fix

**Blocking the build right now:**
1. `alu_tb_top.sv` is empty — xelab falls back to `alu` as top → fails because `alu` has an interface port (`alu_if.dut bus`). **Next file to write.**
2. DUT has known bugs (see below)

---

## Current file inventory

```
hw1_alu_analysis_path/
├── alu_pkg.svh         ✏️  drafted — typedefs only, no UVM classes yet
├── alu_if.svh          ✏️  drafted — DUT modport done, TB/mon modports pending
├── alu.sv              ✏️  drafted — has bugs (see DUT bugs below)
├── alu_tb_top.sv       🆕  EMPTY — write next
```

### Files still missing (need to be written in order)
```
alu_tb_top.sv               ← unblocks xelab. Instantiate clock + alu_if + alu.
alu_command_monitor.svh     ← uvm_analysis_port #(command_t) wrapper
alu_result_monitor.svh      ← uvm_analysis_port #(result_t) wrapper
alu_base_tester.svh         ← stays mostly the same as W4
alu_random_tester.svh       ← stays mostly the same as W4
alu_directed_tester.svh     ← stays mostly the same as W4
alu_random_test.svh         ← stays the same as W4
alu_directed_test.svh       ← stays the same as W4
alu_coverage.svh            ← REFACTOR: extends uvm_subscriber #(command_t)
alu_scoreboard.svh          ← REFACTOR: extends uvm_subscriber #(result_t) + tlm_analysis_fifo
alu_env.svh                 ← REFACTOR: build_phase + connect_phase wiring
```

---

## Decisions made (architectural)

| Decision | Choice | Rationale |
|---|---|---|
| Struct ports vs individual signals | **Struct ports** (`command_t cmd` on interface, not separate A/B/op) | Builds on the ch.5 packed-struct-port drill. Cleaner bus. |
| `result_t` shape | **Bare typedef** `typedef logic [15:0] result_t;` | Single-field "struct" is noise. Convert to struct only if more fields needed. |
| `start`/`done` placement | **Plain interface signals**, NOT in `command_t`/`result_t` | TLM principle: handshakes are signals, transactions are data. |
| FSM style | **2-block** (one `always_ff` + one `always_comb` + assigns) | Matches modern teaching, lint-clean, common idiom. |
| Result computation | **Compute & latch on `start` posedge**, hold in `res_reg` for the full latency window | Avoids the "cmd changed mid-MUL" race. No separate `a_reg`/`b_reg`/`op_reg` needed. |
| `bus.done`/`bus.res` gating | **Don't gate result by `done`** | Standard handshake convention — consumers respect `done`. Saves a mux. |

---

## DUT bugs to fix (from `alu.sv` review)

Pending fixes — see chat for the full review. Cliff notes:

1. **`logic res_reg [15:0]`** → should be `logic [15:0] res_reg` (packed vs unpacked dimension placement)
2. **`state_e` not declared** → add to `alu_pkg.svh`:
   ```systemverilog
   typedef enum logic [1:0] {IDLE, MUL_C1, MUL_C2, DONE} state_e;
   ```
3. **`bus.reset_n`** not `reset_n` (line 14 — missing `bus.` prefix)
4. **`nest_state` typo** for `next_state` (line 32)
5. **Inferred latch on `res_reg`** in `always_comb` — default it to `'0` at the top
6. **Operands not latched** — current code computes from `bus.cmd.*` directly, which is fragile for MUL since cmd can change mid-operation. Fix: latch a_reg, b_reg, op_reg on start, OR compute & latch the result directly in `always_ff` (the 2-block style we discussed).
7. **`logic` base type missing** on `state_e` enum (line 17 of alu_pkg.svh)
8. **`\`include "alu_if.svh"` inside the package** (line 5 of alu_pkg.svh) — illegal. Delete that line. Interfaces are peer compilation units, not nested in packages.

Reference for the corrected DUT structure: the 2-block version sketched in chat. Key features: state register + result register in one `always_ff`; next-state logic in one `always_comb`; `assign bus.done = (state == DONE); assign bus.res = res_reg;`.

---

## Toolchain state

### Scripts that are good
- `run_check.sh` — works for any folder, handles `.svh`, packages, `-L uvm`, auto-detects `*_tb_top.sv` as elab root
- `run_xsim_folder.sh` — same fixes, works for full sim
- `run_xsim.sh` — already had `-L uvm`
- `run_yosys_slang.sh` — gate-level schematic via slang plugin (installed locally)

### Scripts that haven't been updated (will bite when you use them)
- `run_xsim_auto.sh` — only picks up `*_pkg.sv`, not `.svh` or other packages
- `run_xsim_uvm_compile_auto.sh` — same issue
- `run_yosys_rtl.sh` — only globs `*.sv`
- `xvlog_lint.sh` — single-file lint, no folder context

### Consolidation refactor (PROPOSED, NOT EXECUTED)

13 tasks in `.vscode/tasks.json` → consolidate to 5 core + 2 utility:

| # | Task | Script |
|---|---|---|
| 1 | 🔬 **CHECK** | run_check.sh |
| 2 | 🔧 **SCHEMATIC** | run_yosys_slang.sh |
| 3 | 🌊 **SIM** (one-shot) | run_sim.sh (new) |
| 4 | 🔨 **COMPILE** (snapshot) | run_compile.sh (new) |
| 5 | ▶️ **RUN** (against snapshot) | run_test.sh (new) |
| util | 🧹 CLEAN | run_xsim_clean.sh |
| util | 📈 BADGES | tools/update_progress_badges.py |

Deletes: `xvlog_lint.sh`, `run_xsim_auto.sh`, `run_yosys_rtl.sh`, possibly `run_xsim_folder.sh` (or repurpose).

**To execute:** say "do the refactor" in chat. ~30 min of work.

---

## Architecture diagram (target for HW1)

```
              ┌──────────────────────────────────────────────────┐
              │ alu_if (BFM)                                      │
              │   always @(posedge clk):                          │
              │     if (start) cmd_mon_h.write_to_monitor(cmd);   │
              │     if (done)  res_mon_h.write_to_monitor(res);   │
              └────────────┬──────────────┬──────────────────────┘
                           │              │
                           ▼              ▼
                 ┌─────────────┐   ┌─────────────┐
                 │ command_mon │   │ result_mon  │
                 │ ap [cmd_t]  │   │ ap [res_t]  │
                 └──────┬──────┘   └──────┬──────┘
                        │                 │
                        ├──→ coverage     │
                        │                 │
                        ▼                 ▼
                 ┌─────────────────────────────────┐
                 │ scoreboard                      │
                 │   cmd_f : uvm_tlm_analysis_fifo │←─ commands
                 │   .write(result_t r):            │←─ results
                 │     cmd_f.try_get(cmd);          │
                 │     check_predicted(cmd, r);     │
                 └─────────────────────────────────┘
```

---

## Resume order tomorrow

1. **Apply the 8 DUT fixes** from "DUT bugs to fix" above. Re-run 🔬 CHECK on `alu.sv` — should now error at the elab step about `alu_tb_top` being empty (which is the next step).
2. **Write `alu_tb_top.sv`**: top module that instantiates clock generator + `alu_if` + `alu`. Publish the BFM handle to UVM via `uvm_config_db`. ~30 lines. Run 🔬 CHECK — should now elaborate clean.
3. **Add `state_e` to `alu_pkg.svh`** — see DUT bug 2.
4. **Add monitor classes** (`alu_command_monitor.svh`, `alu_result_monitor.svh`) — trivial wrappers around `uvm_analysis_port`. ~15 lines each.
5. **Add BFM monitor hooks** in `alu_if.svh`: `cmd_mon_h.write_to_monitor(cmd)` on start posedge, similar for result.
6. **Refactor `alu_coverage.svh`** to extend `uvm_subscriber #(command_t)`.
7. **Refactor `alu_scoreboard.svh`** to extend `uvm_subscriber #(result_t)` + own a `uvm_tlm_analysis_fifo #(command_t)`.
8. **Write `alu_env.svh`** with `connect_phase` wiring.
9. **Copy testers + tests** from W4 (largely unchanged).
10. **🌊 SIM** to verify the full path works. Capture PASS log to `sim/hw1_alu_analysis_path_pass.log`.

Expected total: 1–2 more sessions.

---

## Iron Rules state for HW1

- (a) RTL committed and lint-clean — ⏳ partial (DUT + interface + pkg drafted, not yet lint-clean)
- (b) Gold-TB PASS log — ⏳ pending full TB
- (c) `verification_report.md` updated — ⏳ end-of-week deliverable

---

## Related concept notes (read before resuming)

- `docs/concepts/uvm_analysis_ports.md`
- `docs/concepts/uvm_subscriber_coverage.md`
- `docs/concepts/uvm_tlm_analysis_fifo.md`
- `docs/concepts/uvm_scoreboard.md`
- `docs/concepts/packed_vs_unpacked.md` (for the struct port vs individual signal choice)

---

## Open chat threads to resume

- Whether to execute the **flow consolidation refactor** (5 tasks instead of 13). Awaiting "do the refactor" command.
- The corrected DUT 2-block code is in chat — not yet applied to `alu.sv`. Re-read or have me re-paste when resuming.

---

*Last updated: 2026-05-13, end of session 3.*
