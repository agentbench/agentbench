#!/usr/bin/env bash
# Compute metrics summary from JSONL events log
# Usage: compute-summary.sh [metrics-dir]
# If no dir given, uses .agentbench-tmp/metrics/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

metrics_dir="${1:-.agentbench-tmp/metrics}"
export AGENTBENCH_METRICS_DIR="$metrics_dir"

source "${SCRIPT_DIR}/metrics.sh"

if [[ ! -f "$(agentbench_metrics_file)" ]]; then
  echo "No events.jsonl in $metrics_dir" >&2
  exit 1
fi

compute_summary
echo "Summary written to $(agentbench_summary_file)"
