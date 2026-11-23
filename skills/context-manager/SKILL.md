---
name: context-manager
description: Use when /session-start or /session-end runs, after every task in a phase-managed project, right after a compaction, when the context grows heavy, or when the user asks for a handoff, a continuation prompt or a /compact focus line.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/session-brief.sh") Bash(bash "${CLAUDE_SKILL_DIR}/scripts/session-close.sh" *)
---

# Context Manager — sessions, compaction and handoff

The wiki is long-term memory; the chat is working memory, renewed before its quality degrades. Sessions open from the wiki and close back into it.

## Standing rules

These come first because a compaction re-attaches only the start of a skill, and may drop an old one entirely.

1. **Disk, not chat.** Whatever must outlive the conversation (a decision, the exact point reached, an instruction the user gave in chat) is written to the wiki before you move on: `wiki/handoff.md`, `wiki/priorities.md`, `wiki/product/decisions.md`, or `CLAUDE.md` with the user's agreement. A compaction summarizes the chat. Instructions given only in chat, path-scoped rules and nested CLAUDE.md files are summarized away. The project-root CLAUDE.md, unscoped rules and auto memory are re-read from disk. Invoked skills come back capped at 5,000 tokens each and 25,000 in total, oldest dropped first.
2. **After a compaction** (the history was replaced by a summary, or the phase rules arrived again mid-session): before the next edit or dispatch, read `.scaffolder/compact-snapshot.md` (the plugin's PreCompact hook writes it from disk just before every compaction), `wiki/handoff.md` and the current plan (milestone plan, design registry, `/task` plan, or in phase 5 the release report and its rounds journal). For exact points, ids and verdicts, trust the files over the summary. When the handoff is older than the work the summary describes, bring it up to date first.
3. **The user runs the context commands.** `/compact`, `/clear`, `/context`, `/rewind` and `/autocompact` are built-in commands that Claude cannot invoke. When one is due, say so and give the exact line to type.
4. **Two memories, two jobs.**
   - Auto memory (`~/.claude/projects/<project>/memory/`) holds the user's preferences and corrections. It is personal, stays on this machine and is not loaded into subagents.
   - The wiki (in the repository, versioned, read by the agents) holds decisions, architecture, progress and errors.
   - A project fact never lives only in auto memory. A personal preference does not go in the wiki.

## Context budget

- Threshold: **300k tokens** by default; the project's `CLAUDE.md` can change it.
- Claude cannot measure its own usage. Use these signals, most reliable first:
  - the `/context` grid, when the user shares it;
  - the context indicator in the VS Code prompt box, which shows from 50 % by default;
  - an automatic compaction already happened in this chat;
  - the number and size of the files read.
- When unsure, assume you are closer to the threshold than you think.
- Above the threshold: no new task. Finish the current step if it is nearly done, then pick a move from the table below.
- Session cost and plan limits: `/usage` (alias `/cost`). Suggest it when the user asks what a session cost.
- Keep the window lean:
  - link wiki pages instead of pasting them, and read excerpts instead of whole files;
  - send large reads and searches to a subagent;
  - after a wrong path, `/rewind` and re-prompt with the lesson instead of piling corrections on top.

## Compact, clear or hand off

| Situation | Tell the user |
|---|---|
| Same work continues, context heavy | `/compact` (a focus only when needed, below) |
| A phase or milestone gate just passed, or the next task is unrelated | Write the handoff, then `/clear` and `/session-start` |
| `CLAUDE.md` or an unscoped rule changed this session (foundation, wiki-keeper, a new working agreement) | `/clear` or `/compact`: until then the running session keeps the old copy |
| Above the threshold and the session is ending | Handoff procedure, then `/clear` and the continuation line |

Every compaction, automatic or manual, already gets its keep-list without the user typing it: the plugin's PreCompact hook hands the summary the phase, plan, handoff age and uncommitted files read from disk, and asks it to keep the active `/task` id and step, the `DEC-NNN` decided in the chat, the last verifier verdict, open findings, chat-only instructions and the exact next step. The **Compact instructions** section of the project's `CLAUDE.md`, when present, adds the project's own items. So plain `/compact` is the default. Give a focus only for something that list misses, on one line:

```
/compact keep: <what this session must not lose>; drop: <finished exploration or dumps>
```

## Session start (`/session-start`)

Read-only orientation, then one briefing.

1. Run `bash "${CLAUDE_SKILL_DIR}/scripts/session-brief.sh"` from the project root. In one read-only call it prints the phase, the Claude Code version check, the current plan path, the handoff, a compaction snapshot when it is newer than the handoff, the open priorities and the guardrail ids. Do not open those files again, and do not re-read `CLAUDE.md`: it is already in context. Open the plan, and only the guardrail entries that match the next items.
2. **Claude Code check**, from the `claude-code:` line:
   - `unchanged`: say nothing about it.
   - `CHANGED`: run the script again with `--changelog`. It downloads the changelog and prints only the non-fix lines newer than the recorded version that touch agents, hooks, skills, plugins, models, Artifacts, compaction, memory, workflows or removals. Put the ones that affect this project in the briefing. Then update `wiki/claude-code.md`: set the line `Last checked version: <installed>` and add those notes.
   - `none recorded`: add the `Last checked version:` line, with no changelog read.
   - `older`, `unknown` (`claude` is not on the PATH of the shell), or a failed download: say so in one line and continue.

   A `compact-snapshot.md is newer than the handoff` block means the last session compacted after its last handoff and may have ended without `/session-end`. Compare its uncommitted files and plan with the handoff, say in "Last session" that the handoff may be behind, and make "update `wiki/handoff.md` from the snapshot and git" the first of the next three.

   Only if the script cannot run (no Git Bash on Windows), read `.scaffolder/phase`, `wiki/handoff.md`, `wiki/priorities.md` and the plan by hand, and say so.
3. **Focus**: when the command carries one (the continuation line of the last handoff), put that activity first in "Next three". The handoff and the plan stay the source of truth: if the focus disagrees with them, follow the files and say so.
4. Briefing, at most twelve lines:

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

Start with `bash "${CLAUDE_SKILL_DIR}/scripts/session-close.sh"` from the project root. It is read-only and prints today's daily-log path, the handoff and priorities line counts against their caps, the changed files grouped for the commit, the touched wiki pages whose `last-verified` is not today, and the stale pages. Act on its lines instead of opening pages to check them. Without Git Bash, do these checks by hand and say so.

1. `wiki/priorities.md`: tick what is done (with evidence), record blockers. What was discovered but is not planned (advice, ideas, checks asked for and not run) goes to the notebook `wiki/todo.md` (backlog skill, `from: session`).
2. `wiki/handoff.md`: done, in progress (the exact point), next with its VERIFY criterion, files to read first, stable files not to re-read. Always written, even for a short session ("no progress, blocked by …").
3. The daily log the script names: tasks with evidence, decisions (`DEC-NNN`), errors (`KE-NNN`, `ERR-NNN`).
4. Instructions the user gave in chat that should keep applying: propose each one for the **Working agreements** of `CLAUDE.md` when it is about the project, or leave it to auto memory when it is personal. Ask before writing to `CLAUDE.md`.
5. Wiki hygiene, from the script's lines: set `last-verified` to today on every page it lists as touched and on the pages written in steps 1-3; move overflow of a page `OVER` its cap to the archive (wiki-keeper skill); report the stale pages, with `/wiki-lint` when it suggests one.
6. Synapse map hygiene (synapse skill, operation 4).
7. `--commit`: stage only this session's files by name, write a commit message from the work done, commit. Never push. Ask before committing when the changes mix unrelated work or the script reports files already staged. A `NEVER COMMIT` line stops the commit until the file is git-ignored.
8. Context above the threshold → run the handoff procedure below.

## Handoff procedure

1. Update `wiki/handoff.md` and `wiki/priorities.md` as in session end. The handoff is the whole continuation: nothing is carried in chat.
2. End with the continuation line, for the user to type:

```
/clear, then: /session-start <activity> at <exact point>
```

A new chat works as well as `/clear`. Either way the fresh session loads `CLAUDE.md` by itself, the phase hook runs, and the session brief prints the handoff and the plan path in one call. So the line only names the focus, and no file is read twice or pasted.
