#!/usr/bin/env python3
"""
generate_week_daily_drivers.py — author the five daily-driver files for
each week_NN_*/ folder that doesn't already have them.

For each week:
    week_NN_<slug>/README.md
    week_NN_<slug>/learning_assignment.md
    week_NN_<slug>/homework.md
    week_NN_<slug>/checklist.md
    week_NN_<slug>/notes.md

Files are NOT overwritten if they already exist (so hand-crafted ones
stay intact). The generated content is intentionally a thin pointer
to docs/week_NN.md (the canonical syllabus) plus the cross-cutting
weekly task slots — Yuval refines each week as he reaches it.

Usage:
    python3 tools/generate_week_daily_drivers.py            # all weeks
    python3 tools/generate_week_daily_drivers.py 5 6 7      # selected
    python3 tools/generate_week_daily_drivers.py --force    # overwrite existing
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

REQUIRED_FILES = (
    "README.md",
    "learning_assignment.md",
    "homework.md",
    "checklist.md",
    "notes.md",
)


PHASE_BY_WEEK = {
    1:  ("Phase 1 — SV Fundamentals",        "✅ Done"),
    2:  ("Phase 1 — SV Fundamentals",        "✅ Done"),
    3:  ("Phase 1 — SV Fundamentals",        "✅ Done"),
    4:  ("Phase 2 — UVM Methodology",        "🟡 In progress"),
    5:  ("Phase 2 — UVM Methodology",        "⬜ Not started"),
    6:  ("Phase 2 — UVM Methodology",        "⬜ Not started"),
    7:  ("Phase 2 — UVM Methodology",        "⬜ Not started"),
    8:  ("Phase 3 — RTL & Architecture",     "⬜ Not started"),
    9:  ("Phase 3 — RTL & Architecture",     "⬜ Not started"),
    10: ("Phase 3 — RTL & Architecture",     "⬜ Not started"),
    11: ("Phase 3 — RTL & Architecture",     "⬜ Not started"),
    12: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    13: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    14: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    15: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    16: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    17: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    18: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    19: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
    20: ("Phase 4 — Portfolio + Advanced",   "⬜ Not started"),
}

# 5 AI task types rotated across weeks (per docs/AI_LEARNING_GUIDE.md)
AI_TASK_BY_WEEK = {
    1:  "Type 1 — Verify (shallow vs deep copy explanation against Spear ch.5)",
    2:  "Type 2 — Flashcards (CRV operators: solve…before, dist, randc, etc.)",
    3:  "Type 3 — RTL style review (your W3 traffic-light FSM)",
    4:  "Type 4 — Interview Qs (UVM phases, factory, uvm_config_db)",
    5:  "Type 5 — Waveform / debug summary (TLM analysis-port broadcast trace)",
    6:  "Type 1 — Verify (UVM sequence vs sequencer explanation)",
    7:  "Type 3 — RTL style review (your async FIFO RTL)",
    8:  "Type 2 — Flashcards (RV32I instruction encodings)",
    9:  "Type 4 — Interview Qs (pipeline hazards: RAW, load-use, control)",
    10: "Type 5 — Waveform / debug summary (UART framing-error trace)",
    11: "Type 3 — RTL style review (your SPI master FSM)",
    12: "Type 1 — Verify (UVM coverage closure methodology)",
    13: "Type 4 — Interview Qs (walk-through of FIFO + CPU project)",
    14: "Type 5 — Waveform / debug summary (RAL backdoor vs frontdoor access)",
    15: "Type 3 — RTL style review (a synthesis-flagged RTL block)",
    16: "Type 1 — Verify (Q-format saturation/rounding semantics)",
    17: "Type 2 — Flashcards (FIR filter design parameters)",
    18: "Type 5 — Waveform / debug summary (2D conv edge-padding behaviour)",
    19: "Type 3 — RTL style review (your CDC handshake RTL)",
    20: "Type 4 — Interview Qs (capstone walkthrough — every layer)",
}

POWER_TASK_BY_WEEK = {
    1:  "LinkedIn headline draft (Pattern A from `docs/POWER_SKILLS.md` §2)",
    2:  "LinkedIn headline iterate — try Pattern B; note view-count change",
    3:  "Resume bullet — Phase 1 retrospective entry",
    4:  "STAR story — UVM bug (template in `concepts/star_stories_template`)",
    5:  "LinkedIn About update mentioning current phase (UVM)",
    6:  "Elevator pitch — first 30s draft for the UVM agent built this week",
    7:  "Resume bullet — UVM env with scoreboard for register file",
    8:  "LinkedIn — RISC-V learning post (one paragraph + a snippet)",
    9:  "Mock interview prep — 3 pipeline-hazards questions answered out loud",
    10: "LinkedIn — UART project highlight with a waveform image",
    11: "Resume bullet — UART/SPI/AXI-Lite protocols implemented",
    12: "Demo video script draft for UART-UVM",
    13: "Resume bullets for both portfolio repos (FIFO-UVM, RISC-V CPU)",
    14: "Mock interview #1 — UVM focus (40 min self-mock)",
    15: "Resume bullet — synthesis flow + LUT/FF/Fmax report",
    16: "LinkedIn post — fixed-point arithmetic deep dive",
    17: "Demo video — FIR impulse response visualisation",
    18: "LinkedIn — DSP-on-FPGA post with input/output image diff",
    19: "Mock interview #2 — CDC depth (40 min self-mock)",
    20: "Final About refresh + 'Open to opportunities' toggle on; mock #3 full portfolio",
}


def parse_canonical(week_path: Path) -> dict:
    """Pull H1 title + first 'Why this matters' paragraph from the
    canonical syllabus. Best-effort — if nothing matches, returns
    sensible fallbacks."""
    text = week_path.read_text() if week_path.exists() else ""
    # H1 title
    m = re.match(r"^#\s+(.+?)\s*$", text, re.MULTILINE)
    title = m.group(1).strip() if m else week_path.stem.replace("_", " ").title()
    # First paragraph after "Why This Matters" or "Why this matters" (if any)
    why = ""
    m = re.search(r"##\s+Why This Matters\s*\n+(.+?)\n\n",
                  text, re.IGNORECASE | re.DOTALL)
    if m:
        why = m.group(1).strip()
    return {"title": title, "why": why, "exists": week_path.exists()}


def render_readme(week: int, slug: str, info: dict) -> str:
    phase, status = PHASE_BY_WEEK.get(week, ("Phase 4 — Portfolio + Advanced", "⬜ Not started"))
    why_block = info["why"] if info["why"] else "(see canonical `docs/week_NN.md`)"
    return f"""# Week {week} — {info['title']}

> **{phase}** · canonical syllabus: [`docs/week_{week:02d}.md`](../docs/week_{week:02d}.md) · {status}

{why_block}

## Prerequisites

See [`docs/ROADMAP.md`](../docs/ROADMAP.md) §"Hard prerequisites" for
the dependency list. Refresh the relevant concept notes in
[`docs/concepts/`](../docs/concepts/) before starting.

## Estimated time split (24h total)

```
Reading        6h
Design         8h
Verification   8h
AI + Power     2h
```

(Adjust per week — UVM-heavy weeks shift hours into Verification;
RTL-heavy weeks shift into Design.)

## Portfolio value (what this week proves)

> Fill in 2–3 bullets when you start the week. The rule of thumb:
> what could you put on your CV after this week that you couldn't
> the week before?

## Iron-Rule deliverables

- [ ] **(a)** RTL committed and lint-clean.
- [ ] **(b)** Gold-TB PASS log captured to `sim/<topic>_pass.log`.
- [ ] **(c)** `verification_report.md` written.

## Daily-driver files

- [[learning_assignment]] · [[homework]] · [[checklist]] · [[notes]]

Canonical syllabus: [`docs/week_{week:02d}.md`](../docs/week_{week:02d}.md).

> ℹ️ This file was auto-generated by
> `tools/generate_week_daily_drivers.py`. Refine it by hand when
> you start the week — replace placeholders with concrete content.
"""


def render_learning(week: int, slug: str, info: dict) -> str:
    ai_task = AI_TASK_BY_WEEK.get(week, "Type 1 — Verify (pick a topic and an AI explanation to audit)")
    power_task = POWER_TASK_BY_WEEK.get(week, "Pick a task from `docs/POWER_SKILLS.md`")
    return f"""# Week {week} — Learning Assignment

## Reading

The canonical reading list with chapter and page references lives at
[`docs/week_{week:02d}.md`](../docs/week_{week:02d}.md). When you start
the week, copy the **Reading — Verification** and **Reading — Design**
tables into this file with page-precise citations per `CLAUDE.md` §3.

## Concept notes to review/update

Browse [`docs/concepts/`](../docs/concepts/) and link to the relevant
notes here once you've identified them. Use `[[concepts/<slug>]]`
wikilinks so Obsidian's graph view shows the dependency.

## AI productivity task (this week)

**{ai_task}**

Use the matching template under [`docs/prompts/`](../docs/prompts/).
Time budget: 30 min. Output goes to `notes.md`.

## Power-skill task

{power_task}

Time budget: 30 min.

> ℹ️ Auto-generated stub. Replace with hand-crafted content when you
> start the week.
"""


def render_homework(week: int, slug: str, info: dict) -> str:
    return f"""# Week {week} — Homework

The canonical homework list lives at
[`docs/week_{week:02d}.md`](../docs/week_{week:02d}.md). When you start
the week, port the **Drills**, **Main HWs**, and **Stretch** sections
here — but with explicit file paths, acceptance criteria, and run
commands using the `homework/` folder structure that already exists
in this repo.

## Per-chapter drills (TODO)

> Table: chapter → file path → 3-line spec → acceptance criteria.

## Connector exercise (TODO)

> Tie design + verif. Same DUT, both sides.

## Big-picture exercise (TODO)

> Mini-project within this week's scope only.

## Self-check questions (TODO)

> 5–8 questions answerable without looking. Answer keys at the
> bottom of this file once written.

## Run commands

```bash
cd week_{week:02d}_*

# Native arm64 sim (Phase 1/2 default)
verilator --lint-only -Wall <rtl_file>.sv
iverilog -g2012 -o /tmp/sim <tb_file>.sv && vvp /tmp/sim

# UVM (Phase 3, when needed)
bash ../run_xsim.sh -L uvm <files>

# Yosys schematic
bash ../run_yosys_rtl.sh <rtl_file>.sv
```

> ℹ️ Auto-generated stub. Replace with concrete homework content
> when you start the week.
"""


def render_checklist(week: int, slug: str, info: dict) -> str:
    ai_task = AI_TASK_BY_WEEK.get(week, "AI productivity task")
    power_task = POWER_TASK_BY_WEEK.get(week, "Power-skill task")
    return f"""# Week {week} — Checklist

## Reading

- [ ] Verification reading (per `learning_assignment.md`)
- [ ] Design reading (per `learning_assignment.md`)
- [ ] Concept notes reviewed/updated

## Per-chapter drills

- [ ] (fill in from canonical `docs/week_{week:02d}.md`)

## Main HWs

- [ ] (fill in from canonical `docs/week_{week:02d}.md`)

## Iron-Rule deliverables

- [ ] (a) RTL committed and lint-clean
- [ ] (b) Gold-TB PASS log captured to `sim/<topic>_pass.log`
- [ ] (c) `verification_report.md` written

## Cross-cutting weekly tasks

- [ ] **AI productivity task** — {ai_task}
- [ ] **Power-skill task** — {power_task}
- [ ] `notes.md` updated with at least 3 entries this week

> ℹ️ Auto-generated stub. Refine the day-by-day breakdown when you
> start the week.
"""


def render_notes(week: int, slug: str, info: dict) -> str:
    return f"""# Week {week} — Notes

## Open questions

> (none yet — add as they come up while reading or coding)

## Aha moments

> (none yet)

## AI corrections

> Track any time AI confidently said something the book contradicted.

## Methodology lessons

> One paragraph per debug session worth remembering.
"""


RENDERERS = {
    "README.md":                render_readme,
    "learning_assignment.md":   render_learning,
    "homework.md":              render_homework,
    "checklist.md":             render_checklist,
    "notes.md":                 render_notes,
}


def find_week_folders() -> list[tuple[int, str, Path]]:
    out: list[tuple[int, str, Path]] = []
    for p in sorted(ROOT.glob("week_*")):
        if not p.is_dir() or p.name.startswith("week_") and "archive" in p.parts:
            continue
        m = re.match(r"week_(\d+)_(.+)", p.name)
        if m:
            out.append((int(m.group(1)), m.group(2), p))
    return out


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--force"]
    force = "--force" in sys.argv

    weeks_filter = {int(a) for a in args} if args else None

    weeks = find_week_folders()
    n_written = 0
    n_skipped = 0

    for week_num, slug, week_dir in weeks:
        if weeks_filter is not None and week_num not in weeks_filter:
            continue

        canonical = DOCS / f"week_{week_num:02d}.md"
        info = parse_canonical(canonical)

        for fname, render in RENDERERS.items():
            target = week_dir / fname
            if target.exists() and not force:
                n_skipped += 1
                continue
            target.write_text(render(week_num, slug, info))
            n_written += 1
            print(f"  wrote {target.relative_to(ROOT)}")

    print()
    print(f"Generated {n_written} file(s); skipped {n_skipped} existing file(s).")
    print("Run `python3 tools/check_week_structure.py` to verify.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
