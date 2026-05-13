#!/usr/bin/env bash
# ============================================================================
# xflow.sh — Unified Vivado xsim flow driver (one script, five modes).
#
# Single source of truth for: folder scanning, top-module detection, Docker
# orchestration, and Vivado xvlog/xelab/xsim invocation. The five xsim-based
# flows differ only in WHICH steps they run and WHETHER they clean up after.
#
# Usage:
#     ./xflow.sh lint    <file.sv|.svh>        # xvlog only — syntax, NO elaboration
#     ./xflow.sh check   <file.sv|.svh>        # syntax + elaboration, NO sim, full clean
#     ./xflow.sh sim     <file.sv|.svh>        # compile + elaborate + simulate + clean
#     ./xflow.sh compile <file.sv|.svh>        # compile + elaborate, KEEP snapshot
#     ./xflow.sh run     <test_name> [target]  # xsim against existing snapshot
#                                              #   target can be a dir or any file in it
#                                              #   defaults to CWD
#
# When to use lint vs check:
#   - lint  — fast syntax verification when the design isn't elaboratable yet
#             (e.g. RTL module with interface ports but no top wrapper).
#   - check — full pre-sim sanity: syntax + cross-module linking (interface
#             modport binding, port widths, missing modules).
#
# Folder-scan rules (applied to check/sim/compile):
#   1. Files containing 'package <name>;' compile first (regardless of
#      .sv vs .svh extension or alphabetic filename order).
#   2. Other *.svh files next.
#   3. Other *.sv files next.
#   4. The target file last — its top module is the elaboration root.
#
# Top-module detection (applied to check/sim/compile):
#   1. $TOP_MODULE env var override
#   2. First *_tb_top.sv / *_top.sv sibling's module name
#   3. First `module <name>` in the target file
#   4. Fallback: target file's basename
#
# Optional env vars (forwarded to xsim where applicable):
#   UVM_TESTNAME   sim/run: +UVM_TESTNAME plusarg
#   UVM_VERBOSITY  sim/run: +UVM_VERBOSITY plusarg (UVM_LOW..UVM_DEBUG)
#   SV_SEED        sim/run: -sv_seed <N>
#   TOP_MODULE     check/sim/compile: override elaboration root
#   VIVADO_PATH    Vivado installation parent dir
#   DOCKER_IMAGE   Docker image (default: x64-linux)
#
# Examples:
#     ./xflow.sh check tb/counter_tb.sv
#     ./xflow.sh sim   tb/counter_tb.sv
#     UVM_TESTNAME=random_test ./xflow.sh sim tb/alu_tb_top.sv
#     ./xflow.sh compile tb/alu_tb_top.sv
#     ./xflow.sh run random_test tb/
#     UVM_VERBOSITY=UVM_HIGH ./xflow.sh run directed_test tb/alu_tb_top.sv
# ============================================================================
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
VIVADO_PATH="${VIVADO_PATH:-/Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main}"
DOCKER_IMAGE="${DOCKER_IMAGE:-x64-linux}"
DOCKER_BIN="/usr/local/bin/docker"
VIVADO_SETTINGS="/home/user/Xilinx/Vivado/2024.1/settings64.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    head -50 "$0" | grep -E '^#( |$)' | sed -E 's/^# ?//' >&2
    exit 1
}

# ── Mode dispatch ──────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    usage
fi

MODE="$1"
shift

# ── Shared helpers ─────────────────────────────────────────────────────────

# Print a header box with mode-specific title.
print_banner() {
    local title="$1"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${YELLOW}${title}${CYAN}$(printf '%*s' $((54 - ${#title})) '')║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}

# Ensure Docker is up; start Docker Desktop if not.
ensure_docker() {
    if "$DOCKER_BIN" info &>/dev/null; then
        return 0
    fi
    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
    open -a Docker
    for i in $(seq 1 30); do
        if "$DOCKER_BIN" info &>/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}Error: Docker failed to start within 30 seconds${NC}" >&2
    exit 1
}

# Extract the first `module` or `program` identifier from a file. Tolerant of
# missing files and files without a module decl.
extract_top_from_file() {
    { grep -m1 -E '^[[:space:]]*(module|program)[[:space:]]' "$1" 2>/dev/null \
        | sed -E 's/^[[:space:]]*(module|program)[[:space:]]+(automatic[[:space:]]+|static[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\3/'; } || true
}

# Scan a folder and populate REL_FILES with the right compile order:
#   packages → other .svh → other .sv → target last.
# Globals set: REL_FILES (array, basenames).
scan_folder() {
    local target_abs="$1"
    local project_dir="$2"

    local target_is_pkg=0
    if grep -qE '^[[:space:]]*package[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*;' "$target_abs"; then
        target_is_pkg=1
    fi

    local pkg_files=() svh_files=() sv_siblings=()
    shopt -s nullglob
    for f in "$project_dir"/*.svh "$project_dir"/*.sv; do
        [[ "$f" == "$target_abs" ]] && continue
        if grep -qE '^[[:space:]]*package[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*;' "$f"; then
            pkg_files+=("$(basename "$f")")
        elif [[ "$f" == *.svh ]]; then
            svh_files+=("$(basename "$f")")
        else
            sv_siblings+=("$(basename "$f")")
        fi
    done
    shopt -u nullglob

    REL_FILES=()
    [[ $target_is_pkg -eq 1 ]] && REL_FILES+=("$(basename "$target_abs")")
    [[ ${#pkg_files[@]}    -gt 0 ]] && REL_FILES+=("${pkg_files[@]}")
    [[ ${#svh_files[@]}    -gt 0 ]] && REL_FILES+=("${svh_files[@]}")
    [[ ${#sv_siblings[@]}  -gt 0 ]] && REL_FILES+=("${sv_siblings[@]}")
    [[ $target_is_pkg -eq 0 ]] && REL_FILES+=("$(basename "$target_abs")")
    return 0
}

# Choose the elaboration top. Precedence:
#   1. $TOP_MODULE env var
#   2. First *_tb_top.sv / *_top.sv sibling in the folder
#   3. First `module`/`program` in the target file
#   4. Target basename (with .sv/.svh stripped)
# Sets global TOP_MODULE.
detect_top_module() {
    local target_abs="$1"
    local project_dir="$2"

    if [[ -n "${TOP_MODULE:-}" ]]; then
        return 0  # caller-specified, keep
    fi

    TOP_MODULE=""
    shopt -s nullglob
    for f in "$project_dir"/*_tb_top.sv "$project_dir"/*_top.sv; do
        TOP_MODULE="$(extract_top_from_file "$f")"
        [[ -n "$TOP_MODULE" ]] && break
    done
    shopt -u nullglob

    if [[ -z "$TOP_MODULE" ]]; then
        TOP_MODULE="$(extract_top_from_file "$target_abs")"
    fi
    if [[ -z "$TOP_MODULE" ]]; then
        TOP_MODULE="$(basename "$target_abs" .sv)"
        TOP_MODULE="${TOP_MODULE%.svh}"
    fi
}

# Build the xvlog command string from REL_FILES. -L uvm is always passed so
# files that `import uvm_pkg::*` compile; it's harmless for non-UVM TBs.
build_xvlog_cmds() {
    XVLOG_CMDS=""
    for f in "${REL_FILES[@]}"; do
        XVLOG_CMDS+="xvlog --sv -L uvm /work/$f && "
    done
}

# Build optional xsim flags from env vars. Sets XSIM_FLAGS.
# `return 0` at the end is required: under `set -e`, a function's exit code is
# its last command's, and a `[[ -n "" ]] && ...` short-circuit returns false
# when the env var is empty — which would silently abort the caller.
build_xsim_flags() {
    XSIM_FLAGS=""
    [[ -n "${SV_SEED:-}" ]]       && XSIM_FLAGS+=" -sv_seed ${SV_SEED}"
    [[ -n "${UVM_TESTNAME:-}" ]]  && XSIM_FLAGS+=" -testplusarg UVM_TESTNAME=${UVM_TESTNAME}"
    [[ -n "${UVM_VERBOSITY:-}" ]] && XSIM_FLAGS+=" -testplusarg UVM_VERBOSITY=${UVM_VERBOSITY}"
    return 0
}

# Run a docker command in the project dir. Args: $1 = remote bash command.
docker_exec() {
    local cmd="$1"
    ensure_docker
    "$DOCKER_BIN" run --rm --platform linux/amd64 \
        -v "$VIVADO_PATH:/home/user" \
        -v "$PROJECT_DIR:/work" \
        "$DOCKER_IMAGE" \
        bash -c "source $VIVADO_SETTINGS 2>/dev/null && cd /work && $cmd"
}

# Resolve a file arg to absolute path and set PROJECT_DIR + TARGET_ABS.
resolve_target_file() {
    local target_file="$1"
    if [[ ! -f "$target_file" ]]; then
        echo -e "${RED}Error: File not found: $target_file${NC}" >&2
        exit 1
    fi
    TARGET_ABS="$(cd "$(dirname "$target_file")" && pwd)/$(basename "$target_file")"
    PROJECT_DIR="$(dirname "$TARGET_ABS")"
}

# ── Mode: lint ─────────────────────────────────────────────────────────────
# xvlog only — parse-and-analyze, NO elaboration. Use when the target file
# can't elaborate standalone (e.g. RTL module with interface ports, before
# the *_tb_top.sv wrapper exists). Catches: syntax errors, undeclared
# identifiers, type mismatches WITHIN a file. Does NOT catch: cross-module
# port width mismatches, missing modules, modport binding failures — those
# are xelab's job (use `check` mode for that).
mode_lint() {
    [[ $# -lt 1 ]] && { echo "Usage: $0 lint <file.sv|.svh>" >&2; exit 1; }
    resolve_target_file "$1"
    scan_folder "$TARGET_ABS" "$PROJECT_DIR"
    build_xvlog_cmds

    # Strip the trailing " && " from XVLOG_CMDS; tack on cleanup.
    local xvlog_only="${XVLOG_CMDS% && }"
    local cmd="${xvlog_only}; EXIT=\$?; rm -rf /work/xvlog.pb /work/xvlog.log 2>/dev/null; exit \$EXIT"

    print_banner "xvlog syntax check (no elaboration)"
    echo -e "${CYAN}  Folder:${NC}  $PROJECT_DIR"
    echo -e "${CYAN}  Files:${NC}   ${REL_FILES[*]}"
    echo ""

    set +e
    docker_exec "$cmd"
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Syntax clean — all files parse${NC}"
        echo -e "${CYAN}  (lint mode skips elaboration — run 'check' once a top exists)${NC}"
    else
        echo -e "\n${RED}✗ Lint failed (exit code $rc) — fix syntax errors above${NC}"
    fi
    exit $rc
}

# ── Mode: check ────────────────────────────────────────────────────────────
# xvlog + xelab, NO xsim, full clean. Snapshot is named 'check_snap' so it
# doesn't clash with 'sim' snapshots that compile/run modes create.
mode_check() {
    [[ $# -lt 1 ]] && { echo "Usage: $0 check <file.sv|.svh>" >&2; exit 1; }
    resolve_target_file "$1"
    scan_folder "$TARGET_ABS" "$PROJECT_DIR"
    detect_top_module "$TARGET_ABS" "$PROJECT_DIR"
    build_xvlog_cmds

    local cmd="${XVLOG_CMDS}xelab -L uvm ${TOP_MODULE} -s check_snap --debug off; EXIT=\$?; rm -rf /work/xsim.dir /work/xvlog.pb /work/xvlog.log /work/xelab.pb /work/xelab.log /work/.Xil 2>/dev/null; exit \$EXIT"

    print_banner "Syntax + elaboration check (xvlog + xelab)"
    echo -e "${CYAN}  Folder:${NC}  $PROJECT_DIR"
    echo -e "${CYAN}  Files:${NC}   ${REL_FILES[*]}"
    echo -e "${CYAN}  Top:${NC}     $TOP_MODULE"
    echo ""

    set +e
    docker_exec "$cmd"
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Syntax + elaboration clean — design compiles${NC}"
    else
        echo -e "\n${RED}✗ Check failed (exit code $rc) — fix errors above${NC}"
    fi
    exit $rc
}

# ── Mode: sim ──────────────────────────────────────────────────────────────
# xvlog + xelab + xsim --runall, then clean. Snapshot named 'sim' (matches
# what compile would build, but cleaned up after).
mode_sim() {
    [[ $# -lt 1 ]] && { echo "Usage: $0 sim <file.sv|.svh>" >&2; exit 1; }
    resolve_target_file "$1"
    scan_folder "$TARGET_ABS" "$PROJECT_DIR"
    detect_top_module "$TARGET_ABS" "$PROJECT_DIR"
    build_xvlog_cmds
    build_xsim_flags

    local cmd="${XVLOG_CMDS}xelab -L uvm ${TOP_MODULE} -s sim --debug off && xsim sim --runall${XSIM_FLAGS}; EXIT=\$?; rm -rf /work/xsim.dir /work/xvlog.pb /work/xvlog.log /work/xelab.pb /work/xelab.log /work/xsim.log /work/xsim.jou /work/.Xil /work/webtalk* 2>/dev/null; exit \$EXIT"

    print_banner "xsim one-shot simulation"
    echo -e "${CYAN}  Folder:${NC}    $PROJECT_DIR"
    echo -e "${CYAN}  Files:${NC}     ${REL_FILES[*]}"
    echo -e "${CYAN}  Top:${NC}       $TOP_MODULE"
    [[ -n "${UVM_TESTNAME:-}" ]]  && echo -e "${CYAN}  Test:${NC}      $UVM_TESTNAME"
    [[ -n "${UVM_VERBOSITY:-}" ]] && echo -e "${CYAN}  Verbosity:${NC} $UVM_VERBOSITY"
    [[ -n "${SV_SEED:-}" ]]       && echo -e "${CYAN}  Seed:${NC}      $SV_SEED"
    echo ""

    set +e
    docker_exec "$cmd"
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Simulation completed${NC}"
    else
        echo -e "\n${RED}✗ Simulation failed (exit code $rc)${NC}"
    fi
    exit $rc
}

# ── Mode: compile ──────────────────────────────────────────────────────────
# xvlog + xelab only — NO xsim, NO cleanup. Snapshot stays at xsim.dir/sim/.
mode_compile() {
    [[ $# -lt 1 ]] && { echo "Usage: $0 compile <file.sv|.svh>" >&2; exit 1; }
    resolve_target_file "$1"
    scan_folder "$TARGET_ABS" "$PROJECT_DIR"
    detect_top_module "$TARGET_ABS" "$PROJECT_DIR"
    build_xvlog_cmds

    local cmd="${XVLOG_CMDS}xelab -L uvm ${TOP_MODULE} -s sim --debug off"

    print_banner "xsim compile (snapshot kept for reuse)"
    echo -e "${CYAN}  Folder:${NC}   $PROJECT_DIR"
    echo -e "${CYAN}  Files:${NC}    ${REL_FILES[*]}"
    echo -e "${CYAN}  Top:${NC}      $TOP_MODULE"
    echo -e "${CYAN}  Snapshot:${NC} $PROJECT_DIR/xsim.dir/sim/"
    echo ""

    set +e
    docker_exec "$cmd"
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Compile successful. Snapshot at $PROJECT_DIR/xsim.dir/sim/${NC}"
        echo -e "${CYAN}  Run a test with:${NC} $0 run <test_name> $PROJECT_DIR"
    else
        echo -e "\n${RED}✗ Compile failed (exit code $rc)${NC}"
    fi
    exit $rc
}

# ── Mode: run ──────────────────────────────────────────────────────────────
# xsim --runall against existing snapshot. Test name is required; target can
# be a folder OR a file (folder inferred from file's dir). Defaults to CWD.
mode_run() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: $0 run <test_name> [project_dir|file_in_project_dir]" >&2
        exit 1
    fi
    local test_name="$1"
    local target="${2:-$(pwd)}"

    if [[ -d "$target" ]]; then
        PROJECT_DIR="$(cd "$target" && pwd)"
    elif [[ -f "$target" ]]; then
        PROJECT_DIR="$(cd "$(dirname "$target")" && pwd)"
    else
        echo -e "${RED}Error: not found: $target${NC}" >&2
        exit 1
    fi

    if [[ ! -d "$PROJECT_DIR/xsim.dir/sim" ]]; then
        echo -e "${RED}Error: no compiled snapshot at $PROJECT_DIR/xsim.dir/sim/${NC}" >&2
        echo "Run '$0 compile <file>' on a file in that folder first." >&2
        exit 1
    fi

    # Build flags — RUN always sets UVM_TESTNAME from positional arg (override
    # any env-var setting), plus the optional verbosity/seed.
    XSIM_FLAGS=" -testplusarg UVM_TESTNAME=${test_name}"
    [[ -n "${UVM_VERBOSITY:-}" ]] && XSIM_FLAGS+=" -testplusarg UVM_VERBOSITY=${UVM_VERBOSITY}"
    [[ -n "${SV_SEED:-}" ]]       && XSIM_FLAGS+=" -sv_seed ${SV_SEED}"

    local cmd="xsim sim --runall${XSIM_FLAGS}"

    print_banner "xsim run (reusing snapshot)"
    echo -e "${CYAN}  Folder:${NC}    $PROJECT_DIR"
    echo -e "${CYAN}  Test:${NC}      $test_name"
    [[ -n "${UVM_VERBOSITY:-}" ]] && echo -e "${CYAN}  Verbosity:${NC} $UVM_VERBOSITY"
    [[ -n "${SV_SEED:-}" ]]       && echo -e "${CYAN}  Seed:${NC}      $SV_SEED"
    echo ""

    set +e
    docker_exec "$cmd"
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Test '$test_name' completed${NC}"
    else
        echo -e "\n${RED}✗ Test '$test_name' failed (exit code $rc)${NC}"
    fi
    exit $rc
}

# ── Dispatch ───────────────────────────────────────────────────────────────
case "$MODE" in
    lint)     mode_lint    "$@" ;;
    check)    mode_check   "$@" ;;
    sim)      mode_sim     "$@" ;;
    compile)  mode_compile "$@" ;;
    run)      mode_run     "$@" ;;
    -h|--help|help) usage ;;
    *)
        echo -e "${RED}Error: unknown mode '$MODE' (expected lint|check|sim|compile|run)${NC}" >&2
        echo "" >&2
        usage
        ;;
esac
