#!/usr/bin/env bash
# Compute metrics summary from the most recent JSONL events log
# Finds the latest /tmp/agentbench-*/ directory and runs compute_summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/metrics.sh"

# Find the most recent metrics directory
metrics_dir="$(ls -td /tmp/agentbench-*/ 2>/dev/null | head -1)"

if [[ -z "$metrics_dir" ]]; then
  echo "No metrics directory found" >&2
  exit 1
fi

# Set AGENTBENCH_RUN_ID from the directory name
export AGENTBENCH_RUN_ID="$(basename "$metrics_dir" | sed 's/^agentbench-//')"

if [[ ! -f "$(agentbench_metrics_file)" ]]; then
  echo "No events.jsonl in $metrics_dir" >&2
  exit 1
fi

compute_summary
echo "Summary written to $(agentbench_summary_file)"
