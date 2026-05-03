#!/usr/bin/env bash
# ============================================================================
# lint_interface.sh — lint a SystemVerilog interface in isolation
#
# Verilator's `-Wall` flags every interface signal as UNUSEDSIGNAL when
# the interface is linted alone, because there's no module driving or
# consuming the wires. Those warnings are noise — they'd disappear the
# moment any DUT or TB instantiates the interface.
#
# This script suppresses **only** the noise classes:
#   - UNUSEDSIGNAL : interface signals have no consumer in isolation
#   - UNDRIVEN     : interface signals have no driver in isolation
#   - DECLFILENAME : a single file may declare both the interface and helper
#                    modules; tools normally want filename = module
#
# Real bugs that DO still surface:
#   - syntax errors (semicolons in modport bodies, etc.)
#   - undeclared identifiers (typos in signal names)
#   - direction mismatches between modports
#   - clocking block direction errors
#   - signals listed in a modport but never declared
#
# Usage:
#   ./lint_interface.sh <interface_file.sv>
#   ./lint_interface.sh <iface.sv> [more_files.sv ...]
#
# Examples:
#   ./lint_interface.sh week_04_uvm_architecture/.../alu_if.sv
#   ./lint_interface.sh shared_pkg.sv alu_if.sv mem_if.sv
# ============================================================================

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <interface_file.sv> [more_files.sv ...]"
    exit 1
fi

# ── Sanity-check inputs ─────────────────────────────────────────────────
for f in "$@"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: file not found: $f"
        exit 1
    fi
done

# ── Detect first interface name (used as --top-module for Verilator) ────
TOP=""
for f in "$@"; do
    name=$(grep -oE '^[[:space:]]*interface[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$f" 2>/dev/null \
           | head -1 | awk '{print $NF}')
    if [[ -n "$name" && -z "$TOP" ]]; then
        TOP="$name"
    fi
done

if [[ -z "$TOP" ]]; then
    echo "Error: no 'interface <name>' declaration found in input file(s)"
    exit 1
fi

# ── Pretty header ───────────────────────────────────────────────────────
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${YELLOW}SystemVerilog interface lint${CYAN}                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}  Top:${NC}   $TOP"
echo -e "${CYAN}  Files:${NC} $*"
echo ""

# ── Verilator: -Wall minus the two noise classes ────────────────────────
echo -e "${CYAN}── Verilator (--lint-only -Wall) ──${NC}"
RC=0
verilator --lint-only \
    -Wall \
    -Wno-UNUSEDSIGNAL \
    -Wno-UNDRIVEN \
    -Wno-DECLFILENAME \
    --top-module "$TOP" \
    "$@" \
    || RC=$?

echo ""
if [[ $RC -eq 0 ]]; then
    echo -e "${GREEN}✓ Interface lint clean${NC}"
else
    echo -e "${RED}✗ Verilator reported issues (exit $RC)${NC}"
    echo "  Fix the errors above; re-run when ready."
fi

# ── iverilog parse-only as a second opinion ────────────────────────────
# Known iverilog 13 limitations:
#   - clocking blocks have only partial support — an interface that USES
#     a clocking block will report "Invalid module item" for every
#     clocking-block line. We detect and skip iverilog in that case.
#   - `modport <name> (clocking <cb>)` reports a "sorry" message even
#     when iverilog otherwise accepts the file; we filter that.
echo ""
echo -e "${CYAN}── iverilog (parse-only, second opinion) ──${NC}"

# Detect clocking block in the input files
HAS_CLOCKING=0
for f in "$@"; do
    if grep -qE '^[[:space:]]*clocking[[:space:]]+[A-Za-z_]' "$f"; then
        HAS_CLOCKING=1
        break
    fi
done

IV_RC=0
if [[ $HAS_CLOCKING -eq 1 ]]; then
    echo -e "${YELLOW}  skipped — clocking block present; iverilog 13 cannot parse${NC}"
    echo -e "${YELLOW}  it. Verilator above is the primary lint for clocking-block${NC}"
    echo -e "${YELLOW}  interfaces. (Use Vivado xsim for full verification.)${NC}"
else
    IV_RAW=$(iverilog -g2012 -t null "$@" 2>&1) || true
    IV_FILT=$(echo "$IV_RAW" | grep -v "sorry: modport clocking declaration is not yet supported" || true)

    if echo "$IV_FILT" | grep -qE "(error|syntax error|Malformed)"; then
        IV_RC=1
    fi

    if [[ -n "$IV_FILT" ]]; then
        echo "$IV_FILT"
    fi

    if [[ $IV_RC -eq 0 ]]; then
        echo -e "${GREEN}✓ iverilog parse OK${NC}"
    else
        echo -e "${RED}✗ iverilog reported issues${NC}"
    fi
fi

# ── Final exit code: fail if EITHER tool found a real issue ─────────────
if [[ $RC -ne 0 || $IV_RC -ne 0 ]]; then
    exit 1
fi
exit 0
