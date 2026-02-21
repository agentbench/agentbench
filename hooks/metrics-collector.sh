#!/usr/bin/env bash
# AgentBench metrics collector hook
# Receives hook event JSON on stdin, normalizes it, and appends to JSONL log.
# On Stop events, also computes the aggregate summary.

set -euo pipefail

# Resolve script directory so we can source the shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/metrics.sh"

# ---------------------------------------------------------------------------
# Read JSON input from stdin
# ---------------------------------------------------------------------------
input="$(cat)"

# Guard: if jq is not available we cannot parse events at all
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Guard: empty or missing input
if [[ -z "$input" ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract common fields
# ---------------------------------------------------------------------------
event_name="$(echo "$input" | jq -r '.hook_event_name // empty')"
session_id="$(echo "$input" | jq -r '.session_id // empty')"

# If the event name is empty / unsupported, exit silently
if [[ -z "$event_name" ]]; then
  exit 0
fi

# Timestamp in milliseconds — date +%s%3N works on GNU/BusyBox/Git-Bash;
# fall back to Python if that produces a literal "%3N" (macOS stock date).
timestamp_ms="$(date +%s%3N 2>/dev/null)" || timestamp_ms=""
if [[ -z "$timestamp_ms" || "$timestamp_ms" == *"%3N"* ]]; then
  timestamp_ms="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || echo "0")"
fi

# Fall back run-id: prefer env var, then session_id, then "unknown"
export AGENTBENCH_RUN_ID="${AGENTBENCH_RUN_ID:-${session_id:-unknown}}"

# ---------------------------------------------------------------------------
# Build a normalized event JSON based on the hook event type
# ---------------------------------------------------------------------------
event_json=""

case "$event_name" in
  UserPromptSubmit)
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg session "$session_id" \
      '{event: $event, ts: $ts, session_id: $session}')
    ;;

  PreToolUse)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
    tool_use_id="$(echo "$input" | jq -r '.tool_use_id // ""')"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg tool "$tool_name" \
      --arg tool_use_id "$tool_use_id" \
      '{event: $event, ts: $ts, tool: $tool, tool_use_id: $tool_use_id}')
    ;;

  PostToolUse)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
    tool_use_id="$(echo "$input" | jq -r '.tool_use_id // ""')"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg tool "$tool_name" \
      --arg tool_use_id "$tool_use_id" \
      '{event: $event, ts: $ts, tool: $tool, tool_use_id: $tool_use_id}')
    ;;

  PostToolUseFailure)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
    # Truncate error message to 200 characters to keep log compact
    error_msg="$(echo "$input" | jq -r '.error // ""' | head -c 200)"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg tool "$tool_name" \
      --arg error "$error_msg" \
      '{event: $event, ts: $ts, tool: $tool, error: $error}')
    ;;

  Stop)
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      '{event: $event, ts: $ts}')

    # Append the Stop event first, then compute the summary
    append_event "$event_json"
    compute_summary
    exit 0
    ;;

  SubagentStart)
    agent_type="$(echo "$input" | jq -r '.agent_type // "unknown"')"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg agent_type "$agent_type" \
      '{event: $event, ts: $ts, agent_type: $agent_type}')
    ;;

  PreCompact)
    trigger="$(echo "$input" | jq -r '.trigger // "unknown"')"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg trigger "$trigger" \
      '{event: $event, ts: $ts, trigger: $trigger}')
    ;;

  *)
    # Unknown event — log it with minimal fields so nothing is lost
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      '{event: $event, ts: $ts}')
    ;;
esac

# Append the normalized event to the JSONL log
append_event "$event_json"
