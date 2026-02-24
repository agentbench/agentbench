# AgentBench

Benchmark your AI agent setup — not the model. 40 real-world tasks across 7 domains, scored with pure rule-based checks. No LLM judges.

## Install

```
/plugin marketplace add agentbench/agentbench
/plugin install agentbench
```

## Quick Start

```
/benchmark                              # Run all 40 tasks
/benchmark --suite memory               # Run one domain
/benchmark --task memory-factual-qa     # Run one task
/benchmark --mode real                  # Test your real environment
/benchmark --custom "Build a REST API"  # Benchmark a custom prompt
/benchmark --strict                     # Tag as deterministic scoring
```

## Commands

| Command | Description |
|---------|-------------|
| `/benchmark` | Run benchmark tasks and produce a scored report |
| `/benchmark --custom "<prompt>"` | Benchmark your setup on any custom prompt |
| `/benchmark-list` | List all available tasks grouped by domain |
| `/benchmark-results` | View results from previous runs |
| `/benchmark-compare` | Compare two runs side-by-side |
| `/benchmark-create-task` | Interactive wizard to create a new task |

## Domains (40 tasks)

| Domain | Tasks | Difficulty | What It Tests |
|--------|-------|------------|---------------|
| Memory | 10 | 5H, 5X | Factual QA recall, cross-session handoff, temporal ordering, contradicting updates, selective recall, incremental context, noise vs signal, numerical precision |
| Multi-Step | 9 | 4H, 5X | Data pipelines, log analysis, repo refactoring, release preparation, dependency chains, ambiguous requirements, git workflow, API integration |
| Data Analysis | 6 | 3H, 3X | SQL queries, cross-referencing, multi-format reconciliation, data pipelines, log pattern detection, hidden patterns |
| Error Handling | 4 | 3H, 1X | Corrupted input, adversarial instructions, graceful degradation, code debugging |
| File Creation | 4 | 4H | Config migration, migration scripts, skill graph refactoring, regex extraction |
| Research | 4 | 4H | Multi-source synthesis, git archaeology, structured data extraction, code review |
| Tool Efficiency | 3 | 3H | Codebase navigation, targeted fixes, code generation |

*H=Hard, X=Expert. Only hard and expert tasks — no easy wins.*

## Scoring

Each task is scored 0-100 across 3 layers:

- **Layer 0 (40%)** — Structural checks: files exist, content matches, command-output validators, format compliance
- **Layer 1 (40%)** — Metrics: tool call count vs expected range, error rate, planning ratio
- **Layer 2 (20%)** — Behavioral: tool appropriateness, read-before-write, efficiency, error recovery

**100% rule-based** — no LLM judges, no subjective grading. Scores may vary ±3-5 points between runs; average 3 runs for official results.

## Per-Tool-Call Tracing

Every tool call is logged with millisecond precision:

```jsonl
{"seq":1,"ts":1708900000123,"tool":"Read","target":"inputs/data.csv","status":"ok","detail":"Read input data"}
{"seq":2,"ts":1708900001456,"tool":"Bash","target":"wc -l data.csv","status":"ok","detail":"Counted 847 lines"}
{"seq":3,"ts":1708900002789,"tool":"Write","target":"analysis.md","status":"ok","detail":"Wrote report"}
{"seq":4,"ts":1708900003100,"tool":"Bash","target":"python3 validate.py","status":"error","detail":"ModuleNotFoundError"}
{"seq":5,"ts":1708900004500,"tool":"Bash","target":"pip install pandas && python3 validate.py","status":"ok","detail":"Retry succeeded"}
```

Trace every call, measure every millisecond. Full transparency — you can audit exactly how your agent solved each task.

## Custom Benchmarks

Test your setup on any prompt:

```
/benchmark --custom "Build a REST API with auth and rate limiting"
```

Uses full benchmark infrastructure but with your prompt. Scores L1 (metrics) + L2 (behavioral) — measures *how* your agent works, not *what* it produces.

## Not SWE-bench

| | SWE-bench | AgentBench |
|---|---|---|
| **Tests** | Code bug fixes | General agent ability across 7 domains |
| **Measures** | The model | Your setup + config + prompts |
| **Scoring** | Pass/fail | 3-layer 0-100 (rule-based) |
| **Key insight** | "Which model is smartest?" | "How good is your agent configuration?" |

Two people using the same model can score 30 points apart based on their agent config alone.

## Output

Each run produces:

- **report.html** — Interactive dashboard
- **report.md** — Markdown summary
- **results.json** — Machine-readable scores, metrics, and trace data
- **trace.jsonl** — Per-task tool call traces

## Modes

- **Sandboxed** (default) — Tasks run in temp directories, no side effects
- **Real** — Tasks run in your actual project, tests your real setup

## License

MIT
