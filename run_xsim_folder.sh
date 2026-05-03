#!/usr/bin/env bash
# ============================================================================
# run_xsim_folder.sh — compile every *.sv in the current file's directory.
#
# Usage:
#     ./run_xsim_folder.sh <any_file_in_the_folder.sv>
#
# All *.sv files in the same directory as the argument are passed to
# run_xsim.sh. Compile order:
#   1. *_pkg.sv     (packages — anything that defines types/classes used elsewhere)
#   2. everything else, with the argument file LAST (so it becomes the top module)
#
# Use this for multi-file class-based testbenches like:
#   factory_demo/
#     ├── animal.svh
#     ├── lion.svh
#     ├── chicken.svh
#     ├── factory_demo_pkg.sv
#     └── factory_demo_top.sv   ← invoke with this as the argument
#
# *.svh files are NOT compiled directly (they're `\`include`d from .sv files).
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

# Collect packages first, then everything else (excluding TB), then TB last.
PKGS=()
OTHERS=()
shopt -s nullglob
for f in "$TB_DIR"/*_pkg.sv; do
    PKGS+=("$f")
done
for f in "$TB_DIR"/*.sv; do
    [[ "$f" == "$TB_ABS" ]] && continue
    [[ "$f" == *"_pkg.sv" ]] && continue
    OTHERS+=("$f")
done
shopt -u nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ${arr[@]+"${arr[@]}"} expands safely under `set -u` when the array is empty.
exec "$SCRIPT_DIR/run_xsim.sh" \
    ${PKGS[@]+"${PKGS[@]}"} \
    ${OTHERS[@]+"${OTHERS[@]}"} \
    "$TB_FILE"
