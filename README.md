# AgentBench

Benchmark your Claude Code agent's general capabilities. Not a coding benchmark — tests real-world tasks like file creation, research, data analysis, multi-step workflows, memory, error handling, and tool efficiency. 62 tasks spanning medium to expert difficulty, with real-mode tasks that create realistic git repo workspaces. **All scoring is rule-based** — no LLM judges, no subjective grading.

## Install

```
/plugin marketplace add agentbench/agentbench
/plugin install agentbench
```

## Quick Start

```
/benchmark                              # Run all 62 tasks (full profile)
/benchmark --fast                       # Run 8 medium tasks (fast profile)
/benchmark --suite research             # Run one domain
/benchmark --suite research --fast      # Run medium tasks in one domain
/benchmark --task research-summarize-doc # Run one task
/benchmark --mode real                  # Test your real environment
/benchmark --strict                     # Tag results with deterministic scoring method
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
| File Creation | 11 | 4M, 7H | Spreadsheets, project scaffolding, config migration, skill graphs, strict format compliance, regex extraction |
| Research | 7 | 1M, 6H | Summarize, compare, multi-source synthesis, git archaeology, noise filtering, code review |
| Data Analysis | 7 | 1M, 3H, 3X | Anomalies, SQL queries, data pipelines, multi-format reconciliation, log pattern detection, hidden patterns |
| Multi-Step | 10 | 4H, 6X | Data pipelines, log analysis, repo refactoring, release preparation, dependency chains, ambiguous requirements, git workflow, API integration, refactoring |
| Memory | 14 | 2M, 7H, 5X | Recall, constraints, context switching, progressive accumulation, long-context recall, factual QA, cross-session handoff, temporal ordering, contradicting updates, selective recall, incremental context, noise filtering, numerical precision |
| Error Handling | 8 | 7H, 1X | Corrupted input, cascading failures, misleading errors, partial recovery, adversarial instructions, graceful degradation, code debugging |
| Tool Efficiency | 5 | 5H | Codebase navigation, targeted fixes, environment awareness, minimal context, code generation |

*E=Easy, M=Medium, H=Hard, X=Expert*

## Scoring

Each task is scored 0-100 across 3 layers:

- **Layer 0 (40%)** — Automated structural checks: files exist, format valid, content matches, command-output validators
- **Layer 1 (40%)** — Metrics: tool call count, planning time, errors
- **Layer 2 (20%)** — Behavioral analysis: tool appropriateness, read-before-write patterns, efficiency, error recovery (rule-based from JSONL event log)

**All rule-based** — no LLM judges. Scores may vary ±3-5 points between runs due to non-deterministic agent execution; we recommend averaging 3 runs.

## Not SWE-bench

AgentBench is a different kind of benchmark. Here's how it compares:

| | SWE-bench | AgentBench |
|---|---|---|
| **Tests** | Code bug fixes | General agent ability (files, research, data, workflows) |
| **Measures** | The model | Your setup + config + prompts |
| **Tasks** | Pull request patches | Real-world work across 7 domains |
| **Scoring** | Pass/fail | 3-layer 0-100 (rule-based, no LLM judges) |
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

- **Full** (default) — All 62 tasks across all difficulty levels
- **Fast** (`--fast`) — 8 medium tasks for quick feedback, covers 4 of 7 domains

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
