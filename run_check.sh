#!/usr/bin/env bash
# Thin compatibility wrapper — forwards to `xflow.sh check`. Kept so the many
# existing docs/homework references to `run_check.sh` keep working unchanged.
# All logic lives in xflow.sh. To make changes, edit that file instead.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/xflow.sh" check "$@"
