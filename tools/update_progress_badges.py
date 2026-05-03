#!/usr/bin/env python3
"""
update_progress_badges.py — recompute the README badges from the docs.

Reads docs/week_NN.md for the current week (passed as arg or detected from
the most recently modified docs/week_*.md), counts checked vs total
checklist items, and rewrites the two dynamic shields.io badges in
README.md:

    ![Current Week](https://img.shields.io/badge/current_week-N-blue)
    ![Week N Progress](https://img.shields.io/badge/week_N_progress-XX%25-COLOR)

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


def latest_week() -> int:
    """Pick the most recently modified docs/week_NN.md as 'current'."""
    weeks = sorted(DOCS.glob("week_*.md"),
                   key=lambda p: p.stat().st_mtime, reverse=True)
    if not weeks:
        sys.exit("ERROR: no docs/week_*.md files found")
    m = re.search(r"week_(\d+)\.md", weeks[0].name)
    return int(m.group(1))


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


def update_readme(week: int, pct: int):
    text = README.read_text()
    color = color_for(pct)

    # Rebuild the two dynamic lines
    new_week_badge = f"![Current Week](https://img.shields.io/badge/current_week-{week}-blue)"
    new_pct_badge  = (f"![Week {week} Progress]"
                      f"(https://img.shields.io/badge/week_{week}_progress-{pct}%25-{color})")

    # Replace existing lines if present, else insert after the Progress badge
    text, n_w = re.subn(r"!\[Current Week\]\([^)]+\)", new_week_badge, text)
    text, n_p = re.subn(r"!\[Week \d+ Progress\]\([^)]+\)", new_pct_badge, text)

    if n_w == 0 or n_p == 0:
        # Insert just after the Progress badge line
        anchor = re.search(r"^(!\[Progress\]\([^)]+\))", text, re.MULTILINE)
        if not anchor:
            sys.exit("ERROR: could not find Progress badge to anchor insertion")
        insertion = "\n" + new_week_badge + "\n" + new_pct_badge
        text = text[:anchor.end()] + insertion + text[anchor.end():]

    README.write_text(text)


def main():
    week = int(sys.argv[1]) if len(sys.argv) > 1 else latest_week()
    week_path = DOCS / f"week_{week:02d}.md"
    if not week_path.exists():
        sys.exit(f"ERROR: {week_path} not found")

    done, total = count_checklist(week_path)
    pct = int(round(100 * done / total)) if total else 0

    print(f"Week {week}: {done}/{total} done ({pct}%)")
    update_readme(week, pct)
    print(f"Updated badges in {README.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
