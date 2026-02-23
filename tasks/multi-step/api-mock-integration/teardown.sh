#!/usr/bin/env bash
set -euo pipefail
WS="$1"
if [ -f "$WS/mock_server.pid" ]; then
    kill "$(cat "$WS/mock_server.pid")" 2>/dev/null || true
    rm -f "$WS/mock_server.pid"
fi
