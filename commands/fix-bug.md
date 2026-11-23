---
description: Fix a known bug systematically - reproduce, failing test, isolate, root cause, minimal fix, proof, then record it in known-errors and guardrails.
argument-hint: "<symptom, error message or finding number>"
---

Load the `project-scaffolder:debugging` skill and run the **`/fix-bug`** procedure for: $ARGUMENTS

No fix before the cause is shown with evidence. After three disproved hypotheses, stop and ask the user. The diagnosis is designed for a Fable session and the command does not switch models: on another model, say so in one line and suggest `/model fable`.
