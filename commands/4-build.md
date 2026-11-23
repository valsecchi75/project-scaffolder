---
description: Phase 4 of 5. Choose the platform, plan the current milestone, then build it task by task. Shows where the build stands and the next activity.
argument-hint: "[--status]"
disable-model-invocation: true
---

Load the `project-scaffolder:phase-flow` skill, then the `project-scaffolder:cortex` skill, and follow it.

On the first run: the platform decision (the user chooses), then the project's `verify` skill and the stack skills, then the plan of milestone M1. On later runs: the plan of the current milestone if it has none, otherwise its status and the next activity to run with `/task` (or `/task --parallel <#,#>` when two or more ready activities are `Parallel = yes`). With `--status`, report only.

Arguments: $ARGUMENTS
