#!/usr/bin/env bash
# ============================================================================
# run_xsim_folder.sh — compile every *.sv in the current file's directory.
#
# Usage:
#     ./run_xsim_folder.sh <any_file_in_the_folder.sv>
#
# Every *.sv AND *.svh file in the same directory as the argument is passed
# to run_xsim.sh. Compile order (handles cross-file dependencies):
#   1. Files containing 'package <name>;' declarations (any extension)
#   2. Other *.svh files (typically `define-only headers or non-package decls)
#   3. Other *.sv files
#   4. The argument file LAST (so it becomes the top module)
#
# Use this for multi-file class-based testbenches like:
#   factory_demo/
#     ├── animal.svh
#     ├── lion.svh
#     ├── chicken.svh
#     ├── factory_demo_pkg.sv
#     └── factory_demo_top.sv   ← invoke with this as the argument
#
# Package detection: grep for ^\s*package\s+<id>\s*;. This makes alphabetical
# filename ordering irrelevant — an interface in alu_if.svh can safely
# import alu_pkg even when alu_pkg.svh sorts later.
# ============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <any_file.sv>"
    exit 1
fi

TB_FILE="$1"
if [[ ! -f "$TB_FILE" ]]; then
    echo "Error: File not found: $TB_FILE"
    exit 1
fi

TB_ABS="$(cd "$(dirname "$TB_FILE")" && pwd)/$(basename "$TB_FILE")"
TB_DIR="$(dirname "$TB_ABS")"

# Collect by category: packages (any extension), other .svh, other .sv,
# then the TB last. Package detection is by `^\s*package\s+<id>\s*;` keyword,
# not filename — so 'alu_pkg.svh' or 'alu_pkg.sv' both sort to the front
# even though they alphabetize AFTER 'alu_if.*'.
PKGS=()
SVH_FILES=()
SV_FILES=()
shopt -s nullglob
for f in "$TB_DIR"/*.svh "$TB_DIR"/*.sv; do
    [[ "$f" == "$TB_ABS" ]] && continue
    if grep -qE '^[[:space:]]*package[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*;' "$f"; then
        PKGS+=("$f")
    elif [[ "$f" == *.svh ]]; then
        SVH_FILES+=("$f")
    else
        SV_FILES+=("$f")
    fi
done
shopt -u nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ${arr[@]+"${arr[@]}"} expands safely under `set -u` when the array is empty.
exec "$SCRIPT_DIR/run_xsim.sh" \
    ${PKGS[@]+"${PKGS[@]}"} \
    ${SVH_FILES[@]+"${SVH_FILES[@]}"} \
    ${SV_FILES[@]+"${SV_FILES[@]}"} \
    "$TB_FILE"
