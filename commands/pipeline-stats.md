---
description: Pipeline numbers from the logs - pass rate, rounds, escalations, bug-hunt yield, recurring defects. Read-only.
argument-hint: "[--week | --month | --all]"
disable-model-invocation: true
context: fork
model: sonnet
background: false
---

Load the `project-scaffolder:pipeline-logger` skill and produce the **`/pipeline-stats`** report for the timeframe: $ARGUMENTS (default: today). Get the numbers from the skill's `pipeline-stats.sh` script, not by reading the logs.

No logs yet → say so and suggest `/task`. Report bad numbers plainly and keep every `flag:` line. Change no file; return only the report.
