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

## Workflow

### Step 0: Choose Execution Mode

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

Announce: `Starting AgentBench run {run-id} | Profile: {profile} | Suite version: {suite_version} | Tasks: {count}`

### Step 3: Execute Each Task

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
   - The workspace path
   - The list of input files available in the workspace
   - The mode (sandboxed/real)
   - Do NOT pass expected_outputs, validators, or scoring info to the task-runner

3b. **Compute metrics summary** after task-runner completes:
   - Check `.agentbench-tmp/metrics/` for `events.jsonl`
   - If it exists, run: `bash ${CLAUDE_PLUGIN_ROOT}/lib/compute-summary.sh .agentbench-tmp/metrics/`
   - If no events.jsonl found, metrics will be unavailable for this task

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
   - Read the metrics summary from `.agentbench-tmp/metrics/summary.json`
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
   - If no metrics available (hooks didn't fire), score as 50 with a note

6. **Layer 2 — Behavioral Analysis** (you compute this directly from the JSONL events log):
   Read events from `.agentbench-tmp/metrics/events.jsonl`
   
   Start at 100 points, apply penalties:
   
   **Tool appropriateness** (check from JSONL events):
   - Count PostToolUse events where tool="Bash" and the input contains "cat ", "head ", "tail ", or "less " followed by a filename → each instance: -3 points (max -15)
   - Count PostToolUse events where tool="Bash" and the input contains "echo " + ">" or "printf " + ">" for file creation → each instance: -3 points (max -15)
   
   **Read-before-write pattern**:
   - Check if any Read/Bash-cat events for input files exist BEFORE the first Write event for output files
   - If inputs existed but agent wrote output without reading any inputs first: -20 points
   - If no input files for this task: no penalty
   
   **Efficiency**:
   - Count duplicate file reads (same file read more than once): -3 points each (max -15)
   - Count PostToolUseFailure events (tool errors): -5 points each (max -20)
   
   **Error recovery**:
   - If PostToolUseFailure events exist, check if a successful retry follows within 3 events: +5 points back per recovered error
   
   Floor at 0, cap at 100.
   
   If no JSONL events available (hooks didn't fire), score as 50 with a note.

7. **Compute composite score**:
   ```
   score = (L0 * layer0_weight) + (L1 * layer1_weight) + (L2 * layer2_weight)
   ```
   Use weights from task.yaml scoring section, or defaults: L0=0.40, L1=0.40, L2=0.20

8. **Save task result** to `agentbench-results/{run-id}/{task-id}/`:
   - `scores.json`: All layer scores, composite score, breakdown
   - `metrics.json`: Copy of the hooks metrics summary (if available)
   - Copy any output files the task-runner created

9. **Display task result** to user:
   ```
   {task.name}: {composite}/100 (L0:{l0} L1:{l1} L2:{l2})
   ```

### Step 4: Generate Report

After all tasks complete:

1. Collect all task scores and metrics from agentbench-results/{run-id}/
2. Compute domain averages (group tasks by suite, average composite scores)
3. Compute overall score (average of domain scores — equal domain weighting)
4. Compute aggregate metrics (total tool calls, total errors, avg planning ratio, total time)
5. Spawn the report-generator subagent with:
   - run_id
   - mode
   - profile ("fast" or "full")
   - suite_version
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
