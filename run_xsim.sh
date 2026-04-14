#!/usr/bin/env bash
# ============================================================================
# run_xsim.sh — Run SystemVerilog files through Vivado xsim via Docker
# ============================================================================
# Usage:
#   ./run_xsim.sh <file.sv>                    # single TB file
#   ./run_xsim.sh <file1.sv> <file2.sv> ...    # multiple files (RTL + TB)
#   ./run_xsim.sh -top <module> <files...>      # specify top module
#
# Examples:
#   ./run_xsim.sh tb/ch2_ex7_tb.sv
#   ./run_xsim.sh rtl/counter.sv tb/counter_tb.sv
#   ./run_xsim.sh -top counter_tb rtl/*.sv tb/counter_tb.sv
#
# Environment:
#   VIVADO_PATH  — path to Vivado installation parent dir
#                  (default: /Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main)
#   DOCKER_IMAGE — Docker image name (default: x64-linux)
# ============================================================================

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
VIVADO_PATH="${VIVADO_PATH:-/Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main}"
DOCKER_IMAGE="${DOCKER_IMAGE:-x64-linux}"
DOCKER_BIN="/usr/local/bin/docker"
VIVADO_SETTINGS="/home/user/Xilinx/Vivado/2024.1/settings64.sh"

# ── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Parse arguments ────────────────────────────────────────────────────────
TOP_MODULE=""
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -top|--top)
            TOP_MODULE="$2"
            shift 2
            ;;
        -h|--help)
            head -20 "$0" | grep '^#' | sed 's/^# \?//'
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

# ── Resolve absolute paths and determine project root ──────────────────────
ABS_FILES=()
for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo -e "${RED}Error: File not found: $f${NC}"
        exit 1
    fi
    ABS_FILES+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
done

# Use the directory of the first file's parent as the project root
PROJECT_DIR="$(dirname "${ABS_FILES[0]}")"
# Walk up to find the week folder (contains tb/ or is the project root)
if [[ "$(basename "$PROJECT_DIR")" == "tb" || "$(basename "$PROJECT_DIR")" == "rtl" ]]; then
    PROJECT_DIR="$(dirname "$PROJECT_DIR")"
fi

# Convert absolute paths to paths relative to PROJECT_DIR
REL_FILES=()
for f in "${ABS_FILES[@]}"; do
    REL_FILES+=("${f#$PROJECT_DIR/}")
done

# ── Auto-detect top module/program from last file ─────────────────────────
if [[ -z "$TOP_MODULE" ]]; then
    LAST_FILE="${ABS_FILES[${#ABS_FILES[@]}-1]}"
    # Extract first 'module' or 'program' name from file
    TOP_MODULE=$(grep -m1 -E '^[[:space:]]*(module|program)[[:space:]]' "$LAST_FILE" \
        | sed -E 's/^[[:space:]]*(module|program)[[:space:]]+(automatic[[:space:]]+|static[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\3/')
    if [[ -z "$TOP_MODULE" ]]; then
        TOP_MODULE=$(basename "${LAST_FILE}" .sv)
    fi
fi

# ── Build xvlog + xelab + xsim command ────────────────────────────────────
XVLOG_CMDS=""
for f in "${REL_FILES[@]}"; do
    XVLOG_CMDS+="xvlog --sv /work/$f && "
done

SEED_FLAG=""
if [[ -n "${SV_SEED:-}" ]]; then
    SEED_FLAG=" -sv_seed ${SV_SEED}"
fi

SIM_CMD="${XVLOG_CMDS}xelab ${TOP_MODULE} -s sim --debug off && xsim sim --runall${SEED_FLAG}; EXIT=\$?; rm -rf /work/xsim.dir /work/xvlog.pb /work/xvlog.log /work/xelab.pb /work/xelab.log /work/xsim.log /work/xsim.jou /work/.Xil 2>/dev/null; exit \$EXIT"

# ── Print info ─────────────────────────────────────────────────────────────
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${YELLOW}Vivado xsim via Docker${CYAN}                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}  Project:${NC}  $PROJECT_DIR"
echo -e "${CYAN}  Files:${NC}    ${REL_FILES[*]}"
echo -e "${CYAN}  Top:${NC}      $TOP_MODULE"
echo ""

# ── Ensure Docker is running ──────────────────────────────────────────────
if ! "$DOCKER_BIN" info &>/dev/null; then
    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
    open -a Docker
    # Wait up to 30 seconds for Docker to start
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

# ── Run simulation ────────────────────────────────────────────────────────
"$DOCKER_BIN" run --rm --platform linux/amd64 \
    -v "$VIVADO_PATH:/home/user" \
    -v "$PROJECT_DIR:/work" \
    "$DOCKER_IMAGE" \
    bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && $SIM_CMD"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}✓ Simulation completed successfully${NC}"
else
    echo -e "\n${RED}✗ Simulation failed (exit code $EXIT_CODE)${NC}"
fi

exit $EXIT_CODE
