# {Project} — Project Hub

> Read at the start of every session. This file is the schema of the project's second brain: how the wiki is organised and maintained. Details live in the wiki.
> last-verified: {YYYY-MM-DD}

## What it is

{Two or three lines from the brief: who it is for, what it does, the business model.}

- **Phase:** see `.scaffolder/phase` (1 brainstorm · 2 foundation · 3 design · 4 build · 5 release). `/phase-status` explains it.
- **Current milestone:** M{n} — {name}
- **Interaction mode (phases 4–5):** {Normal|Autopilot|Autonomous} (DEC-001)
- **Context threshold:** 300k tokens

## The second brain

| Layer | Where | Rule |
|---|---|---|
| Raw sources | `raw/` | Immutable. Read, cite, never edit. New sources enter with `/wiki-ingest`. |
| Wiki | `wiki/` | Maintained by the agents. Start from `wiki/index.md`. One concept per page, cited, tagged. |
| Schema | this file | Changed only with the user. |

- Before answering a question about the project, read `wiki/index.md`, then the pages it points to, and cite them.
- A useful answer that is not in the wiki yet becomes a page (ask first).
- Contradictions are marked, not overwritten. `wiki/log.md` and `wiki/product/decisions.md` are append-only.
- Log line format: `## [YYYY-MM-DD] <op> | <title>`.

## Key pages

| Page | What |
|---|---|
| `docs/brief/BRIEF.md` | The approved brief |
| `wiki/overview.md` · `wiki/product/roadmap.md` | Product and milestones |
| `wiki/handoff.md` · `wiki/priorities.md` | Where the last session stopped, what is next |
| `wiki/architecture.md` · `wiki/tech-stack.md` | Technical foundation |
| `wiki/design/registry.md` | Design system and approved sections, with Artifact links |
| `wiki/agents.md` · `wiki/skills-map.md` | Who does what, with which model; how skills connect |
| `wiki/debugging/known-errors.md` · `guardrails/errors-to-avoid.md` | Lessons that must not repeat |

## How work flows

1. One phase at a time, through its command and its exit gate. In phases 1–3 no application code is written; the phase guard enforces it.
2. In phase 4, every piece of work goes through `/task`: plan (architect) → build (builder) → verify (verifier) → bug hunt (bug-hunter) → persona test when the interface changes. A task is done only with evidence.
3. Interface work ports the approved artboards one to one. A missing design element stops the task and opens `/3-design --section <name>`.
4. Model routing is binding (see `wiki/agents.md`): Fable plans and verifies, Opus builds, Sonnet re-checks and mass-tests, Haiku is not used. Plugin agents keep the model set in their definition.
5. Multi-agent workflows run only when the user types `use a workflow`; the cost estimate is shown first.
6. In this project the phase commands replace generic brainstorming and planning skills from other plugins.

## Working agreements

> Standing rules from the brief. They bind every task.

- **Design source:** {…}
- **Generative models:** {…}
- **Reference projects:** {…}
- **External services:** {names; keys in `secrets/`, variable names in `.env.example`}
- **Other rules:** {…}

## Secrets

`secrets/` holds the key files. Read them only to use a key locally. Never copy a value into chat, wiki, docs, logs, code, commits or Artifacts; refer to it by variable name. The folder is git-ignored and the secrets guard blocks leaks.

## Sessions

- **Start:** `/session-start` — reads this file, the handoff and the priorities; checks whether Claude Code changed since `wiki/claude-code.md`.
- **End:** `/session-end` — updates handoff, priorities, daily log; wiki hygiene; optional commit.
- One phase or one milestone per chat. Above the context threshold: hand off with a continuation prompt instead of pushing on.
- Wrong path: `/rewind` and re-prompt with the lesson. Between large tasks: `/clear` and a written brief. `/compact` always with a hint.

## Discipline

1. State assumptions; ask when two readings lead to different work.
2. The minimum that solves the stated problem.
3. Touch only what the task needs.
4. "Done" only with fresh evidence.
5. Every mistake becomes an `ERR-NNN` in `guardrails/errors-to-avoid.md`.
