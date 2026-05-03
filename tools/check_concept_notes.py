#!/usr/bin/env python3
"""
check_concept_notes.py — lint every docs/concepts/*.md note.

Enforces the minimum bar from the plan (CLAUDE.md §6 cross-reference):

    1. File ≥ 30 lines.
    2. H1 heading present and matches filename slug
       (filename `foo_bar.md` → H1 should reference "foo bar" or
       sensible title; we just check H1 is the first non-blank line).
    3. At least one citation: a recognisable book reference like
       "ch.N", "§N.N", "pp. NN" OR an "http(s)://" URL.
    4. At least one fenced code block (```), or an ASCII/mermaid
       diagram (we accept any line beginning with "│" "├" "└" "┌"
       or a ```mermaid block).
    5. Notes whose top frontmatter or first-line text says "authored"
       must additionally have ≥ 150 words of prose (excluding code
       blocks).

Exit code 0 = all notes compliant; 1 = at least one violation.

Usage:
    python3 tools/check_concept_notes.py
    python3 tools/check_concept_notes.py --quiet
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONCEPTS = ROOT / "docs" / "concepts"

CITATION_RE = re.compile(
    r"(ch\.\s*\w+"           # "ch.7", "ch.A1"
    r"|§\s*\d+"               # "§5.2"
    r"|pp\.\s*\d+"            # "pp. 237"
    r"|https?://\S+"          # any URL
    r"|SNUG-?\d+"             # Cummings SNUG papers
    r"|UG\d+"                 # Xilinx UG903, UG949, UG908
    r"|XAPP\d+"               # Xilinx app notes
    r"|IHI\d+\w*"             # ARM AMBA spec IDs
    r"|IEEE\s+\d+"            # IEEE standards
    r"|RV\d+I"                # RISC-V ISA refs
    r"|riscv\.org"            # RISC-V site
    r"|cummings\.com"         # Cummings papers site
    r"|dspguide\.com"         # Smith DSP guide
    r"|verificationacademy"   # VA cookbook
    r"|yosyshq"               # Yosys docs
    r"|arm\.com"              # ARM specs
    r"|nandland"              # SPI/UART tutorials
    r")",
    re.IGNORECASE,
)
DIAGRAM_LINE_RE = re.compile(r"^[\s]*[│├└┌┐┘─]")  # ASCII box-drawing
FENCED_CODE_RE = re.compile(r"^```", re.MULTILINE)
H1_RE = re.compile(r"^#\s+\S", re.MULTILINE)
TYPE_RE = re.compile(r"\*\*Type\*\*:\s*(authored|auto-stub)", re.IGNORECASE)


def word_count_excluding_code(text: str) -> int:
    """Count words outside fenced code blocks."""
    out: list[str] = []
    in_code = False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            in_code = not in_code
            continue
        if not in_code:
            out.append(line)
    return len(re.findall(r"\b\w+\b", "\n".join(out)))


def check_one(note: Path, quiet: bool = False) -> list[str]:
    violations: list[str] = []
    text = note.read_text()
    rel = note.relative_to(ROOT)

    # 1. Min 30 lines
    n_lines = len(text.splitlines())
    if n_lines < 30:
        violations.append(f"{rel}: only {n_lines} lines (need ≥30)")

    # 2. H1 present
    if not H1_RE.search(text):
        violations.append(f"{rel}: no H1 heading found")

    # 3. At least one citation (book ref or URL)
    if not CITATION_RE.search(text):
        violations.append(f"{rel}: no book/URL citation found")

    # 4. At least one fenced code block OR ASCII/mermaid diagram
    has_code = bool(FENCED_CODE_RE.search(text))
    has_diagram = any(DIAGRAM_LINE_RE.match(ln) for ln in text.splitlines())
    if not (has_code or has_diagram):
        violations.append(f"{rel}: no code block or diagram found")

    # 5. Authored notes need ≥150 words of prose
    type_match = TYPE_RE.search(text)
    if type_match and type_match.group(1).lower() == "authored":
        wc = word_count_excluding_code(text)
        if wc < 150:
            violations.append(f"{rel}: authored note has only {wc} words of prose (need ≥150)")

    if not violations and not quiet:
        kind = type_match.group(1) if type_match else "?"
        print(f"OK   {rel} ({n_lines} lines, type={kind})")
    for v in violations:
        print(f"FAIL {v}")

    return violations


def main() -> int:
    quiet = "--quiet" in sys.argv

    if not CONCEPTS.exists():
        print(f"ERROR: {CONCEPTS} does not exist", file=sys.stderr)
        return 1

    notes = sorted(CONCEPTS.glob("*.md"))
    if not notes:
        print(f"ERROR: no concept notes in {CONCEPTS}", file=sys.stderr)
        return 1

    if not quiet:
        print(f"Checking {len(notes)} concept note(s) under {CONCEPTS.relative_to(ROOT)}/")

    all_violations: list[str] = []
    for n in notes:
        all_violations.extend(check_one(n, quiet=quiet))

    print()
    if all_violations:
        print(f"FAILED: {len(all_violations)} violation(s)")
        return 1
    print(f"PASSED: {len(notes)} concept note(s) compliant")
    return 0


if __name__ == "__main__":
    sys.exit(main())
