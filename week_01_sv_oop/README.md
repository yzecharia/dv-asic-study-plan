# Week 1 — SystemVerilog OOP

> **Phase 1 — SV Fundamentals** · Spear ch.2 + ch.5 + ch.8 §1–5 · ✅ Done

The OOP foundation under everything that follows. Every UVM
transaction, sequence, scoreboard, and test is just a SystemVerilog
class. If polymorphism doesn't feel natural after this week, you'll
fight UVM in W4.

## Prerequisites

- HDLBits-level Verilog (assumed background per `CLAUDE.md` §6).
- No previous OOP experience required — Spear ch.5 starts from zero.

## Estimated time split (24h total)

```
Reading        8h   Spear ch.2 + ch.5 + ch.8 §1–5; Verification Academy lessons 1–6
Verification  10h   HW1 (Packet) + HW2 (Transaction hierarchy) + HW3 (deep copy) + HW4 (virtual methods)
Design         4h   none — Phase 1 is verif-only by design
AI + Power     2h   AI: verify SV terminology against Spear ch.5; Power: write LinkedIn headline draft
```

## Portfolio value (what this week proves)

- You can model a transaction as a class with `rand` fields,
  constraints, `display`, `copy`, and `compare` methods.
- You understand the inheritance hierarchy that UVM relies on
  (`uvm_object` → `uvm_transaction` → `uvm_sequence_item` →
  user transaction).
- You know when to use `virtual` methods — and what breaks without
  them when polymorphism is required.

## Iron-Rule deliverables

- [x] **(a)** RTL committed — n/a (Phase-1 verif-only).
- [x] **(b)** Gold-TB PASS log — all 4 HWs run clean.
- [x] **(c)** `verification_report.md` — Phase-1 retrospective.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_01.md`](../docs/week_01.md).
