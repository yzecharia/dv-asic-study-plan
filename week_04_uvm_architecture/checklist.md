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
- [x] HW3: barrel shifter

## Iron-Rule deliverables

- [x] (a) RTL committed and lint-clean (ALU + adders + barrel shifter, `verilator --lint-only -Wall` zero warnings)
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
