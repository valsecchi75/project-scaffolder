---
name: phase-flow
description: Use when working in a project that has a .scaffolder/phase file, when a numbered phase command (/1-brainstorm to /5-release) runs, or when the user asks which phase the project is in or what comes next.
---

# Phase Flow — the contract every phase follows

A project managed by this plugin moves through five phases, strictly in order. Each phase does one kind of work and ends with one approved artifact. The next phase starts only from that artifact.

```
1 BRAINSTORM ──► 2 FOUNDATION ──► 3 DESIGN ──► 4 BUILD ──► 5 RELEASE
 questions only   second brain     design       platform     whole-project
                  + agent setup    system +     + milestones debug, gate,
                  + secrets/       artboards    + tasks      version
                                   (skipped when there is no user interface)
                                                    ▲            │
                                                    └────────────┘  next milestone
```

| Phase | Command | Only kind of work allowed | Exit artifact (the gate) | Main skill |
|---|---|---|---|---|
| 1 | `/1-brainstorm` | Asking questions, one at a time | `docs/brief/BRIEF.md` with `status: approved` | `brainstorm` |
| 2 | `/2-foundation` | Knowledge base, project skills, agent roster, secrets setup | Structure check green and user confirmation | `foundation` |
| 3 | `/3-design` | Design system, artboards, critique | Every section in scope `approved` in `wiki/design/registry.md` | `design-studio` |
| 4 | `/4-build` | Platform decision, milestone plans, tasks | Milestones in the release scope closed with evidence | `cortex` |
| 5 | `/5-release` | Whole-project debug, gate, versioning | Release report approved, tag created | `release` |

## The state file

`.scaffolder/phase` holds one word: `brainstorm`, `foundation`, `design`, `build` or `release`. It names the phase being worked on now.

- A phase command checks the previous phase's exit artifact, then writes its own phase word. Nothing else changes this file.
- The `phase-guard` hook reads it and refuses writes that belong to a later phase. A refusal is the system working: do not work around it with shell redirection, a different tool or a renamed path. Finish the phase or ask the user to move on.
- No file means the project is not managed by this flow; the hooks stay silent.

## Hard gate

<HARD-GATE>
Do not do the work of a later phase while an earlier phase is open. In phases 1 to 3 that means: no application code, no project scaffolding with framework generators, no dependency installs, no choice of platform or stack presented as settled. Reading files and asking questions are always allowed.

A gate opens only on the user's explicit approval of the exit artifact. Silence, "looks fine so far", or an approval of something else do not open it. Interaction modes (Normal, Autopilot, Autonomous) never skip a gate in phases 1 to 3.
</HARD-GATE>

Moving backwards is allowed and expected: a design gap found during build is resolved with `/3-design --section <name>` without leaving the build phase; a wrong assumption in the brief is fixed by editing the brief, recording a decision and telling the user what it changes.

## Model routing (binding)

| Work | Model | Agent |
|---|---|---|
| Planning: brainstorm, brief, foundation, design direction, platform decision, plans | Fable | the orchestrating session, `architect` |
| Verification: plan conformance, bug hunting, design critique, release debug | Fable | `verifier`, `bug-hunter`, `design-critic` |
| Production: code, tests, design files | Opus | `builder`, `designer` |
| Redundant checks and mass testing: full suites, second opinions, sweeps, persona walk-throughs | Sonnet | `sweeper`, `persona-tester` |
| Haiku | not used | — |

- Dispatch the plugin's agents (`project-scaffolder:<name>`) instead of generic subagents. Their model is set in their definition: never pass a `model` override when dispatching them.
- When you must dispatch a generic subagent, pass the model explicitly according to the table. An omitted model inherits the session's model, which is how routing silently breaks.
- Phase commands set the orchestrating session to Fable for their turn.
- When Fable is unavailable (usage limit), say so plainly, name what was run on another model, and record it in the pipeline log as `[MODEL-FALLBACK]`. Verification and release debug done on a fallback model are repeated on Fable when it is available again; never present them as equivalent.

## Shared rules

- **Language.** All project documents use the language of the brief. Code identifiers stay in English.
- **Tags.** `[FACT]` (stated in a source you can cite), `[DECISION]` (chosen, with alternatives in `wiki/product/decisions.md`), `[HYPOTHESIS]` (inferred, to confirm), `[DEPRECATED]`.
- **Append-only history.** `wiki/log.md` and `wiki/product/decisions.md` are never rewritten. Superseded content is marked `~~like this~~` with a pointer to what replaced it.
- **Secrets.** `secrets/` may be read to use a key locally. Its values never appear in chat, wiki, docs, logs, code, commits or Artifacts. Refer to keys by variable name.
- **One report.** A command ends with a short report in chat (outcome, evidence, next command). Detail lives in the files.
- **Superpowers and similar plugins.** In a phase-managed project the phase commands replace generic brainstorming, planning and execution skills for the same work. Discipline skills that do not compete with a phase (for example test-driven development or verification-before-completion) still apply.

## Canonical paths

```
.scaffolder/phase                 current phase
docs/brief/BRIEF.md               approved brief (phase 1)
raw/                              immutable sources: original brief, references, research
CLAUDE.md                         project hub and wiki schema
wiki/                             the second brain (see the wiki-keeper skill)
wiki/agents.md                    agent roster and model routing for this project
wiki/skills-map.md                connections between project skills
wiki/design/registry.md           design system and sections with their Artifact links
.claude/skills/<prefix>-<name>/   project skills (native location: they auto-load)
secrets/                          local hand-over files with keys, git-ignored
.env.example                      variable names only, never values
design/system/, design/<section>/ design files
docs/plans/MILESTONE-<n>.md       milestone plan
docs/plans/tasks/<task-id>.md     task plans
docs/release/v<version>.md        release reports
guardrails/errors-to-avoid.md     lessons that must not repeat
logs/pipeline/, logs/errors/      audit trail (pipeline-logger skill)
daily-log/                        one file per working day
```

## Status report (`/phase-status`)

Read `.scaffolder/phase`, the exit artifact of the current phase and the previous one, and answer in at most eight lines: the phase, what is approved, what is open, what blocks the gate, and the single next command.
