#!/usr/bin/env bash
# ============================================================================
# run_yosys_slang.sh — Yosys synth + schematic using the SLANG plugin.
#
# Use this INSTEAD of run_yosys_rtl.sh when your design uses modern SV
# features that Yosys's built-in Verilog parser doesn't support:
#   - typedef'd packed structs as port types
#   - import pkg::* / packages with typedefs
#   - generate-style code with SV idioms
#   - interfaces with non-trivial modports
#   - struct expressions '{...} in non-trivial places
#
# Usage:
#     ./run_yosys_slang.sh <top_file.sv>
#
# Compiles every *.svh and *.sv file in the same directory as <top_file.sv>
# (svh first — packages before consumers), uses the basename of <top_file.sv>
# as the top module, runs Yosys's generic synthesis (no tech-mapping —
# pure RTL view), and writes:
#   <dir>/build_rtl/<top>.svg     ← schematic, opens in browser
#   <dir>/build_rtl/<top>.log     ← yosys output
#
# REQUIRES: yosys-slang plugin (https://github.com/povik/yosys-slang).
# If not installed, the script prints install instructions and exits 2.
# ============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <top_file.sv>"
    exit 1
fi

TOP_FILE="$1"
if [[ ! -f "$TOP_FILE" ]]; then
    echo "Error: file not found: $TOP_FILE"
    exit 1
fi

TOP_ABS="$(cd "$(dirname "$TOP_FILE")" && pwd)/$(basename "$TOP_FILE")"
TOP_DIR="$(dirname "$TOP_ABS")"
TOP_NAME="$(basename "$TOP_FILE" .sv)"
OUT_DIR="$TOP_DIR/build_rtl"

mkdir -p "$OUT_DIR"

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ── Plugin probe — fail fast with install instructions if slang is missing ──
if ! yosys -q -p "plugin -i slang; quit" >/dev/null 2>&1; then
    echo -e "${RED}✗ yosys-slang plugin not loaded${NC}"
    echo ""
    echo "Install instructions (macOS, Homebrew Yosys):"
    echo ""
    echo "  # 1. Build prerequisites"
    echo "  brew install yosys cmake ninja"
    echo ""
    echo "  # 2. Clone & build yosys-slang"
    echo "  git clone --recurse-submodules https://github.com/povik/yosys-slang.git"
    echo "  cd yosys-slang"
    echo "  make -j"
    echo "  make install         # installs slang.so next to yosys plugins"
    echo ""
    echo "  # 3. Verify"
    echo "  yosys -p 'plugin -i slang; quit'"
    echo ""
    echo "Reference: https://github.com/povik/yosys-slang"
    echo ""
    echo "Workaround for simple designs without modern SV: use the regular"
    echo "task '🔧 RTL SCHEMATIC (yosys synth + schematic of current file)'"
    echo "which uses Yosys's built-in Verilog parser."
    exit 2
fi

add_white_bg() {
    local svg="$1"
    [[ -f "$svg" ]] || return 0
    python3 - "$svg" <<'PYEOF'
import sys, re
p = sys.argv[1]
with open(p) as f:
    s = f.read()
s = re.sub(r'(<svg[^>]*?>)', r'\1<rect width="100%" height="100%" fill="white"/>', s, count=1, flags=re.DOTALL)
with open(p, 'w') as f:
    f.write(s)
PYEOF
}

# Collect *.svh first (packages must be analyzed before consumer modules),
# then every *.sv. Skip files that aren't synthesizable:
#   - *_tb.sv / tb_*.sv : testbenches
#   - *_if.sv  / if_*.sv : TB-side interfaces (clocking blocks)
#   - any file with a `clocking` block
shopt -s nullglob
SVH_FILES=()
SV_FILES=()
for f in "$TOP_DIR"/*.svh; do
    SVH_FILES+=("$f")
done
for f in "$TOP_DIR"/*.sv; do
    base="$(basename "$f")"
    case "$base" in
        *_tb.sv|tb_*.sv) continue ;;
        *_if.sv|if_*.sv) continue ;;
    esac
    if grep -qE '^[[:space:]]*clocking[[:space:]]+[A-Za-z_]' "$f"; then
        continue
    fi
    SV_FILES+=("$f")
done
shopt -u nullglob

ALL_FILES=()
[[ ${#SVH_FILES[@]} -gt 0 ]] && ALL_FILES+=("${SVH_FILES[@]}")
[[ ${#SV_FILES[@]}  -gt 0 ]] && ALL_FILES+=("${SV_FILES[@]}")

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
    echo "Error: no synthesizable .sv/.svh files found in $TOP_DIR"
    echo "       (TBs and clocking-block interfaces were filtered out)"
    exit 1
fi

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${YELLOW}Yosys + slang RTL synthesis + schematic${CYAN}             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}  Top module:${NC} $TOP_NAME"
echo -e "${CYAN}  Files:${NC}      ${ALL_FILES[*]##*/}"
echo -e "${CYAN}  Output:${NC}     $OUT_DIR/"
echo ""

# Hierarchical view via slang frontend.
# The slang plugin replaces 'read_verilog' with 'read_slang', which handles
# the full SV-2017 grammar that Yosys's built-in parser can't.
yosys -q -l "$OUT_DIR/$TOP_NAME.log" -p "
    plugin -i slang;
    read_slang ${ALL_FILES[*]};
    hierarchy -top $TOP_NAME;
    proc;
    opt;
    show -format svg -prefix $OUT_DIR/$TOP_NAME -colors 1 -viewer false $TOP_NAME;
"

if [[ -f "$OUT_DIR/$TOP_NAME.svg" ]]; then
    add_white_bg "$OUT_DIR/$TOP_NAME.svg"
    echo -e "${GREEN}✓ Hierarchical schematic:${NC} $OUT_DIR/$TOP_NAME.svg"
    open "$OUT_DIR/$TOP_NAME.svg" 2>/dev/null || true
fi

echo -e "\n${GREEN}✓ Done${NC}"
