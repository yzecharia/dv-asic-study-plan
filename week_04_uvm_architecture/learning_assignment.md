# Week 4 — Learning Assignment

## Reading — Verification

Anchor: **Salemi *The UVM Primer* ch.9–14**.

| # | Chapter | Why |
|---|---|---|
| ch.9 | The Factory Pattern (in plain SV) | Understand the *mechanism* before UVM macros. Salemi builds an `animal_factory` with a static method + `case` + `$cast`. |
| ch.10 | An OO Testbench | Pre-UVM bridge: `testbench` class composing `tester`/`scoreboard`/`coverage` via `fork/join_none`. |
| ch.11 | UVM Tests ⭐ | `uvm_test`, `\`uvm_component_utils`, `run_phase`, objections, `+UVM_TESTNAME`, `uvm_config_db`. |
| ch.12 | UVM Components ⭐ | The 5 phases Salemi names; only `build_phase` and `run_phase` are *used* in the chapter — don't try to do real work in the others yet. |
| ch.13 | UVM Environments ⭐ | `uvm_env` + abstract `base_tester` + factory override. The first time UVM macros pay off. |
| ch.14 | A New Paradigm | Short philosophical close — what UVM gives you over plain OOP. |

**Page-precise refs**: see canonical `docs/week_04.md` — Yuval's
already-confirmed chapter list.

Concept notes to skim/update:
- [[concepts/uvm_phases]]
- [[concepts/uvm_factory_config_db]]
- [[concepts/interfaces_modports]] — for the ALU `alu_if`
- [[concepts/sva_assertions]] — for the assertion bundle on the ALU

## Reading — Design

| Source | Why |
|---|---|
| Dally & Harting ch.10 — Arithmetic Circuits | Ripple-carry adder, subtractor, comparator, shift-add multiplier. |
| Dally & Harting ch.12 — Fast Arithmetic | CLA, Wallace trees, barrel shifters. |
| Sutherland *SV for Design* (2e) ch.10 — Interfaces | `interface`, `modport`, `clocking`. |
| Cummings *Synthesis Coding Styles for Efficient Designs* (SNUG-2012) | Synthesis-friendly RTL idioms for the ALU. |

Concept notes: [[concepts/adders_carry_chain]], [[concepts/multipliers]],
[[concepts/interfaces_modports]], [[concepts/synthesis_basics]].

Cheatsheets to skim:
- `cheatsheets/salemi_uvm_ch9-13.sv` — your own UVM reference card.
- `cheatsheets/spear_ch4_interfaces.sv` — interfaces + clocking blocks
  (despite the filename, this is the right reference for the
  Sutherland ch.10 material too).

## Tool setup

UVM weeks need Vivado xsim Docker (open-source UVM support is
incomplete). Use the per-week VSCode task **🧪 FLOW: XSIM UVM** or
the CLI:

```bash
cd week_04_uvm_architecture
bash ../run_xsim.sh -L uvm homework/verif/per_chapter/hw_ch11_uvm_tests/hello_uvm_test.sv
```

EDA Playground fallback: paste the same files; pick "Aldec Riviera" or
"Synopsys VCS" with UVM 1.2.

## AI productivity task (this week)

**Type 4 — Interview Questions** (per `docs/AI_LEARNING_GUIDE.md` §3).

Prompt: copy [`docs/prompts/interview-questions.md`](../docs/prompts/interview-questions.md),
fill the topic as `UVM phases, factory pattern, uvm_config_db`. Generate
10 questions. Write your own answers in `notes.md` first; only then
ask AI for its answers and compare.

Time budget: 30 min. Output goes to `notes.md` under
`## AI interview Qs — UVM`.

## Power-skill task (this week)

Per `docs/POWER_SKILLS.md` §1: draft your **first STAR story** about a
UVM bug. The example STAR in `concepts/star_stories_template.md` is
literally the `uvm_config_db` typo bug — if that one resonates with
your own debug, use it as the seed. Otherwise pick a different ch.9-13
drill and write your own.

Output: `docs/star_stories/01_uvm_config_db.md` (folder doesn't exist
yet — create it when you write the first story).

Time budget: 30 min.
