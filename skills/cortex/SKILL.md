---
name: cortex
description: Use when /4-build, /task, /milestone-plan or /milestone-close runs, or when the user asks for implementation work (implement, add, fix, build, refactor) in a phase-managed project that is in the build or release phase.
---

# Cortex — phase 4: build

The orchestrating session (Fable) decides and checks; specialists produce. Build has three levels, always in this order:

```
platform decision (once) ──► milestone plan (per milestone) ──► tasks (per activity, via /task)
```

`/4-build`, `/milestone-plan` and `/milestone-close` are user-only (`disable-model-invocation`): the command gate sees only typed commands, so Claude names them as the next step and never starts them. `/task` stays invocable, because the release rounds run `/task --release-fix` in the session.

## Dispatching agents (every step below)

Build is designed for a Fable session; the build commands set no `model`. On another model, say so in one line and suggest `/model fable`; the agents keep their own models either way.

- `subagent_type` is the scoped name `project-scaffolder:<agent>`. Never pass `model`, except the Opus retry the user chooses after a Fable usage limit (phase-flow, "When Fable is missing"). The brief points to files instead of pasting them.
- Effort is set per role in each agent file (architect, verifier, bug-hunter, design-critic `high`; builder, designer, sweeper, persona-tester `medium`), because the session's own level does not carry over to an agent on another model. Pass the Agent `effort` parameter only for the builder, as step 3 says. `/tasks` shows each agent's model and effort; `CLAUDE_CODE_EFFORT_LEVEL`, when the user sets it, overrides both.
- In an interactive session an agent starts in the background: the launch means **started**, not done. Tell the user in one line what started and what follows (`Started architect: plan TASK-…; the builder follows its report`), then end the turn. Never act on a plan, diff or verdict that has not arrived.
- Chain on the completion notification: the next step starts only after the previous agent's report arrives, and works from that report and the files it wrote.
- Launch together only independent work, such as the persona testers of step 6 or the builds of `parallel.md`. Several findings go to one sweeper launch.
- Agents cannot ask the user. Open questions in a report are asked here, in the main conversation, with AskUserQuestion (1–4 questions, 2–4 options) before the next launch; every gate and question in this skill relies on it.
- An agent that ends failed (API error, usage limit) is a failed step: show its last output and offer a retry; the chain does not continue. A Fable usage limit and a report on a fallback model are handled as phase-flow says ("When Fable is missing").

## Gate in

- `.scaffolder/phase` is `design` with the design phase closed (its `phase | Design complete` log line exists), or `foundation` closed and the brief says `has_interface: no`, or already `build`. Write `build`.
- During `release`, the cortex runs only fixes for confirmed release findings (`/task --release-fix`). The phase stays `release`.
- Earlier phases still open → stop and name the command that closes them.

## Level 1 — Platform decision (`/4-build`, first run)

When `wiki/tech-stack.md` still says the platform is pending:

1. Dispatch `project-scaffolder:architect` for a platform decision, pointing it to the brief's constraints, `wiki/architecture.md`, the design registry, the working agreements' reference projects, and the phase-4 lines of `raw/parking-lot.md` (solutions the user volunteered in phase 1: each is weighed against the constraints and named adopted or rejected in the decision, never adopted silently).
2. Present its two or three options with the recommendation and ask the user to choose. This is a gate in every interaction mode: it is irreversible and has cost.
3. Record the choice as a `DEC-NNN`, fill `wiki/tech-stack.md` (language, framework, hosting, data store, and the exact build, test, lint, type-check and audit commands), replace the placeholder of the `## Commands` section in the project's `CLAUDE.md` with the same commands (install, run, full suite, one test file, type check, lint), and update `wiki/architecture.md` with the layers.
4. Write `.claude/skills/verify/SKILL.md` from `templates/verify-skill.md` (in this skill's folder) with those commands. A later `/4-build` that finds the platform decided but this file missing (projects set up before it existed) writes it the same way, before anything else. The folder is `verify`, without the project prefix: from Claude Code v2.1.286, a project skill with that name makes Claude run it before each commit, and it replaces the bundled `/verify` in this repository. Never give it `disable-model-invocation` (the commit instruction then stops). It counts from the next session, and it is guidance, not a block: the verifier still runs it on every task. When the commands in `wiki/tech-stack.md` change, update it and the `CLAUDE.md` Commands section in the same edit.
5. Generate the stack skills with `/skill-new` (framework patterns, deployment) and add them, with `verify`, to `wiki/skills-map.md`.
6. Set up the project skeleton as the first activity of the first milestone, not here.

## Level 2 — Milestone plan (`/milestone-plan`)

`/4-build` runs this level itself, without calling `/milestone-plan`, when the current milestone has no plan.

1. Dispatch `project-scaffolder:architect` for the milestone plan in the format of `templates/milestone-plan.md` (in this skill's folder), pointing it to the roadmap entry, the priorities, the tech stack and the approved sections, plus the open P1 and P2 lines of the notebook (`/todo` report, backlog skill) as candidate activities. Items taken become `[>]` with `-> M<n> a<k>`.
2. Every activity names its agent (normally `builder`), a `VERIFY` criterion that can fail, a `Parallel` flag (`yes` only with no dependency on another activity and no git-ignored input), a size (Trivial, Medium, Complex), the design section it implements if any, and a token estimate.
3. Show the plan and ask for approval (in Autonomous mode: proceed and log `[DECISION-AUTO]`). Write `docs/plans/MILESTONE-<n>.md`, update `wiki/priorities.md`, log `## [date] milestone | M<n> planned`.

## Level 3 — A task (`/task <description>`)

One activity per task. `/task --parallel <#,#>` builds two or three `Parallel = yes` activities at once, each builder in its own git worktree: read `parallel.md` (in this skill's folder) and follow it; everything except the build stays one activity at a time.

### 0. Gates

1. The current milestone has an approved plan. Missing → refuse: "Milestone M<n> has no plan: run `/milestone-plan` first." The flag `--unplanned` proceeds anyway and logs the skipped gate (`- gate | - | - | SKIPPED | …` in the task block, pipeline-logger format).
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

A task never starts a multi-agent workflow without the user typing `use a workflow`. The plugin's own loops (`/5-release` rounds, `/improve`, `/research`) are the only other way in: there the user's answer to their cost question is the opt-in.

### 2. Plan

Dispatch `project-scaffolder:architect` for a task plan at `docs/plans/tasks/<task-id>.md` (task id `TASK-YYYY-MM-DD-NNN`). Its brief: the task, the activity row with its `VERIFY`, the paths of the applicable project skills, for interface work the approved section's Artifact link (in Local mode its page `design/<slug>/index.html`) and design folder, the relevant guardrails. Keep the injected brief under about 5k tokens: point to files, do not paste them.

When the plan returns open questions that change the work, ask the user before building.

### 3. Build

After the architect's report has arrived and its questions are answered, dispatch `project-scaffolder:builder` with the plan path. Do not add instructions that contradict the plan.

Effort follows the size: Trivial `effort: "low"`, Medium no parameter (the agent's `medium`), Complex `effort: "high"`. A correction round after a FAIL goes one level up, at most `high`. The parameter needs Claude Code v2.1.292 or later; older versions run the agent's `medium`.

### 4. Verify

After the builder's report has arrived, dispatch `project-scaffolder:verifier` with the plan, the builder's report, the diff range and the path `.claude/skills/verify/SKILL.md`. FAIL → back to the builder with the findings, verbatim.

### 5. Bug hunt (end of every Medium or Complex task)

1. Dispatch `project-scaffolder:bug-hunter` in task mode on the diff, with the plan.
2. Send every CRITICAL and HIGH finding, in one launch, to `project-scaffolder:sweeper` with the **refutation** job, passing only the finding lines (where, claim, repro): it re-derives each one with its own commands, as in `/bug-hunt` and the release rounds.
3. A finding is **confirmed** when the sweeper ran its check and could not refute it. Uncertain counts as refuted; a check that could not run leaves it unverified, never confirmed. Confirmed findings go back to the builder, each with a regression test to add, and then through the verifier again.
4. Refuted and unverified findings are logged in the pipeline log and not acted on. MEDIUM and LOW findings are fixed in the same round when cheap, otherwise added to the notebook `wiki/todo.md` (backlog skill, `debug`, `from: bug-hunt <task-id>`), as are unverified findings worth a second look.

### 6. Persona test (when the interface or user-facing text changed)

Dispatch two or three `project-scaffolder:persona-tester` agents in parallel, each with a different persona built from the brief's target users (vary technical confidence, age, context, accessibility needs). The agent starts without CLAUDE.md, so each brief carries everything it may know: the persona, the flow to attempt, the paths of the changed interface files and the artboard, and the tone and audience lines quoted from the brief. Rework only on a BLOCKING result, or on the same friction reported by two personas; other frictions go to `wiki/todo.md` as `feedback`.

### 7. Correction limit

At most three rounds across steps 4 to 6. After the third failure, stop and report to the user: what was tried each round, what failed and why, and the question "different approach, or do you want to step in?". Record it in `wiki/debugging/failed-experiments.md`.

### 8. Close

1. Synapse: pass the learning packet (errors met, patterns that worked, findings confirmed, decisions) to the `synapse` skill.
2. Mark the activity done in the milestone plan with the evidence line, and in `wiki/priorities.md`.
3. Git: commit (`<task-id>: <activity>`) only when the working agreements' **Git** line says commit per task. Otherwise leave the changes uncommitted, list them in the report, and leave the commit to the user or `/session-end --commit`.
4. Append to `daily-log/<today>.md`.
5. Report in at most ten lines: outcome, `VERIFY` evidence, rounds, findings confirmed and fixed, skills updated (and any synapse lists as due for a refactor), next activity.
6. Context check (context-manager skill): above the threshold, hand off instead of starting the next task.

Every step is logged with the pipeline-logger skill.

## Closing a milestone (`/milestone-close`)

1. Every activity of the plan is done with evidence, or explicitly moved to a later milestone with the user's agreement.
2. Dispatch `project-scaffolder:sweeper` for a mass run of the full suite, lint, type check and build from `wiki/tech-stack.md`. Any failure reopens the activity it belongs to.
3. Mark the milestone done in `wiki/product/roadmap.md`, archive its priorities, log `## [date] milestone | M<n> closed`.
4. Run the `/todo` report (backlog skill): mark the notebook items this milestone completed `[x]`, and ask whether the open P1 items go into the next milestone.
5. Next: when the closed milestones cover the release scope, suggest `/5-release`; otherwise `/milestone-plan` for the next one.

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
