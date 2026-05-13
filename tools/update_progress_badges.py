#!/usr/bin/env python3
"""
update_progress_badges.py — recompute the README badges and Progress
table from the docs.

Reads docs/week_NN.md for the current week (passed as arg or auto-
detected as the lowest-numbered week with an incomplete checklist),
counts checked vs total checklist items, and rewrites:

  * Three dynamic shields.io badges:
        ![Progress](https://img.shields.io/badge/progress-M%2F20_weeks-COLOR)
        ![Current Week](https://img.shields.io/badge/current_week-N-blue)
        ![Week N Progress](https://img.shields.io/badge/week_N_progress-XX%25-COLOR)

  * The Progress table status column in README.md.

  * The per-week status heading emojis in docs/PROGRESS.md.

Rows / headings are auto-flipped according to:
        week < current   → ✅ Done
        week = current   → 🟡 In progress
        week > current   → ⬜ Not started

  M (overall progress) is the count of weeks with status `< current`
  (i.e. closed weeks). For current_week=N, M = N-1.

Current-week detection: walk docs/week_01.md → docs/week_20.md, count
checked vs unchecked items in each (stopping at the AUTO-SYNC marker
if present), and return the lowest-numbered week that has at least one
unchecked item. If all 20 are 100%, returns TOTAL_WEEKS. This replaces
the earlier mtime-based heuristic, which broke whenever sync_week_docs
touched every week file in alphabetical order.

Color buckets for the progress badge:
    0-33%   → red
    34-66%  → yellow
    67-99%  → orange
    100%    → brightgreen

Usage:
    python3 tools/update_progress_badges.py            # auto-detect current week
    python3 tools/update_progress_badges.py 4          # force week 4
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
README = ROOT / "README.md"
PROGRESS_DOC = DOCS / "PROGRESS.md"
TOTAL_WEEKS = 20


def detect_current_week() -> int:
    """Return the lowest-numbered week with an incomplete checklist.

    Falls back to TOTAL_WEEKS if every week is 100% done.
    Skips weeks whose docs/week_NN.md is missing or has zero checkboxes
    (treats them as "no signal" rather than "done").
    """
    for week in range(1, TOTAL_WEEKS + 1):
        week_path = DOCS / f"week_{week:02d}.md"
        if not week_path.exists():
            continue
        done, total = count_checklist(week_path)
        if total == 0:
            continue
        if done < total:
            return week
    return TOTAL_WEEKS


def count_checklist(week_path: Path) -> tuple[int, int]:
    """Return (done, total) by counting [x] vs [ ] markers in week doc.

    Stops at the AUTO-SYNC marker if present — per-week file content
    appended by sync_week_docs.py would otherwise double-count.
    """
    text = week_path.read_text()
    idx = text.find("<!-- AUTO-SYNC:")
    if idx >= 0:
        text = text[:idx]
    done  = len(re.findall(r"^- \[x\]", text, re.MULTILINE))
    pend  = len(re.findall(r"^- \[ \]", text, re.MULTILINE))
    return done, done + pend


def color_for(pct: int) -> str:
    if pct >= 100: return "brightgreen"
    if pct >=  67: return "orange"
    if pct >=  34: return "yellow"
    return "red"


STATUS_DONE   = "✅ Done"
STATUS_ACTIVE = "🟡 In progress"
STATUS_TODO   = "⬜ Not started"


def update_progress_table(text: str, current_week: int) -> tuple[str, int]:
    """Flip the status column of every Progress-table row according to
    `current_week`. Returns (new_text, n_rows_rewritten)."""
    n = 0
    def replace_row(m):
        nonlocal n
        week_num = int(m.group(1))
        phase    = m.group(2)
        topic    = m.group(3)
        if   week_num <  current_week: status = STATUS_DONE
        elif week_num == current_week: status = STATUS_ACTIVE
        else:                          status = STATUS_TODO
        n += 1
        return f"| {week_num} | {phase} | {topic} | {status} |"

    new_text = re.sub(
        r"^\| (\d+) \| (\d+) \| (.+?) \| .+? \|\s*$",
        replace_row,
        text,
        flags=re.MULTILINE,
    )
    return new_text, n


def update_progress_doc(week: int) -> int:
    """Flip the per-week heading emojis in docs/PROGRESS.md.

    Headings look like `### <EMOJI> Week N — Title`. Rewrites the emoji
    according to the same week<current/=current/>current rule used for
    the README's Progress table. Returns the number of headings rewritten.
    Silently no-ops if PROGRESS.md is missing.
    """
    if not PROGRESS_DOC.exists():
        return 0
    text = PROGRESS_DOC.read_text()
    n = 0
    def replace_heading(m):
        nonlocal n
        week_num = int(m.group(1))
        title    = m.group(2)
        if   week_num <  week: emoji = "✅"
        elif week_num == week: emoji = "🟡"
        else:                  emoji = "⬜"
        n += 1
        return f"### {emoji} Week {week_num} — {title}"

    new_text = re.sub(
        r"^### (?:✅|🟡|⬜|🚫|🔍) Week (\d+) — (.+?)$",
        replace_heading,
        text,
        flags=re.MULTILINE,
    )
    if new_text != text:
        PROGRESS_DOC.write_text(new_text)
    return n


def update_readme(week: int, pct: int):
    text = README.read_text()
    color = color_for(pct)

    # Overall progress: weeks with status < current are "Done". For
    # current_week=N, that's N-1 closed weeks. Color is fixed
    # brightgreen (project-alive indicator, not a completion bucket).
    closed_weeks = max(0, week - 1)

    new_overall_badge = (f"![Progress](https://img.shields.io/badge/"
                         f"progress-{closed_weeks}%2F{TOTAL_WEEKS}_weeks-brightgreen)")
    new_week_badge = f"![Current Week](https://img.shields.io/badge/current_week-{week}-blue)"
    new_pct_badge  = (f"![Week {week} Progress]"
                      f"(https://img.shields.io/badge/week_{week}_progress-{pct}%25-{color})")

    # Replace existing lines if present, else insert after the Progress badge
    text, n_o = re.subn(r"!\[Progress\]\([^)]+\)", new_overall_badge, text)
    text, n_w = re.subn(r"!\[Current Week\]\([^)]+\)", new_week_badge, text)
    text, n_p = re.subn(r"!\[Week \d+ Progress\]\([^)]+\)", new_pct_badge, text)

    if n_w == 0 or n_p == 0:
        # Insert just after the Progress badge line
        anchor = re.search(r"^(!\[Progress\]\([^)]+\))", text, re.MULTILINE)
        if not anchor:
            sys.exit("ERROR: could not find Progress badge to anchor insertion")
        insertion = "\n" + new_week_badge + "\n" + new_pct_badge
        text = text[:anchor.end()] + insertion + text[anchor.end():]

    text, n_rows = update_progress_table(text, week)

    README.write_text(text)
    return n_rows


def main():
    week = int(sys.argv[1]) if len(sys.argv) > 1 else detect_current_week()
    week_path = DOCS / f"week_{week:02d}.md"
    if not week_path.exists():
        sys.exit(f"ERROR: {week_path} not found")

    done, total = count_checklist(week_path)
    pct = int(round(100 * done / total)) if total else 0

    print(f"Week {week}: {done}/{total} done ({pct}%)")
    n_rows = update_readme(week, pct)
    print(f"Updated badges in {README.relative_to(ROOT)} ({n_rows} progress-table rows)")
    n_headings = update_progress_doc(week)
    if n_headings:
        print(f"Updated headings in {PROGRESS_DOC.relative_to(ROOT)} ({n_headings} week headings)")


if __name__ == "__main__":
    main()
