#!/usr/bin/env bash
# ============================================================================
# run_check.sh — Syntax + elaboration check via Vivado xvlog + xelab.
#
# Runs the same compile/link passes as run_xsim.sh but STOPS before xsim,
# so you get all SV syntax errors (xvlog) and cross-module linking errors
# (xelab — port widths, missing modules, top-name mismatches) without
# actually simulating anything.
#
# Usage:
#     ./run_check.sh <file.sv>
#
# Auto-includes every *.svh and *.sv file in the same folder as <file.sv>,
# so designs split across multiple files (DFF + Mux + Arb + top + pkg) all
# elaborate together. Both extensions are optional.
#
# COMPILE ORDER (handles cross-file dependencies — packages first):
#   1. Files containing 'package <name>;' declarations (regardless of
#      .sv vs .svh extension or filename alphabetic order)
#   2. Other *.svh files (typically `define-only headers)
#   3. Other *.sv files (excluding the target)
#   4. The target itself last — its top module is the elaboration root.
#
# This means an interface in alu_if.svh can `import alu_pkg::*` even if
# alu_pkg.svh sorts AFTER it alphabetically. The script detects the
# 'package' keyword and pulls those files to the front.
#
# Top module name is inferred from <file.sv> (first `module` keyword).
#
# Note: if a *.svh file is also `include`d inside a *.sv file, you may get
# "duplicate definition" errors. Either rename it to *.sv and import it as a
# package, or stop `include`ing it. Modern SV prefers import over `include
# for packages.
# ============================================================================
set -euo pipefail

VIVADO_PATH="${VIVADO_PATH:-/Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main}"
DOCKER_IMAGE="${DOCKER_IMAGE:-x64-linux}"
DOCKER_BIN="/usr/local/bin/docker"
VIVADO_SETTINGS="/home/user/Xilinx/Vivado/2024.1/settings64.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <file.sv>"
    exit 1
fi

TARGET_FILE="$1"
if [[ ! -f "$TARGET_FILE" ]]; then
    echo -e "${RED}Error: File not found: $TARGET_FILE${NC}"
    exit 1
fi

TARGET_ABS="$(cd "$(dirname "$TARGET_FILE")" && pwd)/$(basename "$TARGET_FILE")"
PROJECT_DIR="$(dirname "$TARGET_ABS")"

# Compile order (handles cross-file dependencies — packages first):
#   1. Files containing 'package <name>;' declarations (any extension)
#   2. Other *.svh files (typically `define-only headers)
#   3. Other *.sv files (excluding the target)
#   4. The target itself last (its top module is the elaboration root)
#
# Detection: grep each candidate for ^\s*package\s+<id>\s*;
# This makes alphabetical filename ordering irrelevant — e.g. alu_if.svh
# can safely `import alu_pkg::*` even though alu_pkg.* sorts later.
PKG_FILES=()
SVH_FILES=()
SV_SIBLINGS=()
shopt -s nullglob
for f in "$PROJECT_DIR"/*.svh "$PROJECT_DIR"/*.sv; do
    [[ "$f" == "$TARGET_ABS" ]] && continue
    if grep -qE '^[[:space:]]*package[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*;' "$f"; then
        PKG_FILES+=("$(basename "$f")")
    elif [[ "$f" == *.svh ]]; then
        SVH_FILES+=("$(basename "$f")")
    else
        SV_SIBLINGS+=("$(basename "$f")")
    fi
done
shopt -u nullglob

REL_FILES=()
[[ ${#PKG_FILES[@]}    -gt 0 ]] && REL_FILES+=("${PKG_FILES[@]}")
[[ ${#SVH_FILES[@]}    -gt 0 ]] && REL_FILES+=("${SVH_FILES[@]}")
[[ ${#SV_SIBLINGS[@]}  -gt 0 ]] && REL_FILES+=("${SV_SIBLINGS[@]}")
REL_FILES+=("$(basename "$TARGET_ABS")")

# Infer top module: first `module <name>` in the target file. Fallback: filename.
TOP_MODULE=$(grep -m1 -E '^[[:space:]]*module[[:space:]]' "$TARGET_ABS" \
    | sed -E 's/^[[:space:]]*module[[:space:]]+(automatic[[:space:]]+|static[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\2/')
if [[ -z "$TOP_MODULE" ]]; then
    TOP_MODULE=$(basename "$TARGET_ABS" .sv)
fi

# Build the docker command — xvlog every file, then xelab with the inferred top.
XVLOG_CMDS=""
for f in "${REL_FILES[@]}"; do
    XVLOG_CMDS+="xvlog --sv /work/$f && "
done

CHECK_CMD="${XVLOG_CMDS}xelab ${TOP_MODULE} -s check_snap --debug off; EXIT=\$?; rm -rf /work/xsim.dir /work/xvlog.pb /work/xvlog.log /work/xelab.pb /work/xelab.log /work/.Xil 2>/dev/null; exit \$EXIT"

echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${YELLOW}Syntax + elaboration check (xvlog + xelab)${CYAN}          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}  Folder:${NC}  $PROJECT_DIR"
echo -e "${CYAN}  Files:${NC}   ${REL_FILES[*]}"
echo -e "${CYAN}  Top:${NC}     $TOP_MODULE"
echo ""

if ! "$DOCKER_BIN" info &>/dev/null; then
    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
    open -a Docker
    for i in $(seq 1 30); do
        if "$DOCKER_BIN" info &>/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    if ! "$DOCKER_BIN" info &>/dev/null; then
        echo -e "${RED}Error: Docker failed to start within 30 seconds${NC}"
        exit 1
    fi
fi

"$DOCKER_BIN" run --rm --platform linux/amd64 \
    -v "$VIVADO_PATH:/home/user" \
    -v "$PROJECT_DIR:/work" \
    "$DOCKER_IMAGE" \
    bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && $CHECK_CMD"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}✓ Syntax + elaboration clean — design compiles${NC}"
else
    echo -e "\n${RED}✗ Check failed (exit code $EXIT_CODE) — fix errors above before synthesis${NC}"
fi

exit $EXIT_CODE
