---
description: List all available benchmark tasks grouped by suite
---

# Benchmark List Command

List all available benchmark tasks.

## Workflow

1. Read all task.yaml files from the `tasks/` directory tree using Glob to find `tasks/**/task.yaml`
2. Parse each task.yaml to extract: name, id, suite, difficulty, mode
3. Group by suite
4. Display as a formatted table:

```
Available Benchmark Tasks:

FILE CREATION (N tasks)
  * {id}    {difficulty}    {mode}    {name}

RESEARCH (N tasks)
  * {id}    {difficulty}    {mode}    {name}

... (for each suite that has tasks)

Total: {N} tasks across {M} suites
```

5. If $ARGUMENTS contains `--suite <name>`, filter to only that suite
6. If $ARGUMENTS contains `--json`, output as a JSON array instead of formatted text
