#!/usr/bin/env bash
# AgentBench metrics library — shared functions for metrics read/write
#
# Provides path helpers, event logging, and summary computation.
# Sourced by the orchestrator command. Summary computation delegates to lib/metrics.py.

# Determine the metrics directory for the current run
# Uses AGENTBENCH_METRICS_DIR env var if set, otherwise falls back to .agentbench-tmp/metrics/ in cwd
agentbench_metrics_dir() {
  echo "${AGENTBENCH_METRICS_DIR:-.agentbench-tmp/metrics}"
}

# Return the path to the JSONL event log
agentbench_metrics_file() {
  echo "$(agentbench_metrics_dir)/events.jsonl"
}

# Return the path to the computed summary JSON
agentbench_summary_file() {
  echo "$(agentbench_metrics_dir)/summary.json"
}

# Append a metrics event (JSON line) to the JSONL log
# Creates the metrics directory if it does not exist.
# Usage: append_event '{"event":"PostToolUse","tool":"Bash","ts":1234567890}'
append_event() {
  local json_line="$1"
  local metrics_file
  metrics_file="$(agentbench_metrics_file)"
  mkdir -p "$(dirname "$metrics_file")"
  echo "$json_line" >> "$metrics_file"
}

# Read all events from the JSONL log (stdout)
# Outputs nothing if the file does not exist.
# Usage: read_events | jq ...
read_events() {
  local metrics_file
  metrics_file="$(agentbench_metrics_file)"
  if [[ -f "$metrics_file" ]]; then
    cat "$metrics_file"
  fi
}

# Compute aggregate summary from the JSONL event log
# Writes summary.json alongside the events file.
# Uses Python3 (no jq dependency).
compute_summary() {
  local metrics_dir
  metrics_dir="$(agentbench_metrics_dir)"

  # Guard: no metrics file
  if [[ ! -f "$(agentbench_metrics_file)" ]]; then
    echo '{"error":"no metrics file found"}' > "$(agentbench_summary_file)"
    return 1
  fi

  # Guard: empty metrics file
  if [[ ! -s "$(agentbench_metrics_file)" ]]; then
    echo '{"error":"metrics file is empty"}' > "$(agentbench_summary_file)"
    return 1
  fi

  python3 "${BASH_SOURCE[0]%/*}/metrics.py" "$metrics_dir"
}
