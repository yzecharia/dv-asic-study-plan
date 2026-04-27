#!/usr/bin/env bash
# ============================================================================
# run.sh — compile + elaborate + run the ch11 UVM testbench via xsim in Docker.
#
# Usage:
#   ./run.sh                       # defaults to random_test
#   ./run.sh random_test           # explicit
#   ./run.sh add_test              # the directed add-only test
#
# Equivalent of Mentor's:  vsim +UVM_TESTNAME=<test> top
# xsim uses:               xsim sim --runall -testplusarg UVM_TESTNAME=<test>
#
# All output is captured to sim.log in this folder.
# ============================================================================
set -euo pipefail

CH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_NAME="${1:-random_test}"
LOG="$CH_DIR/sim_${TEST_NAME}.log"

echo "=== Running test: $TEST_NAME ==="
echo "=== Log:          $LOG ==="
echo ""

/usr/local/bin/docker run --rm --platform linux/amd64 \
  -v /Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main:/home/user \
  -v "$CH_DIR:/work" \
  x64-linux \
  bash -c "
    source /home/user/Xilinx/Vivado/2024.1/settings64.sh 2>/dev/null && cd /work && \
    xvlog --sv -L uvm -i tb_classes \
      tinyalu_dut/single_cycle_add_and_xor.sv \
      tinyalu_dut/three_cycle_mult.sv \
      tinyalu_dut/tinyalu.sv \
      tinyalu_pkg.sv \
      tinyalu_bfm.sv \
      top.sv && \
    xelab -L uvm top -s sim --debug off && \
    xsim sim --runall -testplusarg UVM_TESTNAME=${TEST_NAME} ; \
    EXIT=\$? ; \
    rm -rf /work/xsim.dir /work/*.pb /work/*.jou /work/.Xil 2>/dev/null ; \
    exit \$EXIT
  " 2>&1 | tee "$LOG"

EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "Output saved to: $LOG"
exit $EXIT_CODE
