#!/usr/bin/env bash
# ============================================================================
# run.sh — compile + elaborate + run the ch10 OO testbench via xsim in Docker.
#
# Captures all output to sim.log in this folder (kept on disk, not deleted).
# The xsim native log (xsim.log) is also kept for inspection.
# ============================================================================
set -euo pipefail

CH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$CH_DIR/sim.log"

# Run docker, tee everything to sim.log
/usr/local/bin/docker run --rm --platform linux/amd64 \
  -v /Users/yuval/Documents/Vivado_new/vivado-on-silicon-mac-main:/home/user \
  -v "$CH_DIR:/work" \
  x64-linux \
  bash -c "
    source /home/user/Xilinx/Vivado/2024.1/settings64.sh 2>/dev/null && cd /work && \
    xvlog --sv -i tb_classes \
      tinyalu_dut/single_cycle_add_and_xor.sv \
      tinyalu_dut/three_cycle_mult.sv \
      tinyalu_dut/tinyalu.sv \
      tinyalu_pkg.sv \
      tinyalu_bfm.sv \
      top.sv && \
    xelab top -s sim --debug off && \
    xsim sim --runall ; \
    EXIT=\$? ; \
    rm -rf /work/xsim.dir /work/*.pb /work/*.jou /work/.Xil 2>/dev/null ; \
    exit \$EXIT
  " 2>&1 | tee "$LOG"

EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "Output saved to: $LOG"
echo "xsim native log: $CH_DIR/xsim.log"
exit $EXIT_CODE
