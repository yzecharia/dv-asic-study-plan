#!/usr/bin/env bash
# ============================================================================
# run_xsim_uvm_compile_auto.sh - wrapper around run_xsim_uvm_compile.sh that
# auto-includes every *_pkg.sv / *_pkg.svh sibling sitting next to the TB.
#
# Usage:
#     ./run_xsim_uvm_compile_auto.sh <tb_file.sv>
#
# Mirrors run_xsim_auto.sh but for the UVM compile-and-keep-snapshot flow.
# Used from the VS Code task "UVM COMPILE".
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

PKGS=()
shopt -s nullglob
for f in "$TB_DIR"/*_pkg.sv "$TB_DIR"/*_pkg.svh; do
    if [[ "$f" != "$TB_ABS" ]]; then
        PKGS+=("$f")
    fi
done
shopt -u nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${#PKGS[@]} -gt 0 ]]; then
    exec "$SCRIPT_DIR/run_xsim_uvm_compile.sh" "${PKGS[@]}" "$TB_FILE"
else
    exec "$SCRIPT_DIR/run_xsim_uvm_compile.sh" "$TB_FILE"
fi
