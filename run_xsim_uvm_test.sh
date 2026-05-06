#!/usr/bin/env bash
# ============================================================================
# run_xsim_uvm_test.sh - Run a UVM test against an already-compiled snapshot
# ============================================================================
# Usage:
#   ./run_xsim_uvm_test.sh <test_name>                  # use snapshot in CWD
#   ./run_xsim_uvm_test.sh <test_name> <project_dir>    # explicit project dir
#
# Requires that run_xsim_uvm_compile.sh has already been run in <project_dir>
# (or CWD), which leaves an xsim.dir/sim/ snapshot for reuse.
#
# Examples:
#   cd week_04_uvm_architecture/homework/verif/per_chapter/hw_ch11_uvm_tests
#   ../../../../../run_xsim_uvm_compile.sh top.sv
#   ../../../../../run_xsim_uvm_test.sh hello_uvm_test
#   ../../../../../run_xsim_uvm_test.sh add_test           # different test, no recompile
#
# Environment (optional):
#   UVM_VERBOSITY - one of UVM_LOW UVM_MEDIUM UVM_HIGH UVM_FULL UVM_DEBUG
#   SV_SEED       - seed for $random / class randomize()
#   VIVADO_PATH, DOCKER_IMAGE - same as run_xsim_uvm_compile.sh
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
if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo -e "${RED}Error: expected 1 or 2 args${NC}"
    echo "Usage: $0 <test_name> [project_dir]"
    exit 1
fi

TEST_NAME="$1"
PROJECT_DIR="${2:-$(pwd)}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}Error: project_dir not found: $PROJECT_DIR${NC}"
    exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ ! -d "$PROJECT_DIR/xsim.dir/sim" ]]; then
    echo -e "${RED}Error: no compiled snapshot at $PROJECT_DIR/xsim.dir/sim/${NC}"
    echo "Run run_xsim_uvm_compile.sh in this directory first."
    exit 1
fi

# -- Build optional flags ---------------------------------------------------
EXTRA_FLAGS=""
if [[ -n "${UVM_VERBOSITY:-}" ]]; then
    EXTRA_FLAGS+=" -testplusarg UVM_VERBOSITY=${UVM_VERBOSITY}"
fi
if [[ -n "${SV_SEED:-}" ]]; then
    EXTRA_FLAGS+=" -sv_seed ${SV_SEED}"
fi

XSIM_CMD="xsim sim --runall -testplusarg UVM_TESTNAME=${TEST_NAME}${EXTRA_FLAGS}"

# -- Print info -------------------------------------------------------------
echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}|  ${YELLOW}Vivado xsim UVM run (reusing existing snapshot)${CYAN}       |${NC}"
echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}  Project:${NC}  $PROJECT_DIR"
echo -e "${CYAN}  Test:${NC}     $TEST_NAME"
[[ -n "${UVM_VERBOSITY:-}" ]] && echo -e "${CYAN}  Verbosity:${NC} $UVM_VERBOSITY"
[[ -n "${SV_SEED:-}" ]]       && echo -e "${CYAN}  Seed:${NC}     $SV_SEED"
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

# -- Run inside Docker ------------------------------------------------------
"$DOCKER_BIN" run --rm --platform linux/amd64 \
    -v "$VIVADO_PATH:/home/user" \
    -v "$PROJECT_DIR:/work" \
    "$DOCKER_IMAGE" \
    bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && $XSIM_CMD"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "\n${GREEN}/ Test '$TEST_NAME' completed${NC}"
else
    echo -e "\n${RED}X Test '$TEST_NAME' failed (exit code $EXIT_CODE)${NC}"
fi

exit $EXIT_CODE
