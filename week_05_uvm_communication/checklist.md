# Week 5 — Checklist

## Verification track

- [x] Read Salemi ch.15 (analysis ports, dice example)
- [x] Read Salemi ch.16 (analysis ports in TinyALU)
- [x] Read Salemi ch.17 (put/get + tlm_fifo)
- [x] Read Salemi ch.18 (tester/driver split)
- [ ] Read Salemi ch.19 (UVM reporting)
- [x] Drill ch.15 (dice roller)
- [x] Drill ch.16 (analysis port in TB)
- [x] Drill ch.17 (producer/consumer + tlm_fifo)
- [x] Drill ch.18 (tester/driver split toy)
- [ ] Drill ch.19 (reporting + verbosity)
- [x] HW1: full analysis path on ALU TB (extends W4 HW2)
- [x] HW2: tester/driver split on ALU TB (extends HW1)
- [ ] HW3: reporting polish (extends HW2)
- [ ] Can answer all self-check questions

## Design track

- [x] Read Dally ch.16 (datapath sequential)
- [ ] Read Dally ch.22 (interface timing / handshake)
- [x] Read Sutherland *SV for Design* ch.5 (arrays, structs, unions)
- [ ] Read Cummings async FIFO paper (theory only — build is W7)
- [x] Drill Dally ch.16 (shift register)
- [ ] Drill Dally ch.22 (valid/ready handshake)
- [x] Drill Sutherland ch.5 (packed struct port)
- [ ] HW1: pipelined MAC unit
- [ ] HW2: round-robin arbiter

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean (`verilator --lint-only -Wall`)
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [x] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — Type 5 — Waveform / debug summary (TLM analysis-port broadcast trace) → `notes.md`
- [ ] **Power-skill task** — LinkedIn About update mentioning current phase (UVM)
- [ ] `notes.md` updated with at least 3 entries this week

## Daily breakdown (suggested)

```
Session 1   Read Salemi ch.15+16, drill ch.15.
            Read Dally ch.16, drill ch.16 (shift register).
Session 2   Drill ch.16, read Sutherland ch.5, drill struct port.
            Start HW1 verif (full analysis path on ALU TB).
Session 3   Finish HW1 verif. Read Salemi ch.17+18, drill ch.17.
            Read Dally ch.22, drill valid/ready handshake.
Session 4   Drill ch.18. HW2 verif (tester/driver split).
            HW1 design (pipelined MAC unit).
Session 5   Read Salemi ch.19, drill ch.19, HW3 verif (reporting polish).
            HW2 design (round-robin arbiter). Self-check Qs.
```

Skip a day, don't skip the week. Skip a week, don't skip the phase.
