#!/usr/bin/env python3
"""AgentBench metrics summary computation.

Standalone script: python3 lib/metrics.py [metrics-dir]
Reads events.jsonl, computes summary, writes summary.json.

Keep summary logic in sync with hooks/metrics-collector.py.
"""

import json
import os
import sys
from collections import Counter


def compute_summary(metrics_dir):
    """Compute aggregate summary from events.jsonl and write summary.json."""
    events_path = os.path.join(metrics_dir, "events.jsonl")
    summary_path = os.path.join(metrics_dir, "summary.json")

    if not os.path.isfile(events_path) or os.path.getsize(events_path) == 0:
        with open(summary_path, "w") as f:
            json.dump({"error": "no events"}, f)
        return 1

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
        return 1

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
    return 0


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 lib/metrics.py <metrics-dir>", file=sys.stderr)
        sys.exit(1)
    metrics_dir = sys.argv[1]
    if not os.path.isdir(metrics_dir):
        print(f"Error: {metrics_dir} is not a directory", file=sys.stderr)
        sys.exit(1)
    sys.exit(compute_summary(metrics_dir))


if __name__ == "__main__":
    main()
