---
name: pipeline-logger
description: Use when a /task, /bug-hunt, /fix-bug, /milestone-close or /5-release step completes or fails in a phase-managed project, or when /pipeline-stats needs to read the logs.
---

# Pipeline Logger — the audit trail

Every step that flows through the pipeline is written down: who did it, on which model, with what result. Failures are written twice, so they can be found fast.

```
logs/
├── pipeline/YYYY-MM-DD.md          every operation of the day
└── errors/YYYY-MM-DD-errors.md     failures only, cross-referenced
```

Create the day's files on the first write. One file per day, append only, never deleted.

## Task block (`logs/pipeline/YYYY-MM-DD.md`)

```markdown
---

## [HH:MM] TASK-YYYY-MM-DD-NNN — "{task}"

**Milestone:** M{n} · activity {#} · **Size:** Trivial | Medium | Complex · **Flags:** {…}
**Execution:** standard | decomposition | workflow (user choice)

### Plan — architect (Fable)
- Plan: docs/plans/tasks/{task-id}.md · open questions: {n, answered by the user | none}
- Skills: {project skills used} · Design section: {registry section | —}

### Build — builder (Opus) · round {n}
- Files: {list} · +{added} / -{removed}
- Steps verified by the builder: {n}/{n} · deviations: {none | …}

### Verify — verifier (Fable) · round {n}
- Verdict: PASS | FAIL · criteria met {n}/{n}
- Findings: {BLOCKER/MAJOR/MINOR counts; one line each on FAIL}

### Bug hunt — bug-hunter (Fable) · second opinion — sweeper (Sonnet)
- Findings: {CRITICAL/HIGH/MEDIUM/LOW counts} · confirmed {n} · unconfirmed {n} · leads {n}
- Classes ruled out: {list}

### Persona test — persona-tester (Sonnet)
- {name, archetype} → COMPLETED | BLOCKED at step {n} | frictions {n}
- Rework: yes (reason) | no

### Synapse
- Updated: {skill} ({maturity old → new}) · propagated to: {skills} · guardrail: {ERR-NNN | none}

### Outcome
- SUCCESS | FAILED | ESCALATED · rounds {n} · evidence: {the VERIFY line}
```

Sections that did not run say why in one line ("skipped: Trivial", "skipped: no interface change").

## Other operations

Same file, shorter blocks headed `## [HH:MM] <OP> — <title>`, for: `BUG-HUNT` (scope, areas, findings table), `FIX-BUG` (KE-NNN, cause, test), `MILESTONE-CLOSE` (mass-run results), `RELEASE` (version, gate verdict), `DESIGN` (section, critic verdict, rounds), `GATE-SKIPPED` (which gate, by which flag).

## Error entry (`logs/errors/YYYY-MM-DD-errors.md`)

```markdown
---

## [HH:MM] {step} failed — TASK-YYYY-MM-DD-NNN

**Agent:** {name} ({model}) · **Round:** {n} of 3
**What happened:** {one paragraph}
**Evidence:**
    {the failing command and its output, trimmed}
**Resolution:** fixed in round {n} | escalated to the user | recorded as KE-NNN / ERR-NNN
```

Log an error entry whenever a verifier, bug-hunter confirmation, persona block, synapse validation or gate fails, and whenever a task hits the round limit.

## Never log

- File contents or full diffs: file names and line counts are enough.
- The user's messages verbatim: the task description is enough.
- Secret values, tokens or personal data, even when the error is about them.

## Queries for `/pipeline-stats`

```bash
grep -c '^## \[.*\] TASK-' logs/pipeline/*.md                  # tasks per day
grep -h 'Verdict: FAIL' logs/pipeline/*.md | wc -l              # verifier rejections
grep -h '^- Findings:' logs/pipeline/*.md                       # bug-hunt yield
grep -h 'confirmed' logs/pipeline/*.md                          # confirmed vs unconfirmed
grep -h '^- SUCCESS\|^- FAILED\|^- ESCALATED' logs/pipeline/*.md | sort | uniq -c
grep -h '^\*\*Agent:\*\*' logs/errors/*.md | sort | uniq -c     # failures by agent
```

`/pipeline-stats [--week|--month|--all]` reports: tasks run, first-round pass rate, average rounds, escalations, bug-hunt findings confirmed per task, the classes that keep coming back, persona blocks, and the skills used most. Report bad numbers plainly and flag anomalies (for example "verifier rejects over half the tasks this week: review the plans").
