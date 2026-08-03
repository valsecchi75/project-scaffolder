---
name: task
description: Assign a task to the Cortex for orchestrated execution with QA, user testing, and skill learning. The full development pipeline.
---

# /task

Assign a task to the Cortex — the project's AI project leader. Cortex classifies the work, finds or generates the right skills, delegates to a specialist, runs QA and user testing, and propagates learning back to the skill network.

## Usage

```
/task <description>
/task --priority <low|medium|high> <description>
/task --skip-persona <description>
/task --skill <skill-name> <description>
```

## Flags

| Flag | Effect |
|------|--------|
| `--priority high` | Reduces max iterations to 2. QA focuses on correctness only (skips Karpathy compliance for speed). |
| `--skip-persona` | Skip Persona-Lab user simulation (for backend/infra tasks with no UX impact). |
| `--skill <name>` | Force a specific skill instead of letting Cortex auto-classify. |
| `--no-phase-doc` | Skip the Execution Doc gate (conscious choice, logged as [GATE-SKIPPED]) |
| `--design` / `--no-design` | Force or skip the design gate (design-first skill). The gate is mandatory anyway on the first task of a phase and on Complex tasks. |
| (none) | Cortex auto-classifies and decides the full pipeline. |

## Examples

```
/task Implement Android home screen widget showing total monthly spend
/task --priority high Fix the renewal date calculation bug for annual subscriptions
/task --skip-persona Refactor database schema to add notes column
/task --skill qs-flutter-patterns Add pull-to-refresh on the subscription list
```

## What happens

0. **Step 0 gate** — Cortex verifies that `docs/phases/PHASE-{N}-execution.md` exists for the current phase. Missing and no `--no-phase-doc` → the task is refused; run `/phase-doc` first.
1. **Cortex classifies** — determines domain, complexity, required skills
2. **Skill lookup/generation** — finds existing skill or generates one on-demand
3. **Design gate** — first task of a phase and Complex tasks go through a design dialogue (design-first skill): questions one at a time, 2-3 approaches, your approval. The approved design may revise scaffold rules (`[DESIGN-REVISION]`)
4. **Specialist executes** — subagent implements with the approved design + skill as context
5. **QA verifies** — ephemeral subagent checks correctness + Karpathy compliance
6. **Persona-Lab tests** — simulates 3 end-user profiles (unless skipped)
7. **Synapse propagates** — updates skills with lessons learned, propagates to connected skills
8. **Closes loop** — updates priorities, daily log, reports to user

Max 3 iterations through the QA/Persona feedback loop. After 3 failures, Cortex stops and asks for human guidance.

## Prerequisites

- Project must have been scaffolded (CLAUDE.md, wiki/, skills/ must exist)
- The cortex, synapse, and persona-lab skills must be installed (included in this plugin)
