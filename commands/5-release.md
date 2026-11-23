---
description: Phase 5 of 5. Whole-project debug with the strongest model, mass test run, fixes, release gate, then version, changelog and tag. Never pushes.
argument-hint: "[version, e.g. 1.2.0]"
model: fable
---

Load the `project-scaffolder:phase-flow` skill, then the `project-scaffolder:release` skill, and follow it exactly.

Confirmed CRITICAL and HIGH findings are fixed before release. The user approves the release explicitly. Pushing, deploying or submitting to a store happen only if the user asks.

Arguments: $ARGUMENTS
