---
name: cortex
description: Use when a task needs to be executed through the full development pipeline — classification, delegation, QA, user testing, and learning propagation. Triggers on /task command or when a user describes implementation work in an already-scaffolded project. Do NOT use for questions, wiki updates, or simple file edits.
---

# Cortex — The Project Leader

## Overview

Cortex is the orchestration layer that turns a task into a verified, tested, and learned-from delivery. It classifies work, finds or generates the right skills, delegates to specialist subagents, runs quality gates, and feeds results back to the skill network via Synapse.

**Core principle:** Every task goes through classify → execute → verify → learn. No shortcuts except for explicitly trivial work.

## Activation

### Explicit activation
The `/task` command always triggers the full Cortex pipeline.

### Implicit activation
When a user describes work during a development session (post-scaffolding), Cortex evaluates:

**Activate when** the message contains an imperative verb targeting a code artifact:
- "implement", "add", "fix", "create", "refactor", "build", "remove", "update", "migrate"

**Do NOT activate for:**
- Questions: "how does X work?", "what is Y?", "explain Z"
- Wiki/doc requests: "update the handoff", "document this decision"
- Simple file reads or exploration

**When uncertain:** Ask "Should I run this through the full task pipeline, or handle it directly?"

**v2.0 default:** Implicit activation always asks for confirmation. Only `/task` activates without confirmation.

## The Pipeline

### Step 1: Classify the task

Analyze the request and determine:

| Attribute | How to determine |
|-----------|-----------------|
| Domain | Keywords in task description + which wiki pages are relevant |
| Complexity | Trivial (<10 lines, 1 file) / Medium (multi-file) / Complex (architectural) |
| Required skills | Match domain keywords against `skills/` directory names and `skills/_synapse-map.md` connections |
| UX impact | Does the task touch UI, user-facing text, or user flows? |

### Step 2: Skill lookup

1. Scan `skills/` directory for skills matching the task domain
2. Read `skills/_synapse-map.md` to find connected skills
3. If a matching skill exists → use it (proceed to Step 4)
4. If no matching skill → proceed to Step 3

### Step 3: On-demand skill generation

When no existing skill covers the task domain, generate one using this template:

```markdown
---
name: [project-prefix]-[domain]
description: Use when working on [domain] in this project. Triggers: [specific trigger words].
maturity: seed
tasks_completed: 0
last_synapse_update: [today's date]
connections: []
---

# [Domain Title]

## Overview
[Generated from task context + wiki/architecture.md]

**Core principle:** [One sentence — most important rule for this domain]

## Code Patterns
[2-3 starter patterns from tech stack + domain]

## Anti-Patterns
| Don't | Do instead |
|-------|-----------|
| [Inferred from Karpathy principles] | |

## Behavioral Rules
> Apply these rules every time you write or modify code in this domain.

1. **State assumptions before coding.** If the task is ambiguous, list assumptions and ask if uncertain.
2. **Minimum viable implementation.** Simplest pattern that solves the problem.
3. **Surgical scope.** Stay within the boundary of the current task.
4. **Verify against this skill's checklist** before declaring complete.

## Verification Checklist
- [ ] Code compiles without errors
- [ ] Tests pass for new functionality
- [ ] No dead code introduced
- [ ] [Domain-specific check]

## Common Mistakes
| Mistake | Fix |
|---------|-----|
| (populated after first use by Synapse) | |
```

**How to fill the template:**
1. Read `wiki/tech-stack.md` — extract language, framework, conventions
2. Read `wiki/architecture.md` — extract layer structure, folder organization
3. Read the task description — extract domain keywords
4. Read `skills/_synapse-map.md` — identify potential connections
5. Generate content: code patterns from tech stack + domain, anti-patterns from Karpathy
6. Save to `skills/[prefix]-[domain]/SKILL.md`
7. Trigger Synapse to add connections to the synapse map

### Step 4: Delegate to specialist subagent

Launch a subagent with bounded context:

| Context item | Max size | Required |
|-------------|----------|----------|
| Task description | ~200 tokens | Always |
| Primary skill (full) | ~1,500 tokens | Always |
| 1 related skill (full) | ~1,500 tokens | If connected in synapse map |
| Additional related skills (summary only) | ~300 tokens each, max 2 | If connected |
| wiki/priorities.md excerpt | ~200 tokens | Always |
| wiki/architecture.md excerpt | ~300 tokens | For technical tasks |
| wiki/tech-stack.md excerpt | ~200 tokens | For technical tasks |

**Skill summary format** (when a skill exceeds budget): Extract frontmatter + Overview section + Common Mistakes table only.

**Total context target:** Under 5,000 tokens of injected context.

The specialist implements the task: writes code, creates files, runs tests. Returns a report of what was done and any issues encountered.

### Step 5: QA Agent (ephemeral subagent)

Launch an ephemeral QA subagent with this prompt template:

```
You are a QA engineer reviewing code changes for the task: "{task_description}"

## Technical checks
Run these commands and report results:
{commands_from_tech_stack}

## Karpathy Compliance Checklist
For each check, answer YES/NO with evidence:

1. SCOPE: Does the code implement ONLY what was requested?
   - List any files/functions changed but not required by the task.
2. SIMPLICITY: Could this be done with significantly less code?
   - Flag any classes, abstractions, or config options nobody asked for.
3. SURGICAL: Were only necessary lines changed?
   - Flag any formatting changes, comment additions, or refactors of adjacent code.
4. DEAD CODE: Are there unused imports, functions, or variables from this change?
5. SUCCESS CRITERIA: Does the implementation satisfy: "{verify_criteria}"

## Skill-specific checks
{checklist_from_primary_skill}

## Verdict
- PASS: All checks green
- FAIL: List specific issues with actionable feedback
```

**Template variables:**

| Variable | Source |
|----------|--------|
| `{task_description}` | From `/task` command |
| `{commands_from_tech_stack}` | Parsed from `wiki/tech-stack.md` |
| `{verify_criteria}` | From `→ VERIFY:` in `wiki/priorities.md` |
| `{checklist_from_primary_skill}` | From primary skill's "Verification Checklist" section |

**Note on --priority high:** When this flag is set, skip checks 2 (SIMPLICITY) and 3 (SURGICAL) for speed. Only verify correctness and test passage.

### Step 6: Persona-Lab gate

If the task has UX impact and `--skip-persona` was not set, call the persona-lab skill (see dedicated skill). Otherwise, skip to Step 7.

### Step 7: Feedback loop

```
Specialist delivers → QA rejects?
    YES → Send specific feedback → Specialist corrects → QA re-verifies
    NO (passes) → Persona-Lab rejects? (if applicable)
        YES → Send UX feedback → Specialist corrects → Back to QA
        NO (passes) → Proceed to Step 8

Max iterations: 3 (or 2 if --priority high)
After max failures: STOP → Report to user:
    - What was attempted (each iteration)
    - What failed and why (QA + Persona-Lab feedback history)
    - Ask: "Different approach, or do you want to intervene?"
    - Document in wiki/debugging/failed-experiments.md
```

### Step 8: Close the loop

After all gates pass:
1. Call Synapse for learning propagation (pass the learning packet)
2. Update `wiki/priorities.md` — mark task complete with evidence
3. Update `daily-log/YYYY-MM-DD.md` with task report
4. Report to user: task completed, iterations needed, skills created/updated

## Decision Matrix

| Situation | Cortex Decision |
|-----------|----------------|
| Task matches 1 existing skill | Delegate directly with that skill |
| Task matches 2+ skills | Delegate with all relevant skills as context |
| Task matches no skill | Generate on-demand, then delegate |
| Task is trivial (<10 lines change) | Delegate without QA/Persona-Lab (fast path) |
| Task is purely backend/infra | Delegate with QA only, skip Persona-Lab |
| Task touches UI/UX | Full pipeline: QA + Persona-Lab |
| Task matches 2+ skills with conflicting guidance | Flag conflict to user before delegating |
| Task is architectural/complex | Ask user for confirmation before proceeding |
| Specialist fails 3 times | Stop, report to user, document failure |

## Logging

Every step in the pipeline MUST be logged using the pipeline-logger skill format.

### At pipeline start
1. Create log files if they don't exist: `mkdir -p logs/pipeline logs/errors`
2. Generate task ID: `TASK-YYYY-MM-DD-NNN` (auto-increment NNN per day)
3. Write the task header block to `logs/pipeline/YYYY-MM-DD.md`

### During execution
- **After Step 1 (Classify):** Log domain, complexity, skill matched, UX impact, decision
- **After Step 4 (Specialist):** Log files changed, lines added/removed, test results, status
- **After Step 5 (QA):** Log each check result (SCOPE, SIMPLICITY, SURGICAL, DEAD CODE, SUCCESS CRITERIA), verdict, feedback if FAIL. On FAIL → also write to `logs/errors/YYYY-MM-DD-errors.md`
- **After Step 6 (Persona-Lab):** Log each persona result, frictions, verdict. On FAIL → also write to errors log
- **After Step 7 (Feedback loop):** Log iteration count, rejection reasons
- **After Step 8 (Close):** Log synapse propagations, skills updated, final outcome, total duration

### On errors
Any failure at any step → dual log to both pipeline/ and errors/ with cross-reference.

See `skills/pipeline-logger/SKILL.md` for complete log format and templates.

## Context

This is the central orchestrator skill for the Project Scaffolder v2.0 "Synaptic Edition". It coordinates with three other skills: Synapse (learning propagation), Persona-Lab (user simulation), and the project-scaffolder itself (initial scaffolding). The Cortex is triggered by the /task command.
