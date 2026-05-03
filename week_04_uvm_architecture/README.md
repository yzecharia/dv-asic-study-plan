# Week 4 — UVM Architecture & Components

> **Phase 2 — UVM Methodology** · Salemi ch.9–14 · 🟡 In progress (verif done; design TODO)

The week where the UVM static architecture clicks: factory pattern,
`uvm_test`, `uvm_component`, `uvm_env`. Sequences, TLM, transactions
are **deliberately deferred to W5–W6** — keep scope tight.

## Prerequisites

- [[week_01_sv_oop]] — classes, inheritance, virtual methods
- [[week_02_constrained_random]] — randomization basics
- [[week_03_coverage_assertions]] — covergroups, SVA
- Concept notes: [[concepts/uvm_phases]], [[concepts/uvm_factory_config_db]],
  [[concepts/interfaces_modports]]

## Estimated time split (24h total)

```
Reading        6h   Salemi ch.9-14 + Sutherland Design ch.10 + ChipVerify
Design         8h   Dally ch.10/12 drills + ALU + multiplier + barrel shifter
Verification   8h   Salemi drills (ch.9-13 done) + ALU UVM TB + override demo
AI + Power     2h   AI: interview Qs on UVM phases; Power: STAR — UVM bug
```

## Portfolio value (what this week proves)

- You can build a UVM environment from scratch using only the static
  architecture (no sequences).
- You understand the factory pattern at the **plain SV level first**
  (Salemi ch.9), then with UVM macros (ch.13).
- You can apply `set_type_override` to swap stimulus styles without
  touching env code — the single most reusable UVM pattern.

## Iron-Rule deliverables

- [x] **(b)** Gold TB PASS log — Salemi drills ch.9–13 PASS captured.
- [ ] **(a)** RTL committed — ALU + adders + multiplier + barrel shifter (in progress).
- [ ] **(b)** Gold TB PASS log — ALU UVM TB run.
- [ ] **(c)** `verification_report.md` — UVM env walkthrough + factory override flip evidence.

## Daily-driver files

- [[learning_assignment]] — page-precise reading + AI productivity task
- [[homework]] — exercise list with acceptance criteria
- [[checklist]] — daily checkboxes
- [[notes]] — your freeform notes

Canonical syllabus: [`docs/week_04.md`](../docs/week_04.md).
