---
description: Record a bug or mistake that is already understood - KE-NNN in known-errors, ERR-NNN in guardrails, and propagate the lesson to the connected project skills. Use /fix-bug when the cause is not known yet.
argument-hint: "<short title>"
model: fable
---

Record this error: $ARGUMENTS

1. Collect, asking only what is missing: the context, the symptom (error output with secrets masked), the root cause, the fix, the test that now guards it, the project skills affected.
2. Root cause not known → stop and suggest `/fix-bug` instead.
3. Append `KE-NNN` to `wiki/debugging/known-errors.md` and `ERR-NNN` (pattern to avoid, correct pattern, skills affected, `Ref: KE-NNN`) to `guardrails/errors-to-avoid.md`. The two numbers increment independently.
4. Pass the lesson to the `project-scaffolder:synapse` skill (operation 3).
5. Log `## [date] error | KE-NNN <title>` in `wiki/log.md`.

Never delete earlier entries; a wrong one is marked superseded.
