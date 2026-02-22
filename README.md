# AgentBench

Benchmark your Claude Code agent's general capabilities. Not a coding benchmark — tests real-world tasks like file creation, research, data analysis, multi-step workflows, memory, error handling, and tool efficiency. 37 tasks spanning easy to expert difficulty, with real-mode tasks that create realistic git repo workspaces.

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

| Domain | Tasks | Difficulty | What It Tests |
|--------|-------|------------|---------------|
| File Creation | 6 | 2E, 2M, 2H | Documents, spreadsheets, project scaffolding, config migration |
| Research | 5 | 3M, 2H | Summarize, compare, multi-source synthesis, git archaeology |
| Data Analysis | 5 | 1E, 1M, 1H, 1X | Anomalies, statistics, multi-format reconciliation, log pattern detection |
| Multi-Step | 5 | 1M, 2H, 2X | Data pipelines, log analysis, repo refactoring, release preparation |
| Memory | 5 | 2M, 1H, 1X | Recall, constraints, context switching, progressive accumulation |
| Error Handling | 6 | 1E, 2M, 3H | Corrupted input, cascading failures, misleading errors, partial recovery |
| Tool Efficiency | 5 | 3E, 2H | Minimal reads, right tool choice, codebase navigation, targeted fixes |

*E=Easy, M=Medium, H=Hard, X=Expert*

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
├── setup.sh           # Optional: creates workspace (git repo, files, scenarios)
├── teardown.sh        # Optional: custom cleanup
└── inputs/
    └── {input-files}
```

Real-mode tasks use `setup.sh` to create realistic git repo workspaces with commit history, code, and embedded bugs or scenarios. See existing tasks for examples.

## License

MIT
