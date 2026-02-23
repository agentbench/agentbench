#!/usr/bin/env bash
# AgentBench metrics collector hook
# Receives hook event JSON on stdin from Claude Code.
# Appends normalized events to a JSONL log.
# On Stop events, also computes the aggregate summary.

set -euo pipefail

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
# Determine metrics directory
# Use CLAUDE_PROJECT_DIR (set by Claude Code) to write metrics alongside the project.
# Fall back to cwd from the hook input, then actual cwd.
# ---------------------------------------------------------------------------
project_dir="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$project_dir" ]]; then
  project_dir="$(echo "$input" | jq -r '.cwd // empty')"
fi
if [[ -z "$project_dir" ]]; then
  project_dir="$(pwd)"
fi

METRICS_DIR="${project_dir}/.agentbench-tmp/metrics"
mkdir -p "$METRICS_DIR"

# ---------------------------------------------------------------------------
# Extract common fields from Claude Code hook input
# ---------------------------------------------------------------------------
event_name="$(echo "$input" | jq -r '.hook_event_name // empty')"

# If the event name is empty / unsupported, exit silently
if [[ -z "$event_name" ]]; then
  exit 0
fi

# Timestamp in milliseconds
timestamp_ms="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null)" || timestamp_ms=""
if [[ -z "$timestamp_ms" || ! "$timestamp_ms" =~ ^[0-9]+$ ]]; then
  timestamp_ms="$(date +%s)000"
fi

# ---------------------------------------------------------------------------
# Build a normalized event JSON based on the hook event type
# ---------------------------------------------------------------------------
event_json=""

case "$event_name" in
  UserPromptSubmit)
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      '{event: $event, ts: $ts}')
    ;;

  PreToolUse)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
    tool_input="$(echo "$input" | jq -c '.tool_input // {}' | head -c 500)"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg tool "$tool_name" \
      --arg input "$tool_input" \
      '{event: $event, ts: $ts, tool: $tool, tool_input: $input}')
    ;;

  PostToolUse)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
    tool_input="$(echo "$input" | jq -c '.tool_input // {}' | head -c 500)"
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      --arg tool "$tool_name" \
      --arg input "$tool_input" \
      '{event: $event, ts: $ts, tool: $tool, tool_input: $input}')
    ;;

  PostToolUseFailure)
    tool_name="$(echo "$input" | jq -r '.tool_name // "unknown"')"
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
    echo "$event_json" >> "${METRICS_DIR}/events.jsonl"

    # Compute summary inline (don't source metrics.sh — use direct jq)
    if [[ -f "${METRICS_DIR}/events.jsonl" ]] && [[ -s "${METRICS_DIR}/events.jsonl" ]]; then
      jq -s '
        (map(select(.event == "UserPromptSubmit")) | first // null) as $start |
        (map(select(.event == "Stop"))             | last  // null) as $stop  |
        (map(select(.event == "PreToolUse"))       | first // null) as $first_tool |
        (if $start and $stop then (($stop.ts // 0) - ($start.ts // 0)) else null end) as $total_ms |
        (if $start and $first_tool then (($first_tool.ts // 0) - ($start.ts // 0)) else null end) as $planning_ms |
        (if $planning_ms and $total_ms and $total_ms > 0 then (($planning_ms / $total_ms) * 1000 | round / 1000) else null end) as $planning_ratio |
        [.[] | select(.event == "PostToolUse")] as $tool_calls |
        ($tool_calls | length) as $tool_count |
        ($tool_calls | group_by(.tool) | map({(.[0].tool // "unknown"): length}) | add // {}) as $by_type |
        ([.[] | select(.event == "PostToolUseFailure")] | length) as $errors |
        ([.[] | select(.event == "SubagentStart")] | length) as $subagents |
        {
          total_time_ms: $total_ms,
          planning_time_ms: $planning_ms,
          planning_ratio: $planning_ratio,
          tool_calls_total: $tool_count,
          tool_calls_by_type: $by_type,
          errors: $errors,
          subagents_spawned: $subagents
        }
      ' "${METRICS_DIR}/events.jsonl" > "${METRICS_DIR}/summary.json" 2>/dev/null || true
    fi
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
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      '{event: $event, ts: $ts}')
    ;;

  *)
    event_json=$(jq -nc \
      --arg event "$event_name" \
      --argjson ts "$timestamp_ms" \
      '{event: $event, ts: $ts}')
    ;;
esac

# Append the normalized event to the JSONL log
echo "$event_json" >> "${METRICS_DIR}/events.jsonl"
