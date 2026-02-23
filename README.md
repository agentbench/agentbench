# AgentBench

Benchmark your Claude Code agent's general capabilities. Not a coding benchmark — tests real-world tasks like file creation, research, data analysis, multi-step workflows, memory, error handling, and tool efficiency. 50 tasks spanning easy to expert difficulty, with real-mode tasks that create realistic git repo workspaces.

## Install

```
/plugin marketplace add agentbench/agentbench
/plugin install agentbench
```

## Quick Start

```
/benchmark                              # Run all 50 tasks (full profile)
/benchmark --fast                       # Run 19 easy+medium tasks (fast profile)
/benchmark --suite research             # Run one domain
/benchmark --suite research --fast      # Run easy+medium tasks in one domain
/benchmark --task research-summarize-doc # Run one task
/benchmark --mode real                  # Test your real environment
/benchmark --strict                     # Tag results as self-scored in output JSON
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
| File Creation | 10 | 1E, 3M, 5H, 1X | Documents, spreadsheets, project scaffolding, config migration, skill graphs, strict format compliance |
| Research | 6 | 2H, 3M, 1H | Summarize, compare, multi-source synthesis, git archaeology, noise filtering |
| Data Analysis | 6 | 1E, 1M, 2H, 2X | Anomalies, statistics, multi-format reconciliation, log pattern detection, hidden patterns |
| Multi-Step | 7 | 1H, 2H, 2X, 2X | Data pipelines, log analysis, repo refactoring, release preparation, dependency chains, ambiguous requirements |
| Memory | 6 | 2M, 1H, 2X | Recall, constraints, context switching, progressive accumulation, long-context recall |
| Error Handling | 8 | 1E, 2H, 4H, 1X | Corrupted input, cascading failures, misleading errors, partial recovery, adversarial instructions, graceful degradation |
| Tool Efficiency | 7 | 3E, 4H | Minimal reads, right tool choice, codebase navigation, targeted fixes, environment awareness, minimal context |

*E=Easy, M=Medium, H=Hard, X=Expert*

## Scoring

Each task is scored 0-100 across 4 layers:

- **Layer 0 (20%)** — Automated checks: files exist, format valid, content matches
- **Layer 1 (35%)** — Metrics: tool call count, planning time, errors
- **Layer 2 (20%)** — Behavioral: instruction adherence, tool choice, approach quality
- **Layer 3 (25%)** — Output quality: completeness, accuracy, formatting, polish

## Not SWE-bench

AgentBench is a different kind of benchmark. Here's how it compares:

| | SWE-bench | AgentBench |
|---|---|---|
| **Tests** | Code bug fixes | General agent ability (files, research, data, workflows) |
| **Measures** | The model | Your setup + config + prompts |
| **Tasks** | Pull request patches | Real-world work across 7 domains |
| **Scoring** | Pass/fail | 4-layer 0-100 (automated + behavioral + quality) |
| **Who varies** | The model changes, setup is fixed | The setup changes, model can be fixed |
| **Key insight** | "Which model is smartest?" | "How good is your agent configuration?" |

Two people using the same model can score 30 points apart based on their agent config alone.

## Key Metrics

Captured via hooks (objective, not self-reported):

- Wall-clock time (total, planning, execution)
- Planning-to-execution ratio
- Tool call count and breakdown by type
- Error count
- Subagent spawns
- Context compactions
- Token estimate *(reported only, not scored — quality shouldn't be penalized for thoroughness)*

## Output

Each run produces three files in `agentbench-results/{run-id}/`:

- **report.html** — Interactive dashboard (auto-opens in browser)
- **report.md** — Markdown for terminal/GitHub
- **results.json** — Machine-readable scores and metrics

## Profiles

- **Full** (default) — All 50 tasks across all difficulty levels
- **Fast** (`--fast`) — 19 easy+medium tasks for quick feedback, covers all 7 domains (unchanged from v1)

Results track the profile used, and `/benchmark-compare` warns when comparing runs with different profiles.

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
