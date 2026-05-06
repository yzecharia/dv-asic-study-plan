#!/usr/bin/env bash
# ============================================================================
# run_xsim_uvm_compile.sh - Compile UVM testbench once; keep snapshot for reuse
# ============================================================================
# Usage:
#   ./run_xsim_uvm_compile.sh <file1.sv> [file2.sv ...]
#   ./run_xsim_uvm_compile.sh -top <module> <files...>
#
# Produces a Vivado xsim snapshot at <project>/xsim.dir/sim/ that can be
# rerun with different +UVM_TESTNAME values via run_xsim_uvm_test.sh, with
# no recompile cost between runs.
#
# Examples:
#   ./run_xsim_uvm_compile.sh top.sv
#   ./run_xsim_uvm_compile.sh -top top top.sv my_pkg.sv
#
# Environment:
#   VIVADO_PATH  - path to Vivado installation parent dir
#                  (default: /Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main)
#   DOCKER_IMAGE - Docker image name (default: x64-linux)
# ============================================================================

set -euo pipefail

# -- Configuration ----------------------------------------------------------
VIVADO_PATH="${VIVADO_PATH:-/Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main}"
DOCKER_IMAGE="${DOCKER_IMAGE:-x64-linux}"
DOCKER_BIN="/usr/local/bin/docker"
VIVADO_SETTINGS="/home/user/Xilinx/Vivado/2024.1/settings64.sh"

# -- Colors -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# -- Parse args -------------------------------------------------------------
TOP_MODULE=""
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -top|--top)
            TOP_MODULE="$2"
            shift 2
            ;;
        -h|--help)
            head -25 "$0" | grep '^#' | sed 's/^# \?//'
            exit 0
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No input files specified${NC}"
    echo "Usage: $0 [-top <module>] <file1.sv> [file2.sv ...]"
    exit 1
fi

# -- Resolve absolute paths and project root --------------------------------
ABS_FILES=()
for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo -e "${RED}Error: File not found: $f${NC}"
        exit 1
    fi
    ABS_FILES+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
done

PROJECT_DIR="$(dirname "${ABS_FILES[0]}")"

REL_FILES=()
for f in "${ABS_FILES[@]}"; do
    REL_FILES+=("${f#$PROJECT_DIR/}")
done

# -- Auto-detect top from last file -----------------------------------------
if [[ -z "$TOP_MODULE" ]]; then
    LAST_FILE="${ABS_FILES[${#ABS_FILES[@]}-1]}"
    TOP_MODULE=$(grep -m1 -E '^[[:space:]]*(module|program)[[:space:]]' "$LAST_FILE" \
        | sed -E 's/^[[:space:]]*(module|program)[[:space:]]+(automatic[[:space:]]+|static[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\3/')
    if [[ -z "$TOP_MODULE" ]]; then
        TOP_MODULE=$(basename "${LAST_FILE}" .sv)
    fi
fi

# -- Build xvlog + xelab command (NO xsim, NO cleanup) ----------------------
XVLOG_CMDS=""
for f in "${REL_FILES[@]}"; do
    XVLOG_CMDS+="xvlog --sv -L uvm /work/$f && "
done

COMPILE_CMD="${XVLOG_CMDS}xelab -L uvm ${TOP_MODULE} -s sim --debug off"

# -- Print info -------------------------------------------------------------
echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}|  ${YELLOW}Vivado xsim UVM compile (snapshot kept for reuse)${CYAN}     |${NC}"
echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}  Project:${NC}  $PROJECT_DIR"
echo -e "${CYAN}  Files:${NC}    ${REL_FILES[*]}"
echo -e "${CYAN}  Top:${NC}      $TOP_MODULE"
echo -e "${CYAN}  Snapshot:${NC} $PROJECT_DIR/xsim.dir/sim/"
echo ""

# -- Ensure Docker is up ----------------------------------------------------
if ! "$DOCKER_BIN" info &>/dev/null; then
    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
    open -a Docker
    for i in $(seq 1 30); do
        if "$DOCKER_BIN" info &>/dev/null 2>&1; then break; fi
        sleep 1
    done
    if ! "$DOCKER_BIN" info &>/dev/null; then
        echo -e "${RED}Error: Docker failed to start within 30 seconds${NC}"
        exit 1
    fi
fi

# -- Run compile inside Docker ----------------------------------------------
"$DOCKER_BIN" run --rm --platform linux/amd64 \
    -v "$VIVADO_PATH:/home/user" \
    -v "$PROJECT_DIR:/work" \
    "$DOCKER_IMAGE" \
    bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && $COMPILE_CMD"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}/ Compile successful. Snapshot at $PROJECT_DIR/xsim.dir/sim/${NC}"
    echo -e "${CYAN}  Run a test with:${NC} ./run_xsim_uvm_test.sh <test_name> $PROJECT_DIR"
else
    echo -e "\n${RED}X Compile failed (exit code $EXIT_CODE)${NC}"
fi

exit $EXIT_CODE
