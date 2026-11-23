---
name: cortex
description: Use when /4-build, /task, /milestone-plan or /milestone-close runs, or when the user asks for implementation work (implement, add, fix, build, refactor) in a phase-managed project that is in the build or release phase.
---

# Cortex — phase 4: build

The orchestrating session (Fable) decides and checks; specialists produce, dispatched as the phase-flow skill says (load it first if this session has not). Three levels, always in this order:

```
platform decision (once) ──► milestone plan (per milestone) ──► tasks (per activity, via /task)
```

`/4-build`, `/milestone-plan` and `/milestone-close` are user-only: Claude names them as the next step and never starts them. `/task` stays invocable, because the release rounds run `/task --release-fix` in the session.

Effort is set per role in each agent file (architect, verifier, bug-hunter, design-critic `high`; the others `medium`). Pass the Agent `effort` parameter only for the builder (step 3). `/tasks` shows each agent's model and effort; `CLAUDE_CODE_EFFORT_LEVEL`, when the user sets it, overrides both.

## Gate in

- `.scaffolder/phase` is `design` with `phase | Design complete` logged, or `foundation` closed and the brief says `has_interface: no`, or already `build`. Write `build`. (The command gate refuses a typed `/4-build` that fails this.)
- During `release`, the cortex runs only fixes for confirmed release findings (`/task --release-fix`). The phase stays `release`.
- Earlier phases still open → stop and name the command that closes them.

## `/4-build`

1. `wiki/tech-stack.md` says the platform is pending, or `.claude/skills/verify/SKILL.md` is missing: read `platform.md` (in this skill's folder) and follow it.
2. The current milestone has no plan: run Level 2.
3. Otherwise report its status and the next activity to run with `/task` (`/task --parallel <#,#>` when two or more ready activities are `Parallel = yes`). `--status` reports only.

## Level 2 — Milestone plan (`/milestone-plan`)

1. Dispatch `project-scaffolder:architect` for the plan in the format of `templates/milestone-plan.md` (in this skill's folder), pointing it to the roadmap entry, the priorities, the tech stack, the approved sections, and the open P1 and P2 lines of the `/todo` report as candidate activities. Items taken become `[>]` with `-> M<n> a<k>`.
2. Every activity names its agent (normally `builder`), a `VERIFY` criterion that can fail, a `Parallel` flag (`yes` only with no dependency on another activity and no git-ignored input), a size (Trivial, Medium, Complex), the design section it implements if any, and a token estimate.
3. Show the plan and ask for approval (Autonomous mode: proceed and log `[DECISION-AUTO]`). Write `docs/plans/MILESTONE-<n>.md`, update `wiki/priorities.md`, log `## [date] milestone | M<n> planned`.

## Level 3 — A task (`/task <description>`)

One activity per task. `/task --parallel <#,#>` builds two or three `Parallel = yes` activities at once, each builder in its own git worktree: read `parallel.md` (in this skill's folder); everything except the build stays one activity at a time.

**0. Gates.** (1) The current milestone has an approved plan; missing → "Milestone M<n> has no plan: run `/milestone-plan` first." `--unplanned` proceeds and logs the skipped gate (`- gate | - | - | SKIPPED | …`, pipeline-logger format). (2) Match the task to a plan activity; no match → ask whether to add it to the plan or run it as logged unplanned work. (3) Interface work: its section is `approved` in `wiki/design/registry.md`, else stop: "Section <name> has no approved design: run `/3-design --section <name>`."

**1. Classify.** Trivial: one file, under about 10 lines, no visible behaviour change → inline plan, builder, verifier; no bug hunt, no personas. Medium: several files or one visible behaviour → full path. Complex: architectural, several subsystems, migrations → execution options first, then the full path. Note the project skills that apply (`.claude/skills/`, `wiki/skills-map.md`) and whether the interface or user-facing text changes.

Execution options for Complex tasks, asked before delegating (a cost decision: Normal and Autopilot ask; Autonomous picks standard or decomposition and logs `[DECISION-AUTO]`): **Standard path** (~60–150k tokens, one subsystem, clear plan) · **Decomposition** (two to four sequential tasks, independent parts) · **Multi-agent workflow** (~200–600k, wide refactors, migrations, audits; only when the user types `use a workflow`). No task starts a workflow otherwise; the plugin's own loops (`/5-release` rounds, `/improve`, `/research`) are the only other way in, their cost answer being the opt-in.

**2. Plan.** Dispatch `project-scaffolder:architect` for `docs/plans/tasks/<task-id>.md` (`TASK-YYYY-MM-DD-NNN`) with the task, the activity row and its `VERIFY`, the applicable project skills' paths, for interface work the approved section's Artifact link (Local mode: `design/<slug>/index.html`) and design folder, the relevant guardrails. Keep the brief under about 5k tokens. Open questions that change the work go to the user before building.

**3. Build.** Dispatch `project-scaffolder:builder` with the plan path; add nothing that contradicts the plan. Effort follows the size: Trivial `effort: "low"`, Medium no parameter, Complex `effort: "high"`; a correction round after a FAIL goes one level up, at most `high` (needs v2.1.292+).

**4. Verify.** Dispatch `project-scaffolder:verifier` with the plan, the builder's report, the diff range and `.claude/skills/verify/SKILL.md`. FAIL → back to the builder with the findings, verbatim.

**5. Bug hunt** (every Medium or Complex task). Dispatch `project-scaffolder:bug-hunter` in task mode on the diff, with the plan. Send every CRITICAL and HIGH finding, in one launch, to `project-scaffolder:sweeper` with the **refutation** job, passing only the finding lines (where, claim, repro). Confirmed = the sweeper ran its check and could not refute it; uncertain counts as refuted, a check that could not run leaves it unverified. Confirmed findings go back to the builder, each with a regression test, then through the verifier again. Refuted and unverified findings are logged, not acted on; MEDIUM and LOW are fixed now when cheap, otherwise go to `wiki/todo.md` (backlog skill, `debug`, `from: bug-hunt <task-id>`), as do unverified ones worth a second look.

**6. Persona test** (interface or user-facing text changed). Two or three `project-scaffolder:persona-tester` agents in parallel, each a different persona from the brief's target users (vary confidence, age, context, accessibility needs). They start without CLAUDE.md, so each brief carries the persona, the flow, the changed interface files and the artboard, and the brief's tone and audience lines. Rework only on BLOCKING, or the same friction from two personas; other frictions go to `wiki/todo.md` as `feedback`.

**7. Correction limit.** At most three rounds across steps 4 to 6. Then stop and report what each round tried and why it failed, ask "different approach, or do you want to step in?", and record it in `wiki/debugging/failed-experiments.md`. A plan the builder shows cannot work goes back to the architect with that evidence; a plan contradicting a recorded decision needs a superseding decision the user approves.

**8. Close.** (1) Pass the learning packet (errors, patterns that worked, confirmed findings, decisions) to the `synapse` skill. (2) Mark the activity done with its evidence line in the plan and `wiki/priorities.md`. (3) Commit `<task-id>: <activity>` only when the working agreements' **Git** line says commit per task; otherwise list the changes and leave the commit to the user or `/session-end --commit`. (4) Append to `daily-log/<today>.md`. (5) Report in at most ten lines: outcome, `VERIFY` evidence, rounds, findings confirmed and fixed, skills updated, next activity. (6) Context check (context-manager skill): above the threshold, hand off.

Every step is logged with the pipeline-logger skill. No skill covers the task's domain → `/skill-new <domain>` first; two skills conflict → show the conflict to the user before planning.

## Closing a milestone (`/milestone-close`)

1. Every activity is done with evidence, or moved to a later milestone with the user's agreement.
2. Dispatch `project-scaffolder:sweeper` for a mass run of the full suite, lint, type check and build from `wiki/tech-stack.md`. A failure reopens its activity.
3. Mark the milestone done in `wiki/product/roadmap.md`, archive its priorities, log `## [date] milestone | M<n> closed`.
4. Run the `/todo` report: mark the items this milestone completed `[x]`, and ask whether the open P1 items go into the next milestone.
5. Next: `/5-release` when the closed milestones cover the release scope, otherwise `/milestone-plan`.
