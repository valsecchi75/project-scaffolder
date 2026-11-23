---
description: Fix a known bug systematically - reproduce, failing test, isolate, root cause, minimal fix, proof, then record it in known-errors and guardrails.
argument-hint: "<symptom, error message or finding number>"
model: fable
---

Load the `project-scaffolder:bug-hunt` skill and run the **`/fix-bug`** procedure for: $ARGUMENTS

No fix before the cause is shown with evidence. After three disproved hypotheses, stop and ask the user.
