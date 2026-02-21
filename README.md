# AgentBench

Benchmark your Claude Code agent's general capabilities. Not a coding benchmark — tests real-world tasks like file creation, research, data analysis, multi-step workflows, memory, error handling, and tool efficiency.

## Install

```
/plugin marketplace add agentbench/agentbench
/plugin install agentbench
```

## Quick Start

```
/benchmark                              # Run all tasks
/benchmark --suite research             # Run one domain
/benchmark --task research-summarize-doc # Run one task
/benchmark --mode real                  # Test your real environment
```

## Commands

| Command | Description |
|---------|-------------|
| `/benchmark` | Run benchmark tasks and produce a scored report |
| `/benchmark-list` | List all available tasks grouped by domain |
| `/benchmark-results` | View results from previous runs |
| `/benchmark-compare` | Compare two runs or skill vaults side-by-side |
| `/benchmark-create-task` | Interactive wizard to create a new task |

## Domains

| Domain | Tasks | What It Tests |
|--------|-------|---------------|
| File Creation | 4 | Produce well-structured documents, spreadsheets, forms |
| Research | 3 | Summarize, compare, extract structured data from text |
| Data Analysis | 3 | Find anomalies, compute statistics, cross-reference datasets |
| Multi-Step | 3 | Chain actions: parse logs, extract tasks, clean data pipelines |
| Memory | 3 | Recall facts, retain constraints, persist preferences |
| Error Handling | 3 | Corrupted input, impossible requests, missing files |
| Tool Efficiency | 3 | Minimal tool calls, right tool choice, no unnecessary edits |

## Scoring

Each task is scored 0-100 across 4 layers:

- **Layer 0 (15%)** — Automated checks: files exist, format valid, content matches
- **Layer 1 (25%)** — Metrics: tool call count, planning time, errors
- **Layer 2 (25%)** — Behavioral: instruction adherence, tool choice, approach quality
- **Layer 3 (35%)** — Output quality: completeness, accuracy, formatting, polish

## Key Metrics

Captured via hooks (objective, not self-reported):

- Wall-clock time (total, planning, execution)
- Planning-to-execution ratio
- Tool call count and breakdown by type
- Error count
- Subagent spawns
- Context compactions
- Token estimate

## Output

Each run produces three files in `agentbench-results/{run-id}/`:

- **report.html** — Interactive dashboard (auto-opens in browser)
- **report.md** — Markdown for terminal/GitHub
- **results.json** — Machine-readable scores and metrics

## Modes

- **Sandboxed** (default) — Tasks run in temp directories, no side effects
- **Real** — Tasks run in your actual project, tests your real setup

## Creating Tasks

```
/benchmark-create-task
```

Or manually create:

```
tasks/{suite}/{task-name}/
├── task.yaml
└── inputs/
    └── {input-files}
```

See existing tasks for examples.

## License

MIT
