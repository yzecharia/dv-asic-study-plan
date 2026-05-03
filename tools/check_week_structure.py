#!/usr/bin/env python3
"""
check_week_structure.py — lint every week_NN_*/ folder.

Verifies each `week_NN_*/` folder contains the five daily-driver files
required by CLAUDE.md §6:

    README.md
    learning_assignment.md
    homework.md
    checklist.md
    notes.md

Also verifies the canonical syllabus `docs/week_NN.md` exists for each
folder, since the daily-driver files cite it.

Exit code 0 = all weeks compliant; 1 = at least one violation.

Usage:
    python3 tools/check_week_structure.py
    python3 tools/check_week_structure.py --quiet   # only print failures
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


def find_week_folders() -> list[Path]:
    return sorted(p for p in ROOT.glob("week_*") if p.is_dir())


def check_one(week_dir: Path, quiet: bool = False) -> list[str]:
    """Return a list of violation messages (empty if compliant)."""
    violations: list[str] = []
    m = re.match(r"week_(\d+)_", week_dir.name)
    if not m:
        violations.append(f"{week_dir.name}: folder name does not match week_NN_<slug>")
        return violations

    week_num = int(m.group(1))

    # Required daily-driver files
    for fname in REQUIRED_FILES:
        if not (week_dir / fname).exists():
            violations.append(f"{week_dir.name}/{fname}: MISSING")

    # Canonical syllabus
    canonical = DOCS / f"week_{week_num:02d}.md"
    if not canonical.exists():
        violations.append(f"{canonical.relative_to(ROOT)}: MISSING (canonical syllabus)")

    if not violations and not quiet:
        print(f"OK  {week_dir.name}")
    for v in violations:
        print(f"FAIL {v}")
    return violations


def main() -> int:
    quiet = "--quiet" in sys.argv

    week_dirs = find_week_folders()
    if not week_dirs:
        print("ERROR: no week_*/ folders found", file=sys.stderr)
        return 1

    if not quiet:
        print(f"Checking {len(week_dirs)} week folder(s) under {ROOT.name}/")

    all_violations: list[str] = []
    for w in week_dirs:
        all_violations.extend(check_one(w, quiet=quiet))

    print()
    if all_violations:
        print(f"FAILED: {len(all_violations)} violation(s)")
        return 1
    print(f"PASSED: {len(week_dirs)} week folder(s) compliant")
    return 0


if __name__ == "__main__":
    sys.exit(main())
