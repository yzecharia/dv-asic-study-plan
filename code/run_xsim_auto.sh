#!/usr/bin/env bash
# ============================================================================
# run_xsim_auto.sh — wrapper around run_xsim.sh that auto-includes every
# *_pkg.sv file sitting next to the testbench file.
#
# Usage:
#     ./run_xsim_auto.sh <tb_file.sv>
#
# Any *_pkg.sv files in the same directory as <tb_file.sv> are prepended to
# the xvlog command line so packages are compiled before the TB that imports
# them.  The TB file itself is excluded from the auto-glob so you can still
# run a file called "foo_pkg.sv" directly without passing it twice.
# ============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <tb_file.sv>"
    exit 1
fi

TB_FILE="$1"
if [[ ! -f "$TB_FILE" ]]; then
    echo "Error: File not found: $TB_FILE"
    exit 1
fi

TB_ABS="$(cd "$(dirname "$TB_FILE")" && pwd)/$(basename "$TB_FILE")"
TB_DIR="$(dirname "$TB_ABS")"

# Collect sibling *_pkg.sv files (excluding the TB itself)
PKGS=()
shopt -s nullglob
for f in "$TB_DIR"/*_pkg.sv; do
    if [[ "$f" != "$TB_ABS" ]]; then
        PKGS+=("$f")
    fi
done
shopt -u nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run_xsim.sh" "${PKGS[@]}" "$TB_FILE"
