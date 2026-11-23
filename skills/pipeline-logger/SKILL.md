---
name: pipeline-logger
description: Use when a /task, /bug-hunt, /fix-bug, /milestone-close, /test-sweep, /improve or /5-release step completes or fails in a phase-managed project, or when /pipeline-stats reads the logs.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/pipeline-stats.sh" *)
---

# Pipeline Logger — the audit trail

One line per step: who, on which model, in which round, with what result. A script counts the log without reading it into context. Append only: never edit or delete a line.

```
logs/pipeline/YYYY-MM-DD.md          every operation of the day
logs/errors/YYYY-MM-DD-errors.md     failures only, with evidence
```

Create the day's file on the first write.

## Record format

Every operation is one header followed by its step lines:

```
## [HH:MM] <OP> <id> | <title>
- <step> | <agent>/<model> | r<n> | <RESULT> | <detail>; <detail>
```

- **OP:** `TASK`, `BUG-HUNT`, `FIX-BUG`, `MILESTONE-CLOSE`, `RELEASE`, `DESIGN`, `TEST-SWEEP`, `IMPROVE`, `GATE-SKIPPED`, `MODEL-FALLBACK`.
- **id:** `TASK-YYYY-MM-DD-NNN`, `KE-NNN`, `M<n>`, the version, the improve run, or `-`.
- **Fields:** exactly five, split by ` | `. Use `-` for a field that does not apply. RESULT is one uppercase word (`OK`, `PASS`, `FAIL`, `COMPLETED`, `BLOCKED`, `SKIPPED`, `FALLBACK`, `SUCCESS`, `FAILED`, `ESCALATED`). Details are separated by `;`, never by `|`.
- **Skipped steps** still get their line: RESULT `SKIPPED`, detail the reason (`Trivial`, `no interface change`).
- **Free text** (a bug-hunt findings table, a test-sweep table) goes only after the step lines of its block. The stats script reads headers and step lines only.

## A task

Steps in order: `meta`, `gate` (only when a gate was skipped), `plan`, `build`, `verify`, `bughunt`, `recheck`, `persona`, `synapse`, `outcome`. Repeat `build` and `verify` once per round.

```
## [14:05] TASK TASK-2026-11-23-002 | Show the renewal date on the widget
- meta | - | - | MEDIUM | M2 a3; standard; flags none
- plan | architect/fable | r1 | OK | docs/plans/tasks/TASK-2026-11-23-002.md; questions 1; skills app-widget, app-domain; design home-widget
- build | builder/opus | r1 | OK | 3 files +84/-6; steps 5/5; deviations none
- verify | verifier/fable | r1 | FAIL | criteria 6/7; MAJOR 1: date shown in the device locale
- build | builder/opus | r2 | OK | 1 file +4/-1; steps 1/1
- verify | verifier/fable | r2 | PASS | criteria 7/7
- bughunt | bug-hunter/fable | r1 | OK | C0 H1 M0 L0; confirmed 1; refuted 0; unverified 0; leads 1; ruled out injection, races
- recheck | sweeper/sonnet | r1 | OK | refutation; not refuted 1/1
- persona | persona-tester/sonnet | r1 | COMPLETED | Anna (first-time user); frictions 1; rework no
- synapse | - | - | OK | app-widget seed->growing; propagated app-domain; guardrail ERR-012
- outcome | - | r2 | SUCCESS | VERIFY: npm test -- widget passes 12/12
```

`meta` RESULT is the size (`TRIVIAL`, `MEDIUM`, `COMPLEX`); its details are milestone and activity, execution (`standard`, `decomposition`, `workflow`) and flags. `outcome` carries the total rounds and starts its detail with the VERIFY evidence.

## Other operations

Same line shape, their own steps: `bughunt` (scope, areas, severity counts, `confirmed n`), `fix` (KE-NNN, cause, test), `mass-test`, `critique`, release `gate`. A skipped gate is `- gate | - | - | SKIPPED | <which gate>; flag <flag>`; a fallback run is `- fallback | <agent>/<model> | - | FALLBACK | <why>; repeat on Fable`.

## Error entry (`logs/errors/YYYY-MM-DD-errors.md`)

```
## [14:12] ERROR TASK-2026-11-23-002 | verify failed
- agent | verifier/fable | r1 | FIXED | fixed in r2
What happened: one or two sentences.
    <the failing command and its output, trimmed to 20 lines>
```

RESULT is the resolution: `FIXED` (in a later round), `ESCALATED` (to the user) or `RECORDED` (with the KE-NNN / ERR-NNN in the detail). Write one whenever a verifier, bug-hunter confirmation, persona test, synapse validation or gate fails, and when a task hits the round limit of 3.

## Never log

- File contents or full diffs: file names and line counts are enough.
- The user's messages verbatim: the task title is enough.
- Secret values, tokens or personal data, even when the error is about them.

## `/pipeline-stats`

From the project root run `bash "${CLAUDE_SKILL_DIR}/scripts/pipeline-stats.sh" [--today|--week|--month|--all]` (default `--today`). It is read-only and prints pass rate, rounds, outcomes, bug-hunt yield, persona blocks, skipped gates, fallbacks, top skills, failures by agent, unparsable lines as `file:line`, and `flag:` lines for anomalies. Report those numbers plainly; do not recount them. To name the defect classes that keep coming back, open only the blocks it lists under `bug hunt`.

Older logs written in the earlier multi-section format show up as unparsable lines: report them as "old format", never rewrite them. If the script cannot run, count with `grep -h '^- verify |' logs/pipeline/*.md` and the like, and say so.
