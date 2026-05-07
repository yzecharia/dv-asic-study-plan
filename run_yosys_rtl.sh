#!/usr/bin/env bash
# ============================================================================
# run_yosys_rtl.sh — synthesize a SystemVerilog file with Yosys and produce
# an RTL schematic (.svg) that you can open in a browser.
#
# Usage:
#     ./run_yosys_rtl.sh <top_file.sv>
#
# Compiles every *.sv file in the same directory as <top_file.sv> together,
# uses the basename of <top_file.sv> as the top module, runs Yosys's
# generic synthesis (no tech-mapping — pure RTL view), and writes:
#   <dir>/build_rtl/<top>.svg     ← schematic, opens in browser
#   <dir>/build_rtl/<top>.dot     ← graphviz source (regenerate other formats)
#   <dir>/build_rtl/<top>.log     ← yosys output
#
# The script also writes a flattened version (everything inlined to gates)
# so you can compare hierarchical vs gate-level views.
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

# Collect every .sv file in the folder so dependencies (e.g. halfadder.sv
# next to fulladder.sv) compile together. Skip files Yosys cannot
# synthesize:
#   - *_tb.sv / tb_*.sv : testbenches (use $fatal/$urandom/tasks/int)
#   - *_if.sv  / if_*.sv : TB-side interfaces (often contain `clocking`)
#   - any file with a `clocking` block (Yosys cannot parse it at all)
shopt -s nullglob
SV_FILES=()
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

if [[ ${#SV_FILES[@]} -eq 0 ]]; then
    echo "Error: no synthesizable .sv files found in $TOP_DIR"
    echo "       (TBs and clocking-block interfaces were filtered out)"
    exit 1
fi

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${YELLOW}Yosys RTL synthesis + schematic${CYAN}                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}  Top module:${NC} $TOP_NAME"
echo -e "${CYAN}  Files:${NC}      ${SV_FILES[*]##*/}"
echo -e "${CYAN}  Output:${NC}     $OUT_DIR/"
echo ""

# Hierarchical view (preserves submodule boxes — read top-down)
yosys -q -l "$OUT_DIR/$TOP_NAME.log" -p "
    read_verilog -sv ${SV_FILES[*]};
    hierarchy -top $TOP_NAME;
    proc;
    opt;
    show -format svg -prefix $OUT_DIR/$TOP_NAME -colors 1 -viewer false $TOP_NAME;
"

# Gate-level view via netlistsvg — proper schematic with real gate symbols
# (AND has a flat back + rounded front, OR has a curved back, XOR adds an arc).
# Pipeline: yosys flattens + maps to gates → JSON → netlistsvg renders.
yosys -q -p "
    read_verilog -sv ${SV_FILES[*]};
    hierarchy -top $TOP_NAME;
    proc;
    flatten;
    opt;
    techmap;
    opt;
    write_json $OUT_DIR/${TOP_NAME}_gates.json;
" 2>/dev/null || true

if [[ -f "$OUT_DIR/${TOP_NAME}_gates.json" ]] && command -v netlistsvg >/dev/null; then
    netlistsvg "$OUT_DIR/${TOP_NAME}_gates.json" \
        -o "$OUT_DIR/${TOP_NAME}_gates.svg" 2>/dev/null || true
fi

if [[ -f "$OUT_DIR/$TOP_NAME.svg" ]]; then
    add_white_bg "$OUT_DIR/$TOP_NAME.svg"
    echo -e "${GREEN}✓ Hierarchical schematic:${NC} $OUT_DIR/$TOP_NAME.svg"
fi

if [[ -f "$OUT_DIR/${TOP_NAME}_gates.svg" ]]; then
    add_white_bg "$OUT_DIR/${TOP_NAME}_gates.svg"
    echo -e "${GREEN}✓ Gate-level schematic:${NC}   $OUT_DIR/${TOP_NAME}_gates.svg"
    open "$OUT_DIR/${TOP_NAME}_gates.svg" 2>/dev/null || true
else
    # Fall back to opening the hierarchical view if netlistsvg failed
    open "$OUT_DIR/$TOP_NAME.svg" 2>/dev/null || true
fi

echo -e "\n${GREEN}✓ Done${NC}"
