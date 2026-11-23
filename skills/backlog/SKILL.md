---
name: backlog
description: Use when /todo runs; when the user mentions something for later (advice, an idea, a check or a bug hunt to do, a doubt); when a bug hunt, review, persona test or release defers a finding; when a session ends with loose ends; or when /milestone-plan picks the next work.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/todo-report.sh" *)
---

# Backlog — the project notebook

`wiki/todo.md` collects everything that could go into the project but is not planned yet: users' and testers' advice, loose ideas, bug hunts or checks asked for and never run, deferred findings, debt, open questions. It is the inbox; `wiki/priorities.md` stays the committed queue of the current milestone. Nothing is lost between sessions, and the next plan starts from a sorted list instead of memory.

## The file

Created on the first capture from `templates/todo.md` in this skill's folder. One line per item, never deleted:

```
- [ ] T-007 | P1 | debug | 2026-11-23 | Bug hunt on offline sync, asked in M1, never run | from: user
```

- **Status:** `[ ]` open · `[>]` planned (`| -> M2 a3`) · `[x]` done (`| -> done <date>: <evidence>`) · `[-]` dropped (`| -> dropped: <reason>`). Closing an item changes its mark and appends the outcome; the line stays.
- **Priority:** `P1` hurts users or blocks a release, next milestone · `P2` clear value · `P3` someday. Propose one; the user's word wins.
- **Type:** `feedback`, `idea`, `debug`, `debt`, `question`, `doc`.
- **from:** `user`, `persona <name>`, `bug-hunt <task-id>`, `review`, `release v<x>`, `research <slug>`, `session`.
- The text is one actionable sentence. No secret values, no personal data, no pasted logs: point to the file instead.

Get the next id and the current state from `bash "${CLAUDE_SKILL_DIR}/scripts/todo-report.sh" [--all|--next]` (read-only, prints counts, open items by priority and age, and `flag:` lines). Never recount by reading the file, unless the script cannot run (no Git Bash): then Grep the `- [ ] T-` lines once and say so.

## `/todo` (no argument) — show

Run the script and show its output as is, then one line: the item you would do first and why. Flags (old P1 items, stale items, unparsable lines) are named, not fixed silently.

## `/todo add <text>` and automatic capture

Append one line with the next id, today's date, a proposed priority and type, and the source. Say in one line what was added (`T-012 P2 idea added`). Capture without being asked when:

- the user says "later", "remember", "one day", or gives advice that is out of the current task's scope;
- a MEDIUM or LOW finding, an unverified finding or a lead is deferred (debugging, cortex, release), with `from: bug-hunt <id>` or `release v<x>`;
- a persona test reports a friction that is not fixed in the task;
- `/session-end` leaves something unfinished that is not already in the handoff or the plan.

Before appending, check the open items for the same thing: update that line's priority instead of adding a duplicate.

## `/todo done <id> <evidence>` · `/todo drop <id> <reason>` · `/todo P<n> <id>`

Change the mark or the priority of that one line and append the outcome. Done needs evidence (a commit, a test, a VERIFY result); without it, ask.

## `/todo triage`

Run the script; for the open items without a clear priority, the flagged ones and the P1s, ask the user with AskUserQuestion (up to four items per call, options keep / raise / lower / drop). Write the answers, then show the new order.

## Planning reads it

`/milestone-plan` runs the script and offers the open P1 items and the fitting P2s as candidate activities; the ones taken become `[>]` with `-> M<n> a<k>`. `/milestone-close` lists what is still open and asks whether any P1 moves to the next milestone.

## Phases

The file lives in `wiki/`, which `/2-foundation` creates; it may be written from phase 2 on. Phase 1 writes only the brief and `raw/` (the phase guard refuses `wiki/` there): a solution the user volunteers goes to `raw/parking-lot.md`, anything else for later under the brief's **Open questions** (brainstorm skill).
