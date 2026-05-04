#!/usr/bin/env python3
"""
sync_drill_status.py — flip ⬜ TODO → ✅ DONE in each week_NN_*/homework.md
based on the per-week checklist.md ticks.

Strategy
--------
Parse checklist.md for ticked items (lines like `- [x] some text`).
For every drill row / heading in homework.md still marked `⬜ TODO`,
check if any ticked item *describes* it. If yes, flip to `✅ DONE`.

Two homework.md formats are recognised:

1. **Markdown table rows** — `| Name | path | ⬜ TODO | acceptance |`.
   Match the first column (Name) against ticked items.

2. **Section headings** — `### \`path\` ⬜ TODO` (or similar).
   Match the heading text (path or short label) against ticked items.

Matching is case-insensitive substring: if the homework label appears
inside a ticked item, that's a match. The reverse direction (ticked
item appearing in the homework label) also matches, which lets you
write either form.

This is intentionally fuzzy — the user's checklist phrasing is
human-friendly, not machine-strict. False matches are rare in
practice because drill names are distinctive ("Dally ch.10", "HW1: ALU
DUT", etc.). False misses are recovered by editing the homework.md
manually.

Idempotent: running multiple times after no checklist changes is a
no-op.

Usage
-----
    python3 tools/sync_drill_status.py            # all weeks
    python3 tools/sync_drill_status.py 4 5        # selected weeks
    python3 tools/sync_drill_status.py --check    # dry-run

Wired into sync_week_docs.py so a normal sync flips drill statuses
automatically. You should not normally need to call this directly.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TODO = "⬜ TODO"
DONE = "✅ DONE"

# Match a fully-checked item line (allow leading whitespace, then `- [x]`).
TICKED_RE = re.compile(r"^\s*-\s*\[x\]\s+(.+?)\s*$", re.IGNORECASE)

# Match a markdown table row whose 3rd column is exactly `⬜ TODO`.
TABLE_ROW_RE = re.compile(
    r"^(\|\s*)([^|]+?)(\s*\|\s*)([^|]+?)(\s*\|\s*)" + re.escape(TODO) + r"(\s*\|.*)$",
    re.MULTILINE,
)

# Match a markdown heading line ending in `⬜ TODO`.
HEADING_RE = re.compile(
    r"^(#{1,6}\s+.+?)\s*" + re.escape(TODO) + r"\s*$",
    re.MULTILINE,
)


def normalize(s: str) -> str:
    """Lowercase and collapse separator-chars (-, _, /, `, ., :) to spaces.
    Path-style strings and human-readable strings then have a chance of
    sharing a substring."""
    s = s.lower()
    s = re.sub(r"[-_/`.:,()\[\]]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def parse_ticked(checklist_path: Path) -> list[str]:
    if not checklist_path.exists():
        return []
    items = []
    for line in checklist_path.read_text().splitlines():
        m = TICKED_RE.match(line)
        if m:
            items.append(normalize(m.group(1)))
    return items


def match(label: str, ticked: list[str]) -> bool:
    """True if `label` describes one of the ticked items, fuzzily.
    Normalisation collapses path separators / hyphens / underscores so
    `homework/design/big_picture/shift_add_multiplier/...` and
    `HW2: shift-add multiplier` share enough words to match.
    """
    label_n = normalize(label)
    if not label_n:
        return False
    for item in ticked:
        if label_n in item or item in label_n:
            return True
    return False


def update_homework(homework_path: Path, ticked: list[str]) -> int:
    if not homework_path.exists() or not ticked:
        return 0
    text = homework_path.read_text()
    n = 0

    def table_repl(m: re.Match) -> str:
        nonlocal n
        name = m.group(2)
        if match(name, ticked):
            n += 1
            return f"{m.group(1)}{m.group(2)}{m.group(3)}{m.group(4)}{m.group(5)}{DONE}{m.group(6)}"
        return m.group(0)

    def heading_repl(m: re.Match) -> str:
        nonlocal n
        heading = m.group(1)
        # Strip the leading hashes and any backticks/spaces for matching
        clean = re.sub(r"^#+\s*", "", heading).strip().strip("`")
        if match(clean, ticked):
            n += 1
            return f"{heading} {DONE}"
        return m.group(0)

    text = TABLE_ROW_RE.sub(table_repl, text)
    text = HEADING_RE.sub(heading_repl, text)

    if n > 0:
        homework_path.write_text(text)
    return n


def find_week_folders() -> list[tuple[int, Path]]:
    out = []
    for p in sorted(ROOT.glob("week_*")):
        if not p.is_dir() or any(part == "archive" for part in p.parts):
            continue
        m = re.match(r"week_(\d+)_", p.name)
        if m:
            out.append((int(m.group(1)), p))
    return out


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--check"]
    dry = "--check" in sys.argv
    weeks_filter = {int(a) for a in args} if args else None

    total = 0
    weeks = find_week_folders()
    for num, week_dir in weeks:
        if weeks_filter is not None and num not in weeks_filter:
            continue

        checklist_path = week_dir / "checklist.md"
        homework_path = week_dir / "homework.md"

        ticked = parse_ticked(checklist_path)

        if dry:
            # Re-parse and count without writing
            if not homework_path.exists() or not ticked:
                print(f"  w{num:02d}: 0 (skip)")
                continue
            text = homework_path.read_text()
            n_table = sum(
                1 for m in TABLE_ROW_RE.finditer(text) if match(m.group(2), ticked)
            )
            n_head = sum(
                1
                for m in HEADING_RE.finditer(text)
                if match(re.sub(r"^#+\s*", "", m.group(1)).strip().strip("`"), ticked)
            )
            n = n_table + n_head
            print(f"  w{num:02d}: would flip {n}")
            total += n
        else:
            n = update_homework(homework_path, ticked)
            print(f"  w{num:02d}: flipped {n}")
            total += n

    verb = "Would flip" if dry else "Flipped"
    print(f"\n{verb} {total} drill status row(s) total.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
