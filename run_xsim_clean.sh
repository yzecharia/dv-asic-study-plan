#!/usr/bin/env bash
# ============================================================================
# run_xsim_clean.sh - Remove xsim/xelab/xvlog build artifacts from a folder.
#
# Usage:
#     ./run_xsim_clean.sh <folder>
#     ./run_xsim_clean.sh <file_in_folder.sv>
#
# Useful after an xsim crash poisons the cache: xsim 2024.1 SIGSEGVs at
# 'Compiling module ...' often go away after a clean rebuild. Removes:
#   - xsim.dir/         (xelab snapshot directory)
#   - xelab.log/.pb     (elaborator output)
#   - xvlog.log/.pb     (parser output)
#   - webtalk*          (Xilinx telemetry)
#   - .Xil/             (Vivado work directory, may or may not exist)
#
# Leaves source files untouched. Safe to run between compile attempts.
# ============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <folder|file_in_folder>"
    exit 1
fi

TARGET="$1"
if [[ -d "$TARGET" ]]; then
    DIR="$(cd "$TARGET" && pwd)"
elif [[ -f "$TARGET" ]]; then
    DIR="$(cd "$(dirname "$TARGET")" && pwd)"
else
    echo "Error: not found: $TARGET"
    exit 1
fi

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}|  ${YELLOW}xsim build artifact clean${CYAN}                             |${NC}"
echo -e "${CYAN}+======================================================+${NC}"
echo -e "${CYAN}  Folder:${NC} $DIR"
echo ""

REMOVED=()
for entry in xsim.dir xelab.log xelab.pb xvlog.log xvlog.pb .Xil; do
    if [[ -e "$DIR/$entry" ]]; then
        rm -rf "$DIR/$entry"
        REMOVED+=("$entry")
    fi
done

shopt -s nullglob
for f in "$DIR"/webtalk*; do
    rm -rf "$f"
    REMOVED+=("$(basename "$f")")
done
shopt -u nullglob

if [[ ${#REMOVED[@]} -eq 0 ]]; then
    echo -e "${GREEN}/ Nothing to clean.${NC}"
else
    echo -e "${GREEN}/ Removed:${NC} ${REMOVED[*]}"
fi
