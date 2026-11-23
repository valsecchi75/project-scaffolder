---
description: Improvement loop, 10 to 100 iterations. Each proposes one change, builds it in an isolated worktree and has it refuted; checkpoints and a final diff you approve.
argument-hint: "[resume <run-id>]"
disable-model-invocation: true
---

Load the `project-scaffolder:improve-loop` skill and follow it exactly. Every question is asked here, with AskUserQuestion, before anything launches. Nothing reaches the working tree until the user approves the final diff.

Arguments: $ARGUMENTS
