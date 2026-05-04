#!/usr/bin/env python3
"""
sync_week_docs.py — concatenate per-week daily-driver files into
docs/week_NN.md so the canonical doc is a single-source view.

For each week_NN_*/ folder, reads:
    README.md, learning_assignment.md, homework.md, checklist.md, notes.md
and appends them into docs/week_NN.md under a clearly-marked
auto-generated section.

Re-running OVERWRITES only the auto-generated section. Content above
the marker is preserved verbatim — that's the canonical syllabus,
manually edited.

Marker: <!-- AUTO-SYNC: per-week views below ... -->

The badge script (tools/update_progress_badges.py) is aware of the
marker and stops counting checkboxes at it, so per-week duplicates
don't double-count toward progress.

Usage:
    python3 tools/sync_week_docs.py             # sync every week
    python3 tools/sync_week_docs.py 4 5 6       # sync specific weeks
    python3 tools/sync_week_docs.py --check     # dry-run, list what would change
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

MARKER_LINE = "<!-- AUTO-SYNC: per-week views below — regenerate via tools/sync_week_docs.py; do not edit by hand below this line -->"
MARKER_PREFIX = "<!-- AUTO-SYNC:"

PER_WEEK_FILES = (
    "README.md",
    "learning_assignment.md",
    "homework.md",
    "checklist.md",
    "notes.md",
)


def find_week_folders() -> list[tuple[int, Path]]:
    out: list[tuple[int, Path]] = []
    for p in sorted(ROOT.glob("week_*")):
        if not p.is_dir():
            continue
        if any(part == "archive" for part in p.parts):
            continue
        m = re.match(r"week_(\d+)_", p.name)
        if m:
            out.append((int(m.group(1)), p))
    return out


def assemble_per_week_block(week_dir: Path) -> str:
    parts = [
        "\n\n",
        MARKER_LINE,
        "\n\n## Daily-driver views",
        f"\n\n*Auto-mirrored from `{week_dir.name}/` — edit those files,",
        " then run `python3 tools/sync_week_docs.py` to refresh this section.*\n",
    ]
    for fname in PER_WEEK_FILES:
        f = week_dir / fname
        if not f.exists():
            continue
        content = f.read_text().rstrip()
        parts.append(f"\n\n---\n\n### `{fname}`\n\n{content}\n")
    return "".join(parts)


def split_at_marker(text: str) -> str:
    idx = text.find(MARKER_PREFIX)
    if idx < 0:
        return text.rstrip()
    return text[:idx].rstrip()


def sync_one(week_num: int, week_dir: Path, dry_run: bool = False) -> bool:
    canonical = DOCS / f"week_{week_num:02d}.md"
    if not canonical.exists():
        print(f"SKIP w{week_num:02d}: {canonical.relative_to(ROOT)} not found")
        return False

    current = canonical.read_text()
    canonical_part = split_at_marker(current)
    new_content = canonical_part + assemble_per_week_block(week_dir) + "\n"

    n_files = sum(1 for f in PER_WEEK_FILES if (week_dir / f).exists())

    if dry_run:
        will_change = current != new_content
        flag = "WOULD UPDATE" if will_change else "unchanged   "
        print(f"{flag}  w{week_num:02d}: {n_files} per-week files")
        return will_change

    canonical.write_text(new_content)
    print(f"OK   w{week_num:02d}: appended {n_files} per-week files into {canonical.name}")
    return True


def main() -> int:
    args = sys.argv[1:]
    dry_run = "--check" in args
    args = [a for a in args if not a.startswith("--")]

    weeks_filter = {int(a) for a in args} if args else None

    weeks = find_week_folders()
    if not weeks:
        print("ERROR: no week_*/ folders found", file=sys.stderr)
        return 1

    # Step 1: flip drill statuses in homework.md based on checklist ticks.
    # Done BEFORE the doc-sync below so the appended homework.md reflects
    # the latest status emojis.
    try:
        import sync_drill_status  # type: ignore
    except ModuleNotFoundError:
        # Same dir import — load by path
        import importlib.util
        _spec = importlib.util.spec_from_file_location(
            "sync_drill_status", Path(__file__).parent / "sync_drill_status.py"
        )
        sync_drill_status = importlib.util.module_from_spec(_spec)  # type: ignore
        _spec.loader.exec_module(sync_drill_status)  # type: ignore

    print("── Drill-status sync ──")
    drill_total = 0
    for week_num, week_dir in weeks:
        if weeks_filter is not None and week_num not in weeks_filter:
            continue
        ticked = sync_drill_status.parse_ticked(week_dir / "checklist.md")
        if dry_run:
            text = (week_dir / "homework.md").read_text() if (week_dir / "homework.md").exists() else ""
            n_table = sum(
                1
                for m in sync_drill_status.TABLE_ROW_RE.finditer(text)
                if sync_drill_status.match(m.group(2), ticked)
            )
            n_head = sum(
                1
                for m in sync_drill_status.HEADING_RE.finditer(text)
                if sync_drill_status.match(
                    re.sub(r"^#+\s*", "", m.group(1)).strip().strip("`"), ticked
                )
            )
            n_drill = n_table + n_head
        else:
            n_drill = sync_drill_status.update_homework(week_dir / "homework.md", ticked)
        if n_drill > 0:
            verb = "would flip" if dry_run else "flipped"
            print(f"  w{week_num:02d}: {verb} {n_drill}")
        drill_total += n_drill

    # Step 2: append the per-week files into docs/week_NN.md.
    print("── Doc-sync ──")
    n = 0
    for week_num, week_dir in weeks:
        if weeks_filter is not None and week_num not in weeks_filter:
            continue
        if sync_one(week_num, week_dir, dry_run=dry_run):
            n += 1

    verb = "would update" if dry_run else "synced"
    print(f"\nDrill rows {('would-be-' if dry_run else '')}flipped: {drill_total}")
    print(f"{verb.capitalize()} {n} week(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
