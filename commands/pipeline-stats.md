---
description: Numbers from the pipeline logs - tasks, first-round pass rate, rounds, escalations, bug-hunt yield, recurring defect classes, persona blocks, skills used. Answers whether the pipeline is helping. Read-only.
argument-hint: "[--week | --month | --all]"
model: sonnet
---

Load the `project-scaffolder:pipeline-logger` skill and produce the **`/pipeline-stats`** report for the timeframe: $ARGUMENTS (default: today).

No logs yet → say so and suggest `/task`. Report bad numbers plainly and flag anomalies.
