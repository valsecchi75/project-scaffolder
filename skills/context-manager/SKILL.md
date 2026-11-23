---
name: context-manager
description: Use when /session-start or /session-end runs, at the end of every task in a phase-managed project, and whenever the session context grows heavy or the user asks for a handoff or a continuation prompt.
---

# Context Manager — sessions and handoff

The wiki is long-term memory; the chat is working memory, renewed before its quality degrades. Sessions open from the wiki and close back into it.

## Session start (`/session-start`)

Read-only orientation, then one briefing.

1. Read `.scaffolder/phase`, `CLAUDE.md`, `wiki/handoff.md`, `wiki/priorities.md`, the most relevant entries of `guardrails/errors-to-avoid.md`, and the current milestone plan or design registry depending on the phase.
2. **Claude Code check.** Run `claude --version` and compare it with the version in `wiki/claude-code.md`. When it changed, read only the newer entries of https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md (raw: `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`), list in the briefing the changes that affect this project (agents, hooks, skills, models, Artifacts, deprecations), and update `wiki/claude-code.md` with the new version and those notes. When it did not change, say nothing about it. When the version cannot be read, say so in one line and continue.
3. Briefing, at most twelve lines:

```
Phase: <n — name> · Milestone: M<n> · Mode: <mode>
Last session: <one sentence from the handoff>
Next three:
  1. <item> → VERIFY: <criterion>
  2. …
Watch out: <at most two guardrails relevant to the next items>
Claude Code: <only when it changed: version, what matters>
Next command: <one>
```

Do not change any file except `wiki/claude-code.md`, and do not start work.

## Session end (`/session-end [--commit]`)

1. `wiki/priorities.md`: tick what is done (with evidence), add what was discovered, record blockers.
2. `wiki/handoff.md`: done, in progress (the exact point), next, files to read first. Always written, even for a short session ("no progress, blocked by …").
3. `daily-log/<today>.md`: tasks with evidence, decisions (`DEC-NNN`), errors (`KE-NNN`, `ERR-NNN`).
4. Wiki hygiene: `last-verified` on every page touched; line caps (overflow to the archive, as in the wiki-keeper skill); report pages older than 30 days and suggest `/wiki-lint` when there are more than five.
5. Synapse map hygiene (synapse skill, operation 4).
6. `--commit`: stage the changes, write a commit message from the work done, commit. Never push. Mixed work → ask before committing.
7. Context above the threshold → run the handoff procedure below.

## Threshold

- Default **300k tokens**; the project's `CLAUDE.md` can change it.
- Estimate from the context warnings, the files read and the length of the conversation. When unsure, assume you are closer to the threshold than you think.
- Above it: no new task. Finish the current step if it is nearly done, then hand off.

## Handoff procedure

1. Update `wiki/handoff.md` and `wiki/priorities.md` as in session end.
2. Print the continuation prompt as the last message, for the user to paste into a fresh chat:

```
# Continue: <project> — phase <n>, milestone M<n>

Read, in order, nothing else:
1. CLAUDE.md
2. wiki/handoff.md
3. <milestone plan or design registry>

State: <done>; in progress: <activity> at <exact point>.
Next: <activity> — VERIFY: <criterion>.
Do not re-read: <stable files already processed>.
```

At most 25 lines: the wiki holds the detail, the prompt only points.

## Minimal context

- Wrong path → `/rewind` and re-prompt with the lesson, instead of piling corrections on a polluted context.
- Between large tasks → `/clear` and a written brief (the task plan is the brief).
- `/compact` always with a hint ("keep decisions and the current activity state").
- Link wiki pages, do not paste them. Excerpts over whole files.
