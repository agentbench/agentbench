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

**Metrics collection:** All metrics are collected via the task-runner's self-report: `trace.jsonl` (per-tool-call trace with timestamps) and `metrics.json` (computed aggregates). This is platform-independent and works in all environments including sandboxes.

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
7. Output results to console:
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
8. Save `results.json` to `agentbench-results/custom-{timestamp}/` with `"mode": "custom"`
9. **Generate HTML report** — write `report.html` to the same directory. Read `{workspace}/trace.jsonl` for the full trace data. The HTML report must be a single self-contained file (all CSS/JS inline, no external deps). Use the same design system as the full benchmark report (see report-generator agent). The custom report layout:

   **Header** (centered):
   - "AgentBench — Custom Run" in mono, bold, 20px
   - Overall score as large number (48px, mono, bold, score-colored)
   - Below: prompt text (truncated to 200 chars), timestamp, model if known — 10px mono muted

   **Score Breakdown** (2 cards side by side):
   - L1 card: score, error score detail, planning score detail
   - L2 card: score, list of penalties applied (or "No penalties")

   **Metrics Panel** (grid of 4 cards):
   - Total Time (Xm Xs or Xs)
   - Tool Calls (total + breakdown by type as small badges)
   - Errors (count, red if > 0)
   - Planning Steps (count)

   **Tool Call Timeline** (main feature — this is what makes custom reports useful):
   - Section header: "EXECUTION TRACE"
   - Visual timeline showing every tool call from trace.jsonl
   - Each entry is a row with:
     - **Sequence number** (#1, #2, #3...) in a small mono circle
     - **Timestamp** relative to start (e.g., "+0.0s", "+1.2s", "+3.5s") in muted mono
     - **Tool name** as a colored badge: Read=blue, Write=green, Edit=yellow, Bash=purple, Glob=cyan, Grep=teal, WebSearch=orange
     - **Target** (file path or command, truncated to 80 chars) in mono
     - **Status** indicator: ✓ green for ok, ✗ red for error
     - **Detail** text in muted small text
   - Tool calls connected by a thin vertical line (timeline style)
   - Error entries highlighted with a subtle red-tinted background
   - If there are >50 entries, show first 30 + last 10 with a "... N more entries ..." collapse toggle

   **Files Created** (section):
   - Section header: "OUTPUT FILES"
   - List of files_written from metrics.json with file icons

   **Footer**:
   - "Generated by AgentBench | Custom Run" + link to agentbench.app

   **Design details:**
   - Same CSS variables (light/dark mode) as full report
   - Grid background pattern
   - Max-width 800px centered
   - Responsive (single column on mobile)
   - Under 50KB total
   - Tool badge colors (dark mode compatible):
     - Read: #3b82f6 (blue)
     - Write: #22c55e (green)  
     - Edit: #eab308 (yellow)
     - Bash: #a855f7 (purple)
     - Glob: #06b6d4 (cyan)
     - Grep: #14b8a6 (teal)
     - WebSearch: #f97316 (orange)
     - Other: #78716c (muted)

10. Open the HTML report in the user's browser:
    - macOS: `open agentbench-results/custom-{timestamp}/report.html`
    - Linux: `xdg-open agentbench-results/custom-{timestamp}/report.html`
    - Windows: `start agentbench-results/custom-{timestamp}/report.html`
    - Tell the user where the report is saved
11. Clean up workspace (unless `--keep-workspace`)
12. **Stop** — do not continue to normal benchmark flow.

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
   - Metrics are self-contained in each task workspace (trace.jsonl + metrics.json) — no shared metrics directory needed
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
   - Check workspace for `trace.jsonl` (per-tool-call trace with timestamps) and `metrics.json` (aggregate summary)
   - `trace.jsonl` is the source of truth — each line is a tool call with seq number, millisecond timestamp, tool name, target, status, and detail
   - `metrics.json` contains computed aggregates (total_time_ms, tool_calls, errors, etc.)
   - If trace.jsonl exists but metrics.json doesn't, compute metrics yourself from the trace
   - All metrics come from task-runner self-report — no external hooks needed
   - If NEITHER trace.jsonl nor metrics.json exists: note metrics as unavailable (weights will redistribute to L0).

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
   - Read `trace.jsonl` for per-call data and `metrics.json` for aggregates
   - From trace.jsonl: count tool calls, count errors (status="error"), compute total_time_ms (last ts - first ts), compute planning ratio (reads before first write / total calls)
   - From metrics.json: use pre-computed aggregates as cross-check
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
   - If no metrics available (task-runner didn't produce trace.jsonl/metrics.json): redistribute L1 weight to L0. Set L1 score to null (excluded from composite). Recalculate composite as: `score = (L0 * 0.65) + (L2 * 0.35)` when L1 is unavailable, or `score = L0 * 1.0` when both L1 and L2 are unavailable. Log a note: "Metrics unavailable — weights redistributed to L0."

6. **Layer 2 — Behavioral Analysis** (you compute this from trace.jsonl):
   
   Read `{workspace}/trace.jsonl` — each line is a tool call with exact timestamp, tool name, target, and status.
   
   Start at 100 points, apply penalties:
   
   **Tool appropriateness** (scan trace.jsonl entries):
   - Bash tool where target contains "cat ", "head ", "tail ", "less " for file reading: -5 per instance (max -25)
   - Bash tool where target contains "echo " + ">" or "printf " + ">" for file creation: -5 per instance (max -25)
   
   **Read-before-write pattern**:
   - Find the first Write/Edit entry in trace. Check if any Read/Glob/Grep entries exist before it.
   - If task had input files but no read before first write: -25
   
   **Efficiency**:
   - Same file read more than once (duplicate target in Read entries): -5 each (max -20)
   - Entries with status="error": -7 each (max -28)
   
   **Excessive tool calls**:
   - If total trace entries exceed 2x the expected_metrics tool_calls upper bound: -15
   
   **No planning detected**:
   - Check time gap between seq=1 and seq=2. If < 500ms AND first call is a Write: -10
   - Or if no Read/Glob/Grep calls exist before first Write: -10
   
   **Error recovery**:
   - If an error entry is followed within 3 entries by a successful call to the same tool/target: +3 per recovery
   
   **Timing analysis** (from timestamps):
   - If any single tool call took >30 seconds (gap between consecutive ts values): note as "slow call" in results
   - Report average time per tool call
   
   Floor at 0, cap at 100.
   
   If trace.jsonl doesn't exist, fall back to metrics.json. If neither exists: redistribute L2 weight to L0.

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
   - `metrics.json`: Copy of the task-runner's metrics summary
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
