---
name: kickoff
description: Start-of-session ritual. Reads CLAUDE.md, handoff, priorities, guardrails, and synapse map. Produces a situational briefing. Does not modify any file.
---

# /kickoff

Read-only orientation ritual. Run BEFORE any other work in a new session.

## Steps

1. Read `CLAUDE.md` — current phase, project state
2. Read `wiki/handoff.md` — what the previous session left
3. Read `wiki/priorities.md` — what is queued
4. Read `guardrails/errors-to-avoid.md` — what must not repeat
5. Read `skills/_synapse-map.md` (if exists) — current skill connections

## Output format

```
## Briefing — YYYY-MM-DD

**Current phase:** [N — name, started YYYY-MM-DD]
**Last session:** [1-sentence summary from handoff.md]
**Top 3 priorities:**
  1. [task] → VERIFY: [criterion]
  2. ...
  3. ...
**Guardrails to remember:** [max 3 most relevant to current phase]
**Skills likely needed:** [inferred from priorities + synapse map]
**Recommended next action:** [one concrete step]
```

## Rules

- Do NOT modify any file.
- Do NOT start implementation work — this is orientation only.
- If a required file is missing, report it clearly and stop.
- If `CLAUDE.md` doesn't exist → suggest `/scaffold` instead.
