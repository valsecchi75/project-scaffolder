---
name: wrap
description: End-of-session ritual. Updates handoff, priorities, daily log, and triggers synapse hygiene. Optional git commit with --commit flag.
---

# /wrap

End-of-session ritual. Run before closing the chat to preserve context for the next session.

## Usage

```
/wrap
/wrap --commit
```

## Steps

1. Update `wiki/priorities.md` — mark completed tasks, adjust queue, record blockers
2. Update `wiki/handoff.md` — what was done, what remains, which files the next session should read first
3. Create/append `daily-log/YYYY-MM-DD.md`:
   - Tasks completed (with VERIFY evidence)
   - Decisions made (reference DEC-NNN)
   - Errors encountered (reference KE-NNN / ERR-NNN)
   - Approximate time
4. Update `wiki/log.md` if a phase-level milestone was reached
5. Trigger Synapse Operation 4 (map hygiene): prune connections to deleted skills, trim "Recent Propagations" to last 20, flag orphan skills
6. If `--commit`: stage modified files, generate commit message from completed tasks, create commit (never push)

## Rules

- Always produce a handoff, even for short sessions (minimum: "No progress, blockers: X").
- Never skip the daily log.
- `--commit` with mixed-intent work: ask for confirmation before committing.
- Never force-push or touch remote.
