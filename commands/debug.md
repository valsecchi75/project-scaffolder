---
name: debug
description: Systematic debugging session — reproduce, isolate, diagnose, fix. Produces known-error and errors-to-avoid entries, propagates lesson via Synapse.
---

# /debug

Structured debugging (Karpathy debug principle). Do NOT guess — reproduce and isolate first.

## Usage

```
/debug <symptom description>
```

## Examples

```
/debug App crashes when adding a subscription with empty name
/debug DateFormat throws on Android 11 with IT locale
/debug Isar query returns stale data after save
```

## Phases

1. **Reproduce** — write exact steps that trigger the bug. Confirm reproducibility.
2. **Isolate** — binary-search the cause. Identify the minimum failing case.
3. **Hypothesize** — list 2-3 hypotheses, ranked by likelihood.
4. **Diagnose** — verify the top hypothesis with evidence (log, stack trace, diff).
5. **Fix** — the minimum change that resolves the diagnosed cause.
6. **Verify** — re-run repro steps, confirm fixed, add a regression test where appropriate.
7. **Document** — atomic operations:
   - Append entry to `wiki/debugging/known-errors.md` (ID `KE-NNN`)
   - Append entry to `guardrails/errors-to-avoid.md` (ID `ERR-NNN`, cross-referenced to KE-NNN)
   - Call Synapse to propagate the lesson to connected skills

## Rules

- NEVER skip Reproduce. If you can't reproduce, the bug is not understood.
- Prefer one small fix over a wide refactor.
- If root cause is shared infrastructure → flag Synapse for multi-skill propagation.
- If stuck after 3 hypotheses: STOP, ask the user for more context or escalate.
- Every `/debug` session ends with either a fix + documentation, or an explicit `[INVESTIGATING]` entry.
