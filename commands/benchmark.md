---
description: Run benchmark tasks to measure your agent's general capabilities
---

# Benchmark Command

You are running the AgentBench benchmarking suite. Your job is to orchestrate benchmark tasks and produce scored results.

## Arguments

Parse from $ARGUMENTS:
- `--suite <name>`: Run only a specific suite (file-creation, research, data-analysis, multi-step, memory, error-handling, tool-efficiency)
- `--task <id>`: Run a single specific task by ID
- `--mode <sandboxed|real>`: Override execution mode (default: per-task setting, fallback: sandboxed)
- `--verbose`: Show detailed output for each task
- `--keep-workspace`: Don't clean up temp directories after run
- `--fast`: Run only easy and medium difficulty tasks. Default is full (all tasks). Combinable with --suite. Ignored when --task is specified.
- `--strict`: Mark results as "deterministic" in the output JSON. The `results.json` output will include `"scoring_method": "deterministic"` — all scoring is fully automated with zero LLM judgment.
- `--custom "<prompt>"`: Run a single custom prompt instead of predefined tasks. Uses the full benchmark infrastructure (workspace, task-runner, metrics collection) but with your own prompt. Scoring uses L1 (metrics) and L2 (behavioral) only — L0 is skipped since there are no predefined validators. Useful for testing how your setup handles specific workloads.

## Workflow

### Step 0a: Preflight Check

Verify `python3` is available by running `python3 --version`. Python is needed for some task validators (command-output-contains). If unavailable, warn but continue — most scoring still works.

**Metrics collection:** L1/L2 metrics are collected via task-runner self-report (metrics.json) and optionally via hooks (events.jsonl). Self-report works on all platforms without hooks. Hooks provide richer data when available.

### Step 0a.5: Custom Prompt Mode

If `--custom` is specified, skip the normal task discovery and run in custom mode:

1. Create workspace: `mkdir -p .agentbench-tmp/custom-task && cd .agentbench-tmp/custom-task && pwd` to get absolute path
2. Spawn task-runner subagent with the custom prompt as `user_message`, the workspace path, and mode (sandboxed by default)
3. After task-runner completes, collect metrics from `{workspace}/metrics.json`
4. **Score L1 only** (from metrics.json):
   - Tool calls: report count (no expected range to compare against, so just report)
   - Errors: 0 errors = 100, 1-2 = 70, 3+ = 40
   - Planning: planning_steps > 0 = 100, 0 = 70
   - L1 score = weighted average of error score (50%) and planning score (50%)
5. **Score L2** (from metrics.json):
   - Start at 100, apply standard penalties:
   - `read_before_write` false when files_read should be non-empty: -25
   - `errors` > 0: -7 per error (max -28)
   - `planning_steps` == 0: -10
   - Floor at 0
6. **Composite**: score = (L1 * 0.60) + (L2 * 0.40) — no L0 since no validators
7. Output results:
   ```
   Custom Benchmark Result
   ═══════════════════════
   Prompt: "{first 100 chars of prompt}..."
   Score: {composite}/100 (L1:{l1} L2:{l2})
   Tool calls: {n} ({breakdown by type})
   Errors: {n}
   Planning steps: {n}
   Files created: {list}
   ```
8. Save to `agentbench-results/custom-{timestamp}/results.json` with `"mode": "custom"`
9. Clean up workspace (unless `--keep-workspace`)
10. **Stop** — do not continue to normal benchmark flow.

### Step 0b: Choose Execution Mode

If the user did NOT specify `--mode` in arguments, ask them to choose:

"How would you like to run the benchmark?

**🔒 Sandboxed** (recommended) — Tasks run in isolated temp directories. Safe, no side effects.
**🌐 Real** — Tasks run with full tool access. Tests your actual workflow but may modify files.

Choose: sandboxed / real"

Wait for the user's response before proceeding. If they specified `--mode sandboxed` or `--mode real` in arguments, skip this prompt.

### Step 1: Discover Tasks

The plugin root is available as `${CLAUDE_PLUGIN_ROOT}`. All file paths below are relative to this root. Use `${CLAUDE_PLUGIN_ROOT}/tasks/` to find task files — do NOT search the filesystem.

Read task.yaml files from:
```
${CLAUDE_PLUGIN_ROOT}/tasks/{suite-name}/{task-name}/task.yaml
```

Each task.yaml contains: name, id, suite, difficulty, mode, user_message, input_files, expected_outputs, expected_metrics, scoring weights.

Filter by --suite or --task if specified. If --fast is specified and --task is not, filter to only tasks where difficulty is "easy" or "medium". Determine the profile: "fast" if --fast was specified, otherwise "full". List discovered tasks to the user with count and suites.

### Step 2: Set Up Run Directory

Generate a run ID from the current timestamp: `YYYYMMDD-HHmmss`

Read `suite_version` from `${CLAUDE_PLUGIN_ROOT}/suite-version.json`.

Create the results directory:
```
agentbench-results/{run-id}/
```

Record the benchmark start time: `date -u +%Y-%m-%dT%H:%M:%SZ` and also `date +%s` (epoch seconds for duration calculation).

Detect the model being used. Run: `echo $ANTHROPIC_MODEL` or check the Claude Code session info. If unavailable, note as "unknown".

Announce: `Starting AgentBench run {run-id} | Profile: {profile} | Suite version: {suite_version} | Tasks: {count} | Model: {model}`

### Step 3: Execute Each Task

**Context management**: Running 60 tasks generates a lot of context. To avoid hitting context limits:
- After each task completes and its score is saved to disk, do NOT keep the task's full output/trace in conversation — just the score summary line.
- After every 10 tasks, run `/compact` to free context space. The results are safely on disk in `agentbench-results/{run-id}/`.
- If you receive a "context limit reached" warning, immediately `/compact` and resume from where you left off by reading `agentbench-results/{run-id}/` to see which tasks are already scored.

For each task:

1. **Set up workspace**:
   - Create workspace in the current working directory (where the benchmark was started): `.agentbench-tmp/{task-id}/` as workspace
   - Copy input files from `${CLAUDE_PLUGIN_ROOT}/tasks/{suite}/{task}/inputs/` to the workspace (if inputs/ exists)
   - If the task directory contains a `setup.sh`: run `bash ${CLAUDE_PLUGIN_ROOT}/tasks/{suite}/{task}/setup.sh {workspace-path}` to scaffold the workspace. The setup script receives the workspace path as $1 and creates files, git repos, etc. inside it.
   - For validators that use `file-unchanged`: compute checksums of specified files now (after setup, before task-runner runs) and store them for comparison after scoring.
   - Clear any previous task's metrics: run `rm -rf .agentbench-tmp/metrics/ 2>/dev/null && mkdir -p .agentbench-tmp/metrics/` to ensure fresh metrics for this task
   - Set environment variable `AGENTBENCH_RUN_ID` to `{run-id}-{task-id}`

2. **Announce**: Tell the user which task is running:
   `Running: {task.name} [{task.suite}] (difficulty: {task.difficulty})`

3. **Spawn task-runner subagent** with:
   - The task's `user_message`
   - The **absolute path** to the workspace directory (resolve it first with `cd .agentbench-tmp/{task-id} && pwd`)
   - The list of input files available in the workspace
   - The mode (sandboxed/real)
   - Do NOT pass expected_outputs, validators, or scoring info to the task-runner
   - **CRITICAL**: Tell the task-runner the exact absolute workspace path. ALL files must be created inside that path. Example: "Your workspace is /Users/tarek/myproject/.agentbench-tmp/summarize-doc — create all files there."

3b. **Collect metrics** after task-runner completes:
   - Check workspace for `metrics.json` (written by task-runner self-report)
   - Also check `.agentbench-tmp/metrics/summary.json` (from hooks, if they fired)
   - **Priority**: Use hooks summary.json if available (more accurate). Fall back to task-runner's metrics.json.
   - If NEITHER exists: note metrics as unavailable (weights will redistribute to L0).

4. **Layer 0 — Automated Structural Checks** (you compute this directly):
   After the task-runner completes, check the workspace:
   - For each entry in `expected_outputs`:
     - `file-exists`: Check if a file matching the pattern exists in workspace. Award 30 points if found, 0 if not.
     - `content-contains`: Read the file, check if each required section keyword appears (case-insensitive search). Award points proportionally (e.g., 4 of 5 sections found = 80% of 40 points = 32 points). Total pool: 40 points.
     - `word-count-range`: Count words in the file. In range = 30 points. Within 2x range = 15 points. Outside = 0 points.
     - `git-log-contains`: Run `git -C {workspace} log --oneline` and check if expected strings appear in commit messages. If `min_commits` is specified, also verify at least that many commits exist. Award 30 points if all expected strings found and commit count met, proportional points otherwise.
     - `directory-structure`: Check that all paths listed in `paths` exist in the workspace (files and directories). Award 30 points if all present, proportional points for partial matches.
     - `command-output-contains`: Run the command specified in `command` inside the workspace directory and check if stdout/stderr contains all strings listed in `contains`. Award 30 points if all found and command exits 0, 0 points if command fails.
     - `file-unchanged`: Compare checksum of specified file against the pre-task-runner checksum recorded during workspace setup. Award 30 points if file unchanged, 0 if modified or deleted.
     - `link-consistency`: Scan all files matching `files` glob pattern. Detect link syntax used in each file: wikilinks (`[[...]]`), markdown links (`[...](...)`) , or plain references. Award 30 points if all files use the same link syntax consistently, 15 points if mixed but one dominant style (>70%), 0 points if no clear pattern. Any valid syntax is accepted — this checks consistency, not which syntax was chosen.
   - Normalize the total to 0-100 scale.

5. **Layer 1 — Metrics Analysis** (you compute this directly):
   - Read metrics from hooks `summary.json` OR task-runner's `metrics.json` (whichever is available, hooks preferred)
   - Map task-runner metrics: `tool_calls` → total tool calls, `errors` → error count, `planning_steps` → derive planning ratio (planning_steps / tool_calls)
   - If metrics are available and task has expected_metrics:
     - Tool calls within expected range: 40 points
     - Tool calls within 2x expected range: 20 points
     - Tool calls outside 2x range: 0 points
     - Planning ratio within expected range: 30 points
     - Planning ratio outside range but within 2x: 15 points
     - Planning ratio way off: 0 points
     - Zero errors: 30 points
     - 1-2 errors: 15 points
     - 3+ errors: 0 points
   - Normalize to 0-100 scale
   - If no metrics available (hooks didn't fire): redistribute L1 weight to L0. Set L1 score to null (excluded from composite). Recalculate composite as: `score = (L0 * 0.65) + (L2 * 0.35)` when L1 is unavailable, or `score = L0 * 1.0` when both L1 and L2 are unavailable. Log a note: "Metrics unavailable — weights redistributed to L0."

6. **Layer 2 — Behavioral Analysis** (you compute this from metrics.json, events.jsonl, or execution-trace.md):
   
   **Data sources (in priority order):**
   1. Hooks JSONL (`events.jsonl`) — most detailed, if available
   2. Task-runner self-report (`metrics.json`) — reliable fallback
   3. Execution trace (`execution-trace.md`) — last resort, parse for patterns
   
   Start at 100 points, apply penalties:
   
   **Using hooks JSONL (if available):**
   - Bash misuse (cat/head/tail for reading, echo > for writing): -5 per instance (max -25)
   - No read-before-write: -25
   - Duplicate file reads: -5 each (max -20)
   - Tool errors: -7 each (max -28)
   - Excessive tool calls (>2x expected): -15
   - No planning (first tool <500ms after start): -10
   - Error recovery: +3 per recovered error
   
   **Using task-runner metrics.json (if no JSONL):**
   - `read_before_write` is false AND task had input files: -25
   - `errors` > 0: -7 per error (max -28)
   - `tool_calls` > 2x expected_metrics upper bound: -15
   - `planning_steps` == 0: -10
   - Check `tool_calls_by_type`: if Bash count > Read+Write count AND task is a file task: -10 (bash misuse proxy)
   - Check `files_read`: if input files not in list but should have been: -10
   
   **Using execution-trace.md only (last resort):**
   - Check if trace mentions reading input files: if not, -25
   - Check if trace mentions planning/approach: if not, -10
   - Check if trace mentions errors/retries: -7 per mentioned error
   - Score is approximate — note "L2 from trace analysis" in results
   
   Floor at 0, cap at 100.
   
   If NO data source available at all: redistribute L2 weight to L0. Set L2 score to null (excluded from composite). See weight redistribution rules in L1 above.

7. **Compute composite score**:
   ```
   # Normal (all layers available):
   score = (L0 * 0.40) + (L1 * 0.40) + (L2 * 0.20)
   
   # If L1 unavailable (no metrics):
   score = (L0 * 0.65) + (L2 * 0.35)
   
   # If L2 unavailable (no events):
   score = (L0 * 0.55) + (L1 * 0.45)
   
   # If both L1 and L2 unavailable:
   score = L0
   ```
   Use weights from task.yaml scoring section, or defaults: L0=0.40, L1=0.40, L2=0.20

8. **Save task result immediately** to `agentbench-results/{run-id}/{task-id}/`:
   - `scores.json`: All layer scores, composite score, breakdown
   - `metrics.json`: Copy of the hooks metrics summary (if available)
   - Copy any output files the task-runner created
   - Also append a line to `agentbench-results/{run-id}/progress.jsonl`: `{"task_id":"{task-id}","suite":"{suite}","score":{composite},"l0":{l0},"l1":{l1},"l2":{l2}}`
   - This progress file allows resuming after compaction — just read it to see what's done.

9. **Display task result** to user (one line only — keep context small):
   ```
   ✓ {task.name}: {composite}/100 (L0:{l0} L1:{l1} L2:{l2})
   ```
   Do NOT print full task details, output contents, or validator results to the conversation.

### Step 4: Generate Report

After all tasks complete:

1. Collect all task scores and metrics from agentbench-results/{run-id}/
2. Compute domain averages (group tasks by suite, average composite scores)
3. Compute overall score (average of domain scores — equal domain weighting)
4. Compute aggregate metrics (total tool calls, total errors, avg planning ratio, total time)
5. Calculate total runtime: `current epoch - start epoch` → format as Xm Xs
6. Spawn the report-generator subagent with:
   - run_id
   - mode
   - profile ("fast" or "full")
   - suite_version
   - model (the model name detected at start)
   - total_runtime (formatted and raw seconds)
   - All task results (scores, metrics)
   - output_dir: agentbench-results/{run-id}/
6. Report generator produces: report.md, report.html, results.json

### Step 5: Present Results

1. Display the overall score prominently
2. Show domain breakdown as a simple table
3. Open report.html in the user's browser:
   - Windows: `start agentbench-results/{run-id}/report.html`
   - macOS: `open agentbench-results/{run-id}/report.html`
   - Linux: `xdg-open agentbench-results/{run-id}/report.html`
4. Tell the user where full results are saved

### Step 6: Clean Up

If the task directory contains a `teardown.sh`: run `bash ${CLAUDE_PLUGIN_ROOT}/tasks/{suite}/{task}/teardown.sh {workspace-path}` for any custom cleanup.
If --keep-workspace was NOT specified, remove the entire `.agentbench-tmp/` directory: `rm -rf .agentbench-tmp/`
Always keep the agentbench-results/ directory.

## Error Handling

- If a task-runner subagent fails or returns no output, score that task as 0 across all layers with a note explaining the failure
- Always continue to the next task even if one fails
- Display progress as you go so the user knows what's happening
- If no tasks match the --suite or --task filters, list available suites and tasks
- If the agentbench-results directory can't be created, warn the user and continue with console output only
