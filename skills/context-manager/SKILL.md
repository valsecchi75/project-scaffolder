---
name: context-manager
description: Use at the end of every task in a scaffolded project and whenever the session context grows heavy. Enforces the context threshold, generates the continuation prompt for the next chat, and applies context minimalism rules. Triggers on "context check", "continuation prompt", "handoff", or context warnings.
---

# Context Manager

## Overview

Keeps sessions inside a healthy context window. The wiki is long-term memory; the chat is working memory that must be renewed BEFORE quality degrades (context rot).

**Core principle:** hand off proactively at the threshold, never reactively at the limit.

## Threshold Check (after every completed task)

- Threshold: **300k tokens** by default — configurable via the "Context threshold" line in the project CLAUDE.md.
- Estimate consumption from: system context warnings, number/size of files read this session, conversation length. When in doubt, assume you are CLOSER to the threshold than you think.
- Below threshold → continue normally.
- **Above threshold → no new activities.** Finish the current activity if nearly done, then run the Handoff Procedure.

## Handoff Procedure

1. Update `wiki/handoff.md` (≤80 lines): done, in progress, next, files to read.
2. Update `wiki/priorities.md` (≤100 lines): checkbox states current.
3. Generate the **Continuation Prompt** (template below, ≤40 lines) and print it as the final message so the user can paste it into a fresh chat.
4. Update `daily-log/YYYY-MM-DD.md`.

## Continuation Prompt Template

```
# Continue: {project} — Phase {N}

Read in order (nothing else):
1. CLAUDE.md
2. wiki/handoff.md
3. docs/phases/PHASE-{N}-execution.md

State: activities {list} DONE; activity {n} IN PROGRESS at {exact point}.
Next: activity {n} — {description}. VERIFY: {criterion}.
Mode: {Normal/Autopilot/Autonomous}. Context threshold: {X}k.
Do NOT re-read: {stable files already processed}.
```

## Context Minimalism Rules

Injected into every generated CLAUDE.md:

1. **Wrong path → `/rewind` + re-prompt** with the lesson learned. Never pile inline corrections on a polluted context.
2. **Between large tasks → `/clear` + written brief** (the Execution Doc activity is the brief).
3. **`/compact` always with a hint** ("keep decisions and current activity state").
4. **Inject the minimum:** link wiki pages instead of pasting them; excerpts over full files.

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Push through the threshold "to finish the phase" | Hand off — the next chat finishes with fresh quality |
| Write a continuation prompt >40 lines | The wiki holds the detail; the prompt only points |
| Correct a derailed session inline for the third time | `/rewind`, add the lesson to the prompt, go again |
