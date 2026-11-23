---
name: phase-flow
description: Use when working in a project that has a .scaffolder/phase file, when a numbered phase command (/1-brainstorm to /5-release) runs, or when the user asks which phase the project is in or what comes next.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/phase-status.sh" *)
---

# Phase Flow — the contract every phase follows

A project managed by this plugin moves through five phases, strictly in order. Each phase does one kind of work and ends with one approved artifact. The next phase starts only from that artifact. Phase 3 is skipped when the project has no user interface; after a release, the next milestone starts again in phase 4.

| Phase | Command | Only kind of work allowed | Exit artifact (the gate) | Main skill |
|---|---|---|---|---|
| 1 | `/1-brainstorm` | Asking questions, one topic at a time | `docs/brief/BRIEF.md` with `status: approved` | `brainstorm` |
| 2 | `/2-foundation` | Knowledge base, project skills, agent roster, secrets setup | Structure check green and user confirmation | `foundation` |
| 3 | `/3-design` | Design system, artboards, critique | Every section in scope `approved` in `wiki/design/registry.md` | `design-studio` |
| 4 | `/4-build` | Platform decision, milestone plans, tasks | Milestones in the release scope closed with evidence | `cortex` |
| 5 | `/5-release` | Whole-project debug, gate, versioning | Release report approved, tag created | `release` |

Supporting files, read only when the case applies:
- `${CLAUDE_SKILL_DIR}/capabilities.md`: the commands each phase adds and what stays blocked. Read it when the user asks what they can do now, instead of guessing.
- `${CLAUDE_SKILL_DIR}/paths.md`: where every project file lives. Read it when you need a location the current phase skill does not name.
- **Status:** `/phase-status`. Asked in conversation, run `bash "${CLAUDE_SKILL_DIR}/scripts/phase-status.sh"` (read-only: phase, exit artifacts, gate, next, what can run now) and relay its lines; never re-derive them.

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

## Model routing and dispatch (binding)

| Work | Model | Agent |
|---|---|---|
| Planning: brainstorm, brief, foundation, design direction, platform decision, plans | Fable | the orchestrating session, `architect` |
| Verification: plan conformance, bug hunting, design critique, release debug | Fable | `verifier`, `bug-hunter`, `design-critic` |
| Production: code, tests, design files | Opus | `builder`, `designer` |
| Redundant checks and mass testing: full suites, refutation of findings, sweeps, persona walk-throughs | Sonnet | `sweeper`, `persona-tester` |
| Haiku | not used | — |

**Session model.** Every phase is designed for a Fable session: the session asks, plans and verifies; code and design files come from the Opus agents. Commands never switch the model (a switch re-reads the whole history uncached, and the session model returns on the next prompt anyway). When a phase starts on another model, say it in one line (`this phase is designed for Fable: /model fable`) and continue if the user prefers.

**Dispatch.**
- Pass the plugin agent's scoped name as `subagent_type` (`project-scaffolder:architect`, `project-scaffolder:builder`, …), never a generic subagent, never a `model` override (sole exception: the usage-limit retry under "When Fable is missing"): the model sits in the agent's definition. If a generic subagent is unavoidable, pass its model from the table; an omitted model inherits the session's, which is how routing silently breaks.
- Agents start in the background. A launch means *started*, not *done*. Launch the next step only after the previous agent's completion notification, and give it that agent's report or the file it wrote. Only independent checks of the same result run side by side.
- One line to the user before each launch and one after each report, for example `step 2/4 · builder (Opus) · M2-T3 … done: 4 files, tests green`.
- Ask every agent for a short report: verdict, findings as `file:line`, open questions. Detail goes to the file named in its task; the read-only agents (verifier, bug-hunter, design-critic, sweeper, persona-tester) cannot write, so the session writes it from their report.

**Questions stay here.** Subagents and workflows cannot ask the user. Every question (brainstorm questions, approvals, choices, round counts) is asked in the main conversation before launching, with AskUserQuestion: 1–4 questions, 2–4 options each, headers of at most 12 characters (the brainstorm keeps to one topic per call). This flow explicitly relies on AskUserQuestion at every question and gate, auto mode included. An agent's open questions go to the user; never answer them by guessing.

**When Fable is missing.** A fallback chain (`fallbackModel` in the user's settings, or `--fallback-model`) switches only when a model is overloaded or unavailable, never on a usage or rate limit, and a plugin cannot set it: recommend it, never assume it. An agent report that opens with `⚠ This agent switched to <model>` ran on a fallback. A Fable agent that fails on a usage limit: ask the user (AskUserQuestion) to wait for the reset and retry, or to re-dispatch the same agent now with the Agent tool's `model: "opus"` (it overrides the agent's own model), and add a `T-NNN` line to `wiki/todo.md` (`debug`, P1) to repeat that step on Fable. In every case say it plainly, name what ran on which model, and log a `fallback` step line (pipeline-logger format). Verification, bug hunting and release debug done on another model are repeated on Fable when it is back; never present them as equivalent.

## Shared rules

- **Language.** All project documents use the language of the brief. Code identifiers stay in English.
- **Tags.** `[FACT]` (stated in a source you can cite), `[DECISION]` (chosen, with alternatives in `wiki/product/decisions.md`), `[HYPOTHESIS]` (inferred, to confirm), `[DEPRECATED]`.
- **Append-only history.** `wiki/log.md` and `wiki/product/decisions.md` are never rewritten. Superseded content is marked `~~like this~~` with a pointer to what replaced it.
- **Secrets.** `secrets/` may be read to use a key locally. Its values never appear in chat, wiki, docs, logs, code, commits or Artifacts. Refer to keys by variable name.
- **One report.** A command ends with a short report in chat (outcome, evidence, next command). Detail lives in the files.
- **Superpowers and similar plugins.** In a phase-managed project the phase commands replace generic brainstorming, planning and execution skills for the same work. Discipline skills that do not compete with a phase (for example test-driven development or verification-before-completion) still apply.
