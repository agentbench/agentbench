---
description: Interactive wizard to create a new benchmark task
---

# Create Benchmark Task

Guide the user through creating a new benchmark task.

## Workflow

Spawn the task-author subagent to interactively help the user create a task. Pass $ARGUMENTS if any were provided.

The task-author agent will walk the user through:
1. Choosing a suite (domain)
2. Naming the task
3. Setting difficulty and mode
4. Writing the description and user message
5. Creating input files
6. Defining expected outputs and validators
7. Setting metric expectations and scoring weights

The result will be a complete task directory under tasks/{suite}/{task-id}/ with task.yaml and any input files.

After creation, suggest: "Task created! Run `/benchmark --task {task-id}` to test it."
