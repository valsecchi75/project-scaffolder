---
name: pipeline-logger
description: Use to log every operation in the synaptic pipeline. Called by Cortex, Synapse, Persona-Lab, and QA Agent at each step. Maintains daily pipeline logs and a separate error log for fast debugging. Do NOT use directly — other skills call this automatically.
---

# Pipeline Logger — The Black Box Recorder

## Overview

Pipeline Logger records every operation that flows through the synaptic pipeline. Like an aircraft's black box, it creates a complete audit trail of what happened, when, why, and what went wrong. Every task, every QA check, every persona test, every synapse propagation — logged with timestamps and outcomes.

**Core principle:** If it happened in the pipeline, it's in the log. If it broke, it's in the error log.

## Log Structure

The scaffolder initializes this structure during Phase 0:

```
logs/
├── pipeline/
│   └── YYYY-MM-DD.md       # Daily pipeline log — all operations
└── errors/
    └── YYYY-MM-DD-errors.md # Daily error log — failures only
```

## Log Format: Pipeline

Each `/task` execution produces a full log block in `logs/pipeline/YYYY-MM-DD.md`:

```markdown
---

## [HH:MM] Task: "{task_description}"

**ID:** TASK-YYYY-MM-DD-NNN
**Priority:** normal | high
**Flags:** --skip-persona, --skill X (if any)

### 1. CORTEX — Classification
- **Domain:** [domain]
- **Complexity:** trivial | medium | complex
- **Skill matched:** [skill-name] (existing | generated on-demand)
- **Connected skills:** [list from synapse map]
- **UX impact:** yes | no
- **Decision:** [routing decision from matrix]

### 2. SPECIALIST — Execution
- **Skill used:** [skill-name] (maturity: [level])
- **Files changed:** [list]
- **Lines added/removed:** +N / -N
- **Tests run:** [command] → PASS | FAIL
- **Duration:** ~N min
- **Status:** completed | failed | escalated

### 3. QA AGENT — Verification
- **Iteration:** N of max 3
- **SCOPE:** ✅ PASS | ❌ FAIL — [details]
- **SIMPLICITY:** ✅ PASS | ❌ FAIL — [details]
- **SURGICAL:** ✅ PASS | ❌ FAIL — [details]
- **DEAD CODE:** ✅ PASS | ❌ FAIL — [details]
- **SUCCESS CRITERIA:** ✅ PASS | ❌ FAIL — [details]
- **Skill checks:** ✅ PASS | ❌ FAIL — [details]
- **Verdict:** PASS | FAIL
- **Feedback to specialist:** [if FAIL, what was sent back]

### 4. PERSONA-LAB — User Simulation
_(skipped if --skip-persona or no UX impact)_
- **Personas tested:** N
- **Persona 1:** [Name] ([archetype]) → ✅ PASS | ❌ BLOCKED at step N | ⚠️ friction
- **Persona 2:** [Name] ([archetype]) → ✅ PASS | ❌ BLOCKED at step N | ⚠️ friction
- **Persona 3:** [Name] ([archetype]) → ✅ PASS | ❌ BLOCKED at step N | ⚠️ friction
- **Verdict:** PASS | FAIL
- **Recurring pattern:** [if any]

### 5. SYNAPSE — Learning Propagation
- **Primary skill updated:** [skill-name] — maturity: [old] → [new]
- **New patterns added:** N
- **New anti-patterns added:** N
- **Propagated to:** [list of skills + what was propagated]
- **Guardrail created:** ERR-NNN (if applicable)
- **Synapse map changes:** [connections added/updated]

### 6. OUTCOME
- **Result:** ✅ SUCCESS | ❌ FAILED
- **Total iterations:** N
- **Total duration:** ~N min
- **Skills created:** [if on-demand generation happened]
- **Skills updated:** [list]
- **Errors encountered:** N (see error log)
```

## Log Format: Errors

Each error gets an entry in `logs/errors/YYYY-MM-DD-errors.md`:

```markdown
---

## [HH:MM] ERR in {step} — Task "{task_description}"

**Task ID:** TASK-YYYY-MM-DD-NNN
**Step:** CORTEX | SPECIALIST | QA | PERSONA-LAB | SYNAPSE
**Iteration:** N of max 3

### What happened
[Description of the error]

### Stack trace / output
```
[Actual error output, test failure, or rejection reason]
```

### Resolution
- **Fixed:** yes | no | escalated to user
- **How:** [What was changed to fix it]
- **Guardrail created:** ERR-NNN in errors-to-avoid.md (if applicable)
- **Skill updated:** [skill-name] (if anti-pattern added)
- **Propagated:** [yes/no — if Synapse spread the lesson]

### Impact
- **Iterations added:** N
- **Files re-changed:** [list]
```

## Logging Rules

### When to log

| Event | Where to log | Required |
|-------|-------------|----------|
| /task starts | pipeline/ | Always |
| Cortex classifies | pipeline/ | Always |
| Specialist completes | pipeline/ | Always |
| Specialist fails | pipeline/ + errors/ | Always |
| QA passes | pipeline/ | Always |
| QA rejects | pipeline/ + errors/ | Always |
| Persona passes | pipeline/ | If run |
| Persona rejects | pipeline/ + errors/ | If run |
| Synapse propagates | pipeline/ | Always |
| Synapse validation fails | pipeline/ + errors/ | Always |
| Task completes | pipeline/ | Always |
| Task fails (max iterations) | pipeline/ + errors/ | Always |
| On-demand skill generated | pipeline/ | Always |

### File management

- **One file per day.** Append to existing file if same day.
- **Task ID format:** `TASK-YYYY-MM-DD-NNN` where NNN is auto-incremented per day (001, 002...).
- **Timestamps:** Use `[HH:MM]` format at the start of each block.
- **Error cross-reference:** Pipeline log links to error log entries. Error log links back to task ID.
- **Never delete logs.** Logs are append-only. Old logs stay for historical analysis.

### What NOT to log

- File contents (too verbose — just log filenames and line counts)
- Full skill content (just log skill name and maturity)
- User conversations (privacy — only log task descriptions)
- Secrets, tokens, or credentials (obviously)

## How Other Skills Call the Logger

Each skill in the pipeline is responsible for logging its own step. The logger provides the format — skills write directly to the log files.

**Cortex** logs: classification, routing decision, skill selection, loop iterations, final outcome.
**QA Agent** logs: each check result, verdict, feedback sent.
**Persona-Lab** logs: each persona result, frictions, verdict.
**Synapse** logs: skill updates, propagations, guardrail creation, map changes.

### Log initialization

At the start of each `/task`, Cortex creates the day's log files if they don't exist:

```bash
mkdir -p logs/pipeline logs/errors
touch "logs/pipeline/$(date +%Y-%m-%d).md"
touch "logs/errors/$(date +%Y-%m-%d)-errors.md"
```

## Analytics Queries

The structured log format enables quick analysis:

```bash
# How many tasks today?
grep -c "^## \[" logs/pipeline/2026-04-16.md

# How many errors today?
grep -c "^## \[" logs/errors/2026-04-16-errors.md

# Which skills used most?
grep "Skill used:" logs/pipeline/*.md | sort | uniq -c | sort -rn

# QA rejection rate
grep "Verdict: FAIL" logs/pipeline/*.md | wc -l

# Average iterations per task
grep "Total iterations:" logs/pipeline/*.md

# Which step produces most errors?
grep "Step:" logs/errors/*.md | sort | uniq -c | sort -rn

# Skills with most on-demand generation
grep "generated on-demand" logs/pipeline/*.md | wc -l
```

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Skip logging when task is trivial | Log everything — trivial tasks still generate useful patterns |
| Log full file diffs | Log filenames + line counts only |
| Delete old logs to save space | Archive to `logs/archive/` if needed, never delete |
| Log user messages verbatim | Log task descriptions only (privacy) |
| Forget to log errors separately | Always dual-log: pipeline/ AND errors/ |
