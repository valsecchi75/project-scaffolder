---
name: implement
description: Execute a previously written plan through the Cortex pipeline. Injects the plan as primary context for step-by-step orchestrated execution.
---

# /implement

Execute an existing plan. Wrapper around `/task` that uses a plan file as structured input.

## Usage

```
/implement <plan-file-path>
/implement @latest
```

## Examples

```
/implement docs/superpowers/plans/2026-04-17-pull-to-refresh.md
/implement @latest
```

## Steps

1. Resolve plan path:
   - If `@latest` → pick the most recent file in `docs/superpowers/plans/`
   - Otherwise → read the provided path
2. Validate plan structure:
   - Has Goal, Steps, VERIFY criteria on every step
   - Plan file is less than 7 days old (otherwise context may be stale)
3. Pass the full plan to Cortex as primary context.
4. Cortex executes step-by-step:
   - Specialist implements step N
   - QA Agent verifies step N against its VERIFY criterion
   - If FAIL → return to specialist for that step only (max 2 iterations per step)
   - If PASS → proceed to step N+1
5. Log each step outcome to `logs/pipeline/YYYY-MM-DD.md`.

## Rules

- Refuse plans without VERIFY criteria on every step.
- Refuse plans older than 7 days — ask the user to regenerate.
- Max 2 iterations per step (stricter than default `/task` because the plan should have been pre-thought).
- If a step fails twice: stop, report to user, document in `wiki/debugging/failed-experiments.md`.
