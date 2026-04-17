---
name: plan
description: Produce an implementation plan BEFORE touching code. Outputs a plan file with numbered steps and verifiable criteria. Does not execute.
---

# /plan

Think before coding (Karpathy principle). Produces a written plan with verifiable criteria. Does NOT implement.

## Usage

```
/plan <task description>
```

## Examples

```
/plan Implement pull-to-refresh on the subscription list
/plan Migrate storage from SharedPreferences to Isar
/plan Add Android home-screen widget showing monthly total
```

## Steps

1. If the `superpowers:writing-plans` skill is available → delegate to it.
2. Otherwise, read relevant context:
   - `wiki/architecture.md`, `wiki/tech-stack.md`
   - Any skill matching the task domain
   - `guardrails/errors-to-avoid.md`
3. Produce the plan file at `docs/superpowers/plans/YYYY-MM-DD-<slug>.md`.

## Plan structure (required sections)

- **Goal:** one sentence, unambiguous
- **Context:** files likely touched, skills involved
- **Assumptions:** tagged `[HYPOTHESIS]` or `[FACT]`
- **Steps:** numbered, each with a concrete action and `→ VERIFY: <criterion>`
- **Rollback:** how to undo if a step fails
- **Out of scope:** what this plan will NOT do

## Rules

- Do NOT write implementation code.
- Do NOT modify source files.
- If the task is ambiguous, ask clarifying questions before writing the plan.
- Every step must have a verifiable criterion — no vague "ensure it works".
- Plans are reviewable artifacts: assume a human reviews before `/implement`.
