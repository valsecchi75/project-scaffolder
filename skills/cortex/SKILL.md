---
name: cortex
description: Use when /4-build, /task, /milestone-plan or /milestone-close runs, or when the user asks for implementation work (implement, add, fix, build, refactor) in a phase-managed project that is in the build or release phase.
---

# Cortex — phase 4: build

The orchestrating session (Fable) decides and checks; specialists produce. Build has three levels, always in this order:

```
platform decision (once) ──► milestone plan (per milestone) ──► tasks (per activity, via /task)
```

## Gate in

- `.scaffolder/phase` is `design` with the design phase closed (its `phase | Design complete` log line exists), or `foundation` closed and the brief says `has_interface: no`, or already `build`. Write `build`.
- During `release`, the cortex runs only fixes for confirmed release findings (`/task --release-fix`). The phase stays `release`.
- Earlier phases still open → stop and name the command that closes them.

## Level 1 — Platform decision (`/4-build`, first run)

When `wiki/tech-stack.md` still says the platform is pending:

1. Dispatch `project-scaffolder:architect` for a platform decision, pointing it to the brief's constraints, `wiki/architecture.md`, the design registry, and the working agreements' reference projects.
2. Present its two or three options with the recommendation and ask the user to choose. This is a gate in every interaction mode: it is irreversible and has cost.
3. Record the choice as a `DEC-NNN`, fill `wiki/tech-stack.md` (language, framework, hosting, data store, and the exact build, test, lint, type-check and audit commands), and update `wiki/architecture.md` with the layers.
4. Generate the stack skills with `/skill-new` (framework patterns, deployment) and add them to `wiki/skills-map.md`.
5. Set up the project skeleton as the first activity of the first milestone, not here.

## Level 2 — Milestone plan (`/milestone-plan`)

`/4-build` runs it automatically when the current milestone has no plan.

1. Dispatch `project-scaffolder:architect` for the milestone plan in the format of `templates/milestone-plan.md` (in this skill's folder), pointing it to the roadmap entry, the priorities, the tech stack and the approved sections.
2. Every activity names its agent (normally `builder`), a `VERIFY` criterion that can fail, a `Parallel` flag, a size (Trivial, Medium, Complex), the design section it implements if any, and a token estimate.
3. Show the plan and ask for approval (in Autonomous mode: proceed and log `[DECISION-AUTO]`). Write `docs/plans/MILESTONE-<n>.md`, update `wiki/priorities.md`, log `## [date] milestone | M<n> planned`.

## Level 3 — A task (`/task <description>`)

### 0. Gates

1. The current milestone has an approved plan. Missing → refuse: "Milestone M<n> has no plan: run `/milestone-plan` first." The flag `--unplanned` proceeds anyway and logs `[GATE-SKIPPED]`.
2. Match the task to an activity in the plan. No match → ask whether to add it to the plan or run it as unplanned work (logged).
3. Interface work: the section it implements is `approved` in `wiki/design/registry.md`. Not approved or missing → stop: "Section <name> has no approved design: run `/3-design --section <name>`."

### 1. Classify

| Size | Definition | Path |
|---|---|---|
| Trivial | One file, under about 10 lines, no behaviour change visible to users | Short plan written inline, builder, verifier. No bug hunt, no personas. |
| Medium | Several files or one visible behaviour | Full path |
| Complex | Architectural, several subsystems, migrations | Execution options first (below), then the full path |

Also note: the project skills that apply (from `.claude/skills/` and `wiki/skills-map.md`), and whether the interface or user-facing text changes.

**Execution options for Complex tasks.** Present before delegating, with order-of-magnitude costs, and wait for the choice. This is a cost decision: asked in Normal and Autopilot; in Autonomous choose the standard path or decomposition silently and log `[DECISION-AUTO]`.

| Option | How it runs | Est. tokens | Best when |
|---|---|---|---|
| Standard path | The steps below, once | ~60–150k | One subsystem, clear plan |
| Decomposition | Two to four sequential tasks | similar, spread out | The parts are independent |
| Multi-agent workflow | The user types `use a workflow` | ~200–600k | Wide refactors, migrations, audits |

Multi-agent workflows are never started without the user typing `use a workflow`.

### 2. Plan

Dispatch `project-scaffolder:architect` for a task plan at `docs/plans/tasks/<task-id>.md` (task id `TASK-YYYY-MM-DD-NNN`). Its brief: the task, the activity row with its `VERIFY`, the paths of the applicable project skills, the approved Artifact and local design folder for interface work, the relevant guardrails. Keep the injected brief under about 5k tokens: point to files, do not paste them.

When the plan returns open questions that change the work, ask the user before building.

### 3. Build

Dispatch `project-scaffolder:builder` with the plan path. Do not add instructions that contradict the plan.

### 4. Verify

Dispatch `project-scaffolder:verifier` with the plan, the builder's report and the diff range. FAIL → back to the builder with the findings, verbatim.

### 5. Bug hunt (end of every Medium or Complex task)

1. Dispatch `project-scaffolder:bug-hunter` in task mode on the diff, with the plan.
2. For each CRITICAL or HIGH finding, dispatch `project-scaffolder:sweeper` for a second opinion: it follows the reproduction without the hunter's conclusion. Several findings can go to one sweeper dispatch.
3. A finding is **confirmed** when the sweeper reproduces it, or when the hunter's reproduction is a test that fails. Confirmed findings go back to the builder, each with a regression test to add, and then through the verifier again.
4. Findings that do not reproduce are logged as leads in the pipeline log and not acted on. MEDIUM and LOW findings are fixed in the same round when cheap, otherwise added to `wiki/priorities.md`.

### 6. Persona test (when the interface or user-facing text changed)

Dispatch two or three `project-scaffolder:persona-tester` agents in parallel, each with a different persona built from the brief's target users (vary technical confidence, age, context, accessibility needs). Rework only on a BLOCKING result, or on the same friction reported by two personas.

### 7. Correction limit

At most three rounds across steps 4 to 6. After the third failure, stop and report to the user: what was tried each round, what failed and why, and the question "different approach, or do you want to step in?". Record it in `wiki/debugging/failed-experiments.md`.

### 8. Close

1. Synapse: pass the learning packet (errors met, patterns that worked, findings confirmed, decisions) to the `synapse` skill.
2. Mark the activity done in the milestone plan with the evidence line, and in `wiki/priorities.md`.
3. Append to `daily-log/<today>.md`.
4. Report in at most ten lines: outcome, `VERIFY` evidence, rounds, findings confirmed and fixed, skills updated, next activity.
5. Context check (context-manager skill): above the threshold, hand off instead of starting the next task.

Every step is logged with the pipeline-logger skill.

## Closing a milestone (`/milestone-close`)

1. Every activity of the plan is done with evidence, or explicitly moved to a later milestone with the user's agreement.
2. Dispatch `project-scaffolder:sweeper` for a mass run of the full suite, lint, type check and build from `wiki/tech-stack.md`. Any failure reopens the activity it belongs to.
3. Mark the milestone done in `wiki/product/roadmap.md`, archive its priorities, log `## [date] milestone | M<n> closed`.
4. Next: when the closed milestones cover the release scope, suggest `/5-release`; otherwise `/milestone-plan` for the next one.

## Decision matrix

| Situation | Decision |
|---|---|
| Task matches one project skill | Plan with it |
| No skill covers the domain | `/skill-new <domain>` first, then plan |
| Two skills give conflicting guidance | Show the conflict to the user before planning |
| The plan contradicts a recorded decision | The architect proposes a superseding decision; the user approves it |
| Interface task without an approved section | Stop, `/3-design --section` |
| Builder reports the plan cannot work | Back to the architect with the builder's evidence |
| Three failed rounds | Stop, report, record the failed experiment |
