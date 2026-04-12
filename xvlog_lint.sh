#!/usr/bin/env bash
# ============================================================================
# xvlog_lint.sh — Wrapper to run Vivado xvlog (SV parser) via Docker
# Used as VS Code linter backend instead of iverilog
# ============================================================================
VIVADO_PATH="${VIVADO_PATH:-/Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main}"
DOCKER_BIN="/usr/local/bin/docker"
DOCKER_IMAGE="${DOCKER_IMAGE:-x64-linux}"
VIVADO_SETTINGS="/home/user/Xilinx/Vivado/2024.1/settings64.sh"

# Get the file to lint (passed as argument by VS Code)
FILE="$1"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    exit 0
fi

# Check if Docker is running — if not, silently exit (don't block the editor)
if ! "$DOCKER_BIN" info &>/dev/null 2>&1; then
    exit 0
fi

FILE_DIR="$(cd "$(dirname "$FILE")" && pwd)"
FILE_NAME="$(basename "$FILE")"

"$DOCKER_BIN" run --rm --platform linux/amd64 \
    -v "$VIVADO_PATH:/home/user" \
    -v "$FILE_DIR:/work" \
    "$DOCKER_IMAGE" \
    bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && xvlog --sv $FILE_NAME 2>&1; rm -rf /work/xvlog.pb /work/xvlog.log /work/xsim.dir 2>/dev/null"
