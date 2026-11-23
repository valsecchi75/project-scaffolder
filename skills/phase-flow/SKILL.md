---
name: phase-flow
description: Use when working in a project that has a .scaffolder/phase file, when a numbered phase command (/1-brainstorm to /5-release) runs, or when the user asks which phase the project is in or what comes next.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/phase-status.sh" *)
---

# Phase Flow — the contract every phase follows

Five phases, strictly in order. Each does one kind of work and ends with one approved artifact, from which the next starts. Phase 3 is skipped without a user interface; after a release, the next milestone starts again in phase 4.

| Phase | Command | Only kind of work allowed | Exit artifact (the gate) | Main skill |
|---|---|---|---|---|
| 1 | `/1-brainstorm` | Asking questions, one topic at a time | `docs/brief/BRIEF.md` with `status: approved` | `brainstorm` |
| 2 | `/2-foundation` | Knowledge base, project skills, agent roster, secrets setup | Structure check green and user confirmation | `foundation` |
| 3 | `/3-design` | Design system, artboards, critique | Every section in scope `approved` in `wiki/design/registry.md` | `design-studio` |
| 4 | `/4-build` | Platform decision, milestone plans, tasks | Milestones in the release scope closed with evidence | `cortex` |
| 5 | `/5-release` | Whole-project debug, gate, versioning | Release report approved, tag created | `release` |

Read only when the case applies (all in `${CLAUDE_SKILL_DIR}/`):
- `capabilities.md`: the commands each phase adds and what stays blocked, when the user asks what they can do now.
- `paths.md`: where every project file lives, when the current phase skill does not name a location.
- `fallback.md`: when a Fable agent fails on a usage limit or a report says it switched model.
- **Status:** `/phase-status`. Asked in conversation, run `bash "${CLAUDE_SKILL_DIR}/scripts/phase-status.sh"` (read-only) and relay its lines; never re-derive them.

## The state file

`.scaffolder/phase` holds one word (`brainstorm`, `foundation`, `design`, `build`, `release`): the current phase. A phase command checks the previous exit artifact, then writes its own word; nothing else changes the file. No file: not managed by this flow, the hooks stay silent.

Hooks hold the gates: the command gate refuses a typed command that comes too early (also `/2-foundation` without an approved brief, `/4-build` before `phase | Design complete` unless `has_interface: no`); the phase guard refuses writes of a later phase. A refusal is the system working: never work around it (shell redirection, another tool, a renamed path). Finish the phase or ask the user to move on.

## Hard gate

<HARD-GATE>
Do not do the work of a later phase while an earlier phase is open. In phases 1 to 3 that means: no application code, no project scaffolding with framework generators, no dependency installs, no choice of platform or stack presented as settled. Reading files and asking questions are always allowed.

A gate opens only on the user's explicit approval of the exit artifact. Silence, "looks fine so far", or an approval of something else do not open it. Interaction modes (Normal, Autopilot, Autonomous) never skip a gate in phases 1 to 3.
</HARD-GATE>

Moving backwards is allowed: a design gap found in build goes to `/3-design --section <name>` without leaving the phase; a wrong assumption in the brief is fixed by editing it, recording a decision and telling the user what it changes.

## Model routing and dispatch (binding, for every phase skill)

| Work | Model | Agent |
|---|---|---|
| Planning: brainstorm, brief, foundation, design direction, platform decision, plans | Fable | the orchestrating session, `architect` |
| Verification: plan conformance, bug hunting, design critique, release debug | Fable | `verifier`, `bug-hunter`, `design-critic` |
| Production: code, tests, design files | Opus | `builder`, `designer` |
| Redundant checks and mass testing: suites, refutations, sweeps, persona walk-throughs | Sonnet | `sweeper`, `persona-tester` |
| Haiku | not used | — |

**Session model.** Every phase is designed for a Fable session (it asks, plans, verifies; the Opus agents produce). Commands never switch the model: a switch re-reads the history uncached. On another model, say so in one line (`/model fable`) and continue if the user prefers.

**Dispatch.**
- `subagent_type` is the scoped name (`project-scaffolder:architect`, …), never a generic subagent (it would inherit the session's model), never a `model` override (sole exception: `fallback.md`). The brief points to files instead of pasting them.
- Agents start in the background: a launch means *started*, not done. One line on what started and what follows (`step 2/4 · builder (Opus) · M2-T3`), then end the turn; never act on a report that has not arrived. The next step starts on the completion notification, from that report and the files written. Only independent work runs side by side; never two agents on one deliverable. One line after each report (`… done: 4 files, tests green`).
- Ask every agent for a short report: verdict, findings as `file:line`, open questions. Detail goes to the file named in its task; for the read-only agents the session writes it from their report.
- An agent that ends failed (API error, usage limit) is a failed step: show its last output, offer a retry; the chain stops.

**Questions stay here.** Subagents and workflows cannot ask, so a phase skill never runs in a fork. Every question (topics, approvals, choices, round counts, an agent's open questions) is asked in the main conversation with AskUserQuestion: 1–4 questions, 2–4 options, headers of at most 12 characters. Then stop and wait, in every mode, auto mode included; never continue on an assumed answer. Tool denied or question closed unanswered: ask it as plain text with numbered options and end the message there.

## Shared rules

- **Language.** All project documents use the language of the brief. Code identifiers stay in English.
- **Tags.** `[FACT]` (stated in a source you can cite), `[DECISION]` (chosen, with alternatives in `wiki/product/decisions.md`), `[HYPOTHESIS]` (inferred, to confirm), `[DEPRECATED]`.
- **Append-only history.** `wiki/log.md` and `wiki/product/decisions.md` are never rewritten. Superseded content is marked `~~like this~~` with a pointer to what replaced it.
- **Secrets.** A key is used by loading its file in the command that needs it (`set -a; . secrets/<file>.env; set +a; <command>`), never by reading it into the conversation; DEC-003 says whether reads of `secrets/` are blocked. Values never appear in chat, wiki, docs, logs, code, commits, Artifacts or the shipped build. Refer to keys by variable name.
- **One report.** A command ends with a short report in chat (outcome, evidence, next command). Detail lives in the files.
- **Other plugins.** The phase commands replace generic brainstorming, planning and execution skills; discipline skills that do not compete with a phase (test-driven development, verification-before-completion) still apply.
