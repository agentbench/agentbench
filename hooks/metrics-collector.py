#!/usr/bin/env python3
"""AgentBench metrics collector hook.

Receives hook event JSON on stdin from Claude Code.
Appends normalized events to a JSONL log.
On Stop events, also computes the aggregate summary.
"""

import json
import os
import sys
import time
from collections import Counter

def main():
    # Read JSON input from stdin
    raw = sys.stdin.read().strip()
    if not raw:
        return

    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return

    # Determine metrics directory
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not project_dir:
        project_dir = data.get("cwd", "")
    if not project_dir:
        project_dir = os.getcwd()

    metrics_dir = os.path.join(project_dir, ".agentbench-tmp", "metrics")
    os.makedirs(metrics_dir, exist_ok=True)

    # Extract event name
    event_name = data.get("hook_event_name", "")
    if not event_name:
        return

    # Timestamp in milliseconds
    timestamp_ms = int(time.time() * 1000)

    # Build normalized event
    event = {"event": event_name, "ts": timestamp_ms}

    if event_name in ("PreToolUse", "PostToolUse"):
        event["tool"] = data.get("tool_name", "unknown")
        tool_input = json.dumps(data.get("tool_input", {}))
        event["tool_input"] = tool_input[:500]

    elif event_name == "PostToolUseFailure":
        event["tool"] = data.get("tool_name", "unknown")
        event["error"] = str(data.get("error", ""))[:200]

    elif event_name == "SubagentStart":
        event["agent_type"] = data.get("agent_type", "unknown")

    # event_name in (UserPromptSubmit, Stop, PreCompact, *) — just event+ts

    events_path = os.path.join(metrics_dir, "events.jsonl")

    if event_name == "Stop":
        # Append Stop event, then compute summary
        with open(events_path, "a") as f:
            f.write(json.dumps(event) + "\n")
        compute_summary(events_path, os.path.join(metrics_dir, "summary.json"))
        return

    # Append normalized event
    with open(events_path, "a") as f:
        f.write(json.dumps(event) + "\n")


def compute_summary(events_path, summary_path):
    """Compute aggregate summary from events.jsonl and write summary.json."""
    if not os.path.isfile(events_path) or os.path.getsize(events_path) == 0:
        with open(summary_path, "w") as f:
            json.dump({"error": "no events"}, f)
        return

    events = []
    with open(events_path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    events.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

    if not events:
        with open(summary_path, "w") as f:
            json.dump({"error": "no valid events"}, f)
        return

    # Key events
    starts = [e for e in events if e.get("event") == "UserPromptSubmit"]
    stops = [e for e in events if e.get("event") == "Stop"]
    pre_tools = [e for e in events if e.get("event") == "PreToolUse"]
    post_tools = [e for e in events if e.get("event") == "PostToolUse"]
    failures = [e for e in events if e.get("event") == "PostToolUseFailure"]
    subagents = [e for e in events if e.get("event") == "SubagentStart"]
    compactions = [e for e in events if e.get("event") == "PreCompact"]

    start = starts[0] if starts else None
    stop = stops[-1] if stops else None
    first_tool = pre_tools[0] if pre_tools else None

    # Timing
    total_ms = None
    planning_ms = None
    execution_ms = None
    planning_ratio = None

    if start and stop:
        total_ms = stop.get("ts", 0) - start.get("ts", 0)
    if start and first_tool:
        planning_ms = first_tool.get("ts", 0) - start.get("ts", 0)
    if first_tool and stop:
        execution_ms = stop.get("ts", 0) - first_tool.get("ts", 0)
    if planning_ms is not None and total_ms and total_ms > 0:
        planning_ratio = round(planning_ms / total_ms, 3)

    # Tool call counts
    tool_counter = Counter(e.get("tool", "unknown") for e in post_tools)

    summary = {
        "total_time_ms": total_ms,
        "planning_time_ms": planning_ms,
        "execution_time_ms": execution_ms,
        "planning_ratio": planning_ratio,
        "tool_calls_total": len(post_tools),
        "tool_calls_by_type": dict(tool_counter),
        "errors": len(failures),
        "subagents_spawned": len(subagents),
        "compactions": len(compactions),
    }

    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # hooks must never break the session
