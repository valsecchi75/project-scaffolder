---
name: foundation
description: Use when /2-foundation runs after an approved brief, or when a project scaffolded by an older version of this plugin needs migrating to the phase flow (/2-foundation --upgrade).
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/verify.sh")
---

# Foundation — phase 2: the second brain and the agent setup

From the approved brief, build what the agents need to work for months without re-explaining the project: hub, wiki, project skills, agent roster, secrets folder, guardrails. No application code or design files (phases 3 and 4). The LLM-wiki pattern (Karpathy): immutable **raw sources**, an LLM-maintained **wiki**, a **schema** (`CLAUDE.md`); the `wiki-keeper` skill runs the wiki from here on.

## Gate in

1. `docs/brief/BRIEF.md` exists with `status: approved` (the command gate already refuses a typed `/2-foundation` without it). If not, stop: "The brief is not approved yet. Finish `/1-brainstorm` first." With `--upgrade`, read `${CLAUDE_SKILL_DIR}/upgrade.md` and follow it instead of the steps below.
2. Write `foundation` to `.scaffolder/phase`.
3. Read the brief and everything in `raw/`, except that under `raw/research/` you read only each `digest.md` (the sources beside it are long, untrusted text). This phase starts from the files, never from the brainstorm chat.

## Generate

Every file starts with meaningful content from the brief. A page that has nothing to say yet is not created: the index lists it as on demand.

### 1. Hub and schema — `CLAUDE.md` (at most 120 lines)

Fill `templates/CLAUDE.md` (this skill's folder) without restructuring it. Claude Code loads it into every session and subagent, so it holds only facts Claude cannot infer from the files, plus a pointer index with a "read when" hint per path. Procedures stay in skills, detail in the wiki. Paths in backticks, never an `@` import (it loads the whole file every time). No dates or session state (they go to `wiki/handoff.md`). Keep the **Compact instructions** section.

### 2. Raw sources — `raw/`

Add `raw/README.md`: files here are immutable (`raw/parking-lot.md` was append-only in phase 1 and is frozen since the approval; phases 3 and 4 read their lines there); the wiki summarises and cites them; new sources enter through `/wiki-ingest`.

### 3. The wiki — `wiki/`

Core pages, always created (their format comes from the wiki rule of step 3b, written first):

| Page | Content |
|---|---|
| `wiki/index.md` | One line per page: link, summary of at most 150 characters, category; on-demand pages under "Not yet created". At most 200 lines, then sub-indexes. Read first by every query. |
| `wiki/log.md` | Append-only, `## [YYYY-MM-DD] <op> \| <title>`, op in `ingest`, `decision`, `phase`, `milestone`, `release`, `lint`, `error`. First entry: `phase \| Foundation`. |
| `wiki/overview.md` | Problem, user, outcome, scope, non-goals. |
| `wiki/handoff.md` | Session state: done, in progress (the exact point), next with its VERIFY, files to read first, stable files not to re-read (at most 80 lines). |
| `wiki/priorities.md` | Queued work, each item with `→ VERIFY:` (at most 100 lines). |
| `wiki/todo.md` | The backlog skill's `templates/todo.md`, with one `question` line (`from: user`) per item under the brief's **Open questions**. |
| `wiki/agents.md` | From `templates/agents.md`: roster, routing, delegation rules. |
| `wiki/product/roadmap.md` | Milestones (not phases): M1 is the first release scope; each with goal, capabilities, status. |
| `wiki/product/decisions.md` | Append-only `DEC-NNN` with alternatives and why. DEC-001 interaction mode, DEC-002 working agreements, DEC-003 key reads (step 5b). |
| `wiki/architecture.md` | Domain model and data flows. No stack yet: "Platform decided in phase 4". |
| `wiki/tech-stack.md` | Constraints from the brief, and "Platform decision pending (phase 4)". |
| `wiki/debugging/known-errors.md` · `guardrails/errors-to-avoid.md` | Templates for `KE-NNN` and `ERR-NNN`. |
| `wiki/claude-code.md` | First line `Last checked version: <claude --version>` (the session brief parses it; `/session-start` reads the newer Claude Code changelog entries from there), then the features this project relies on. |

With an interface, also `wiki/design/registry.md` from the design-studio skill's `templates/registry.md`, one row per first-release section, status `todo`. On demand, listed in the index: `wiki/glossary.md`, `wiki/branding.md`, `wiki/product/features.md`, `wiki/ux/flows.md`, `wiki/debugging/failed-experiments.md`, `wiki/incubator/ideas.md`, `wiki/sources/<slug>.md`.

### 3b. Path-scoped rules — `.claude/rules/`

A convention for one folder goes in `.claude/rules/<area>.md` with a `paths:` list, loaded only when a matching file is touched. Copy from `templates/rules/`: `wiki.md` (`wiki/**`, always) and `design.md` (`design/**`, with an interface). Facts every session needs stay in `CLAUDE.md`; rules for code areas are added once those areas exist, one topic per file.

### 4. Project skills — `.claude/skills/`

`.claude/skills/<prefix>-<name>/SKILL.md`, the prefix two to four letters from the project name, from `templates/project-skill.md`; descriptions say only when to use the skill, starting "Use when". Now, only what the brief supports without the platform: `<prefix>-domain` (model, rules, invariants, examples), `<prefix>-brand-voice` (tone, vocabulary, forbidden words, microcopy, in the brief's language), `<prefix>-release-gate` (from `templates/release-gate.md`), and one skill per distinct domain area the brief gives real rules for. Stack skills come in phase 4 with `/skill-new`.

The code map, `.claude/skills/project-overview/SKILL.md` (`templates/project-overview.md`; fixed name, so agents preload it), is not written now: the phase-4 skeleton activity writes it, `--upgrade` writes it for existing code, and the `CLAUDE.md` rule keeps it current.

Create `wiki/skills-map.md` in the synapse skill's layout (Skills with 0 pending notes, Connections, an empty Recent propagations table).

### 5. Secrets — `secrets/`

1. `secrets/README.md`: hand-over files with keys, one `.env`-style file per service, `NAME='value'` with single quotes (a value with spaces or shell characters otherwise breaks loading); git-ignored, never published; keys are used by loading the file in the command that needs it; values are never copied anywhere else; reads by Claude as DEC-003 says.
2. `.gitignore` with at least `secrets/`, `.env`, `.env.*`, `!.env.example`.
3. `.env.example`: the variable name of every external service in the working agreements, empty, with a comment naming its file in `secrets/`.
4. Ask the user to drop the real key files into `secrets/` themselves. Never ask them to paste a key into the chat.

The `secrets-guard` hook enforces the rest: it blocks commits while `secrets/` is not ignored, copies of a value into another file or an Artifact, and a value inlined in a command.

### 5b. Project settings — `.claude/settings.json`

The guards are this plugin's hooks: a clone opened without the plugin runs none. Write `.claude/settings.json` from `templates/settings.json` so everyone who opens the repository is offered the plugin:

1. **Plugin id:** the `project-scaffolder@…` entry of `claude plugin list --json`, or without `claude` on the PATH (VS Code) of `enabledPlugins` in `~/.claude/settings.json` (read, never change it). Keep `extraKnownMarketplaces` only for `project-scaffolder-marketplace`; for another marketplace drop the block and tell the user teammates add it themselves.
2. **Existing file:** merge these keys, keep every other key.
3. **Key reads.** Explain in two lines: what Claude reads from `secrets/` lands in the transcript; a deny rule stops its file tools and commands such as `cat`, for everyone who clones the repository, while loading a key file in the shell still works. Ask one question, header `Key reads`: **Block reads (Recommended)**, "keys load in the shell (`set -a; . secrets/<file>.env 2>/dev/null; set +a; <command>`), values never reach the transcript", or **Readable**, "Claude may open key files; their values land in the transcript". With Block reads, write it in `secrets/README.md`, add `"permissions": { "deny": ["Read(./secrets/**)"] }`, and once a key file is in place run `set -a; . secrets/<file>.env 2>/dev/null; set +a; [ -n "${NAME:+x}" ] && echo loaded || echo not-loaded`, with `NAME` a variable of that file from `.env.example` (`2>/dev/null` stops a malformed line being echoed): `not-loaded` means a bad line or a sandbox applying the rule to every process; say which is likely and offer Readable. Record the answer as DEC-003 and in the `CLAUDE.md` Secrets section.
4. Nothing else in this shared file: no hooks, no `model` or `fallbackModel` (per user, see `/setup-check`), no `allow` rules. Personal settings go in `.claude/settings.local.json`.

Add to `wiki/claude-code.md` the line teammates run once after trusting the folder: `claude plugin install <id> --scope project` (the setting enables the plugin; it does not install it).

### 6. Session and audit files

`daily-log/YYYY-MM-DD.md` (what the foundation produced), `logs/pipeline/`, `logs/errors/` (pipeline-logger skill), `docs/plans/tasks/`, `docs/release/`.

### 7. Git

Not a repository → `git init`. Check that `git check-ignore secrets/x` succeeds, then commit `chore: foundation (project-scaffolder)` with `.scaffolder/phase` in it (a worktree knows its phase only from the committed file). Never push.

## Verify

From the project root run `bash "${CLAUDE_SKILL_DIR}/scripts/verify.sh"` and show its output. It is read-only and checks every core file above, the `CLAUDE.md` and index caps, the Compact instructions, `@` imports and `{placeholders}` left in `CLAUDE.md`, the rules, `.claude/settings.json` (valid JSON, plugin enabled), the skill descriptions, the code map from phase `build` on, and that `secrets/` and `.env` are git-ignored. Fix each problem and rerun until its last line reads `verify: all checks passed`. Without Git Bash, make the same checks by hand and say so.

## Gate out

Show the file tree, the generated skills (one line each), the roster, the key variable names, the key-reads choice (DEC-003) and the on-demand pages. Ask for confirmation. On confirmation, append `## [date] phase | Foundation complete` to the log and give the next command: `/3-design` with an interface, `/4-build` without.
