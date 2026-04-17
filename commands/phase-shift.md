---
name: phase-shift
description: Formal transition between development phases. Archives the current phase state and opens the next. Updates roadmap, CLAUDE.md, priorities, and log.
---

# /phase-shift

Transition from the current phase to the next. Execute only when the current phase is actually complete.

## Usage

```
/phase-shift <target-phase-number>
/phase-shift <target-phase-number> --force
```

## Examples

```
/phase-shift 3
/phase-shift 4 --force
```

## Steps

1. Verify the current phase is complete (every task in `priorities.md` checked with VERIFY evidence)
2. If incomplete and no `--force` flag → STOP and list remaining work
3. Mark the current phase `[COMPLETED]` in `wiki/product/roadmap.md` with completion date
4. Update `CLAUDE.md` → "Current phase: [new phase]"
5. Generate a fresh `wiki/priorities.md` populated from the new phase in the roadmap
6. Append a milestone entry to `wiki/log.md`
7. Reset `wiki/handoff.md` for the first session of the new phase

## Rules

- Refuse to shift if the current phase has unchecked VERIFY criteria, unless `--force` is passed.
- Never skip phases (N → N+2) without `--force`.
- Preserve old priorities — archive to `wiki/product/archive/phase-N-priorities.md` before overwriting.
