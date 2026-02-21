---
description: View the results of the most recent benchmark run
---

# Benchmark Results Command

Display results from a previous benchmark run.

## Workflow

1. Look for `agentbench-results/` in the current directory
2. List subdirectories (each is a run-id, format: YYYYMMDD-HHmmss)
3. Sort by name descending to find the most recent run
4. If $ARGUMENTS contains a specific run-id, use that instead
5. If $ARGUMENTS contains `--open` or no other flags:
   - Open the HTML report in the browser:
     - Windows: `start agentbench-results/{run-id}/report.html`
     - macOS: `open agentbench-results/{run-id}/report.html`
     - Linux: `xdg-open agentbench-results/{run-id}/report.html`
6. If $ARGUMENTS contains `--md`, read and display report.md to the user
7. If $ARGUMENTS contains `--json`, read and display results.json
8. If $ARGUMENTS contains `--list`, list all available run IDs with date and overall score:
   ```
   Available Benchmark Runs:
     20260221-143022    2026-02-21 14:30    Score: 74/100
     20260220-091500    2026-02-20 09:15    Score: 68/100
   ```
9. If no results found, tell the user: "No benchmark results found. Run `/benchmark` first."
