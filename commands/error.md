---
name: error
description: Log a bug or error atomically — creates entries in known-errors and errors-to-avoid, propagates the lesson via Synapse.
---

# /error

Log a bug or error with full propagation to guardrails and connected skills.

## Usage

```
/error <short title>
```

## Examples

```
/error DateFormat crashes on Android 11 with IT locale
/error Isar schema migration fails when switching device
/error Push notification silently dropped on MIUI devices
```

## Prompt flow

1. **Context:** what were you doing when it happened?
2. **Error:** what went wrong? (paste stack trace if available)
3. **Root cause:** what was the real problem? (not the symptom)
4. **Fix:** how was it resolved?
5. **Affected skills:** which skills are relevant? (infer from domain, confirm with user)

## Atomic operations

1. Append to `wiki/debugging/known-errors.md`:
   ```
   ## KE-NNN: <title>
   **Date:** YYYY-MM-DD
   **Context:** ...
   **Error:** ...
   **Root cause:** ...
   **Fix:** ...
   ```
2. Append to `guardrails/errors-to-avoid.md`:
   ```
   ## ERR-NNN: <title>
   **Pattern to avoid:** ...
   **Correct pattern:** ...
   **Skills affected:** [list]
   **Ref:** KE-NNN
   ```
3. Call Synapse Operation 3 to propagate to affected skills.

## Rules

- `ERR-NNN` and `KE-NNN` auto-increment independently.
- Always cross-reference `KE` ↔ `ERR`.
- If the error has no identified root cause yet: log with status `[INVESTIGATING]`, refuse Synapse propagation until root cause is known.
- Never delete prior entries — even if the error was mis-categorized, mark as superseded.
