#!/usr/bin/env bash
# IMALEagent wrapper - delegates to the real pi binary
set -euo pipefail

PI_REAL_BIN="__PI_REAL_BIN__"

exec "$PI_REAL_BIN" "$@"
