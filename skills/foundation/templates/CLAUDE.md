# {Project}

> Facts a session cannot infer from the files, and where everything else lives. Read a page only when its hint below applies. Changed only with the user.

## Project

{Two or three lines from the brief: who it is for, what it does, the business model.}

- **Phase:** in `.scaffolder/phase` (1 brainstorm · 2 foundation · 3 design · 4 build · 5 release). `/phase-status` explains it.
- **Current milestone:** M{n} — {name} (`wiki/product/roadmap.md`)
- **Interaction mode (phases 4–5):** {Normal|Autopilot|Autonomous} (DEC-001)
- **Context threshold:** 300k tokens

## Commands

None yet: the platform is decided in phase 4, which then writes here the exact commands for install, run, full test suite, one test file, type check and lint.

## Where things live

| Path | Rule | Read when |
|---|---|---|
| `wiki/index.md` | One line per page | First, for any question about the project |
| `raw/` | Immutable sources: cite, never edit; new ones via `/wiki-ingest` | Checking where a claim comes from |
| `docs/brief/BRIEF.md` | The approved brief | A scope question |
| `wiki/handoff.md` · `wiki/priorities.md` | Session state; queued work | Starting a session or choosing the next task |
| `wiki/todo.md` | Notebook of unplanned items, `T-NNN` by priority; read through `/todo`, never whole | Something comes up for later; planning a milestone |
| `wiki/product/decisions.md` | Append-only `DEC-NNN` | Before changing anything a decision covers |
| `wiki/architecture.md` · `wiki/tech-stack.md` | Domain model, data flows, stack | Touching structure or dependencies |
| `wiki/design/registry.md` | Design system and approved sections | Any interface work |
| `wiki/agents.md` · `wiki/skills-map.md` | Roster and routing; skill links | Before dispatching an agent |
| `guardrails/errors-to-avoid.md` · `wiki/debugging/known-errors.md` | `ERR-NNN`, `KE-NNN` | Before a fix, when debugging |
| `.claude/skills/project-overview/SKILL.md` | Code map: layers, key directories, entry points, naming (from the project skeleton on) | Before searching the source tree |
| `.claude/skills/` | Project skills | Loaded by their descriptions |
| `.claude/rules/` | One folder's conventions, scoped with `paths:` | Load by themselves on a matching file |
| `.claude/settings.json` | Shared: enables this plugin for the repository{, blocks reads of `secrets/`}; personal settings go in `.claude/settings.local.json` | Before changing a setting |

## Knowledge

- A useful answer not in the wiki yet becomes a page (ask first). Page format comes from `.claude/rules/wiki.md`.
- A convention that applies to one folder goes in a `.claude/rules/<area>.md` with `paths:`, not here.
- The commit that creates the project skeleton, or adds, moves or renames a top-level source directory, an entry point or a layer, also writes or updates `.claude/skills/project-overview/SKILL.md` (sections: Layers, Key directories, Entry points, Naming, Not to search or edit; at most 80 lines; only paths that exist).
- Refer to files by path in backticks, never with an `@` import: an import loads the whole file into every session.
- Project knowledge (decisions, architecture, conventions, lessons) goes to `wiki/`, which the whole team shares. Auto memory is personal and outside the repo: keep it for the user's own preferences and corrections, never for project decisions.

## How work flows

1. One phase at a time, through its command and its exit gate. In phases 1–3 no application code is written; the phase guard enforces it.
2. In phase 4 every piece of work goes through `/task`: plan (architect) → build (builder) → verify (verifier) → bug hunt (bug-hunter) → persona test when the interface changes. Done only with evidence.
3. Interface work ports the approved artboards one to one. A missing design element stops the task and opens `/3-design --section <name>`.
4. Model routing is binding (`wiki/agents.md`): Fable plans and verifies, Opus builds, Sonnet re-checks and mass-tests, Haiku is not used.
5. Multi-agent workflows run only on the user's explicit choice: typing `use a workflow`, or answering the cost question of `/5-release` rounds, `/improve` or `/research`. The cost estimate comes first.
6. The phase commands replace generic brainstorming and planning skills from other plugins.

## Working agreements

> Standing rules from the brief. They bind every task.

- **Design source:** {…}
- **Generative models:** {…}
- **Reference projects:** {…}
- **External services:** {names; keys in `secrets/`, variable names in `.env.example`}
- **Git:** {commit per task: yes | no}
- **Other rules:** {…}

## Secrets

- `secrets/` holds the key files. It is git-ignored and never published; the secrets guard blocks leaks.
- Use a key by loading its file inside the command that needs it: `set -a; . secrets/<service>.env; set +a; <command>`. The value never enters the conversation.
- Anything read from `secrets/` with Read or `cat` lands in the session transcript. Read a key file only when loading it in the shell cannot work. Reads of `secrets/` here: {allowed|blocked by a deny rule} (DEC-003).
- Never copy a value into chat, wiki, docs, logs, code, commits or Artifacts; refer to it by variable name.

## Sessions

- `/session-start` and `/session-end` keep `wiki/handoff.md`, `wiki/priorities.md` and the daily log current.
- Anything for later (advice, an idea, a check not run) goes to `wiki/todo.md` with the next `T-NNN`; `/todo` shows it by priority.
- One phase or one milestone per chat. Above the context threshold, hand off: `wiki/handoff.md` holds the state, and the next chat starts with `/session-start <focus>`.
- An edit to this file reaches a running session only after `/clear`, `/compact` or a restart.

## Compact instructions

When compacting, keep: the current phase and milestone; the active `/task` id and its plan path; decisions made this session with their `DEC-NNN`; the last verifier verdict, open findings and unresolved bugs; files changed but not committed; the next step. Drop file contents and tool output that are already on disk or in the wiki.

## Discipline

1. State assumptions; ask when two readings lead to different work.
2. The minimum that solves the stated problem; touch only what the task needs.
3. "Done" only with fresh evidence.
4. Every mistake becomes an `ERR-NNN` in `guardrails/errors-to-avoid.md`.
