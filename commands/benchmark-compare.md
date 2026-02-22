---
description: Compare two benchmark runs or skill vaults side-by-side
---

# Benchmark Compare Command

Compare benchmark results between two runs or two skill configurations.

## Arguments

Parse from $ARGUMENTS:
- `--run-a <run-id> --run-b <run-id>`: Compare two existing runs
- `--vault-a <path> --vault-b <path>`: Run benchmarks against two skill vaults and compare

## Workflow: Compare Existing Runs

1. Load results.json from both run directories in agentbench-results/
2. Check version and profile compatibility:
   - If `suite_version` differs between runs: warn that score differences may reflect task changes, not agent performance
   - If `profile` differs between runs: warn and only compare tasks present in both runs (intersection)
   - If either run is missing `suite_version` or `profile` fields (pre-versioning run): note that comparison may be unreliable
   - Add a metadata header row to the comparison output showing: run IDs, timestamps, profiles, and suite versions
3. Produce a comparison showing:
   - Overall scores side-by-side with delta and winner
   - Per-domain comparison table:
     ```
     | Domain          | Run A | Run B | Delta | Winner |
     |-----------------|-------|-------|-------|--------|
     | File Creation   | 82    | 85    | +3    | B      |
     ```
   - Per-task deltas (sorted by biggest improvement)
   - Metrics comparison (time, tools, planning ratio)
   - Clear recommendation: which run performed better and why

## Workflow: Compare Vaults (A/B Test)

1. Warn the user: "This will run the full benchmark suite twice. Estimated cost: $2-8."
2. Ask for confirmation before proceeding
3. Run `/benchmark` with vault A's skills → save as run A
4. Run `/benchmark` with vault B's skills → save as run B
5. Run the comparison workflow above

## Output

Save comparison to:
- `agentbench-results/compare-{runA}-vs-{runB}/comparison.md`
- `agentbench-results/compare-{runA}-vs-{runB}/comparison.html`
- `agentbench-results/compare-{runA}-vs-{runB}/comparison.json`

Open comparison.html in the browser when done.
