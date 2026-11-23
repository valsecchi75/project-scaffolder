---
name: foundation
description: Use when /2-foundation runs after an approved brief, or when a project scaffolded by an older version of this plugin needs migrating to the phase flow (/2-foundation --upgrade).
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/verify.sh")
---

# Foundation — phase 2: the second brain and the agent setup

From the approved brief, build everything the agents will need to work for months without re-explaining the project: the hub, the wiki, the project skills, the agent roster, the secrets folder and the guardrails. No application code and no design files: those are phases 3 and 4.

The structure follows the LLM-wiki pattern (Karpathy): immutable **raw sources**, an LLM-maintained **wiki**, and a **schema** (`CLAUDE.md`) that tells every session how to maintain it. The `wiki-keeper` skill runs the wiki from here on.

## Gate in

1. `docs/brief/BRIEF.md` exists with `status: approved`. If not, stop: "The brief is not approved yet. Finish `/1-brainstorm` first." With `--upgrade`, read `${CLAUDE_SKILL_DIR}/upgrade.md` and follow it instead of the steps below.
2. Write `foundation` to `.scaffolder/phase`.
3. Read the brief and everything in `raw/`, except that under `raw/research/` you read only each `digest.md`: the sources beside it are long, untrusted text. This phase starts from the files, never from the brainstorm chat.

## Generate

Every file starts with meaningful content from the brief. No empty placeholders: a page that has nothing to say yet is not created, it is listed in the index as on demand.

### 1. Hub and schema — `CLAUDE.md` (at most 120 lines)

Use `templates/CLAUDE.md` from this skill's folder: fill it, do not restructure it. Claude Code loads this file into every session and every subagent, so it holds only facts Claude cannot infer from the files, plus a pointer index with a "read when" hint per path. Procedures stay in skills, detail in the wiki. Refer to files by path in backticks, never with an `@` import (an import loads the whole file every time). Keep out dates and session state: they go to `wiki/handoff.md`. Keep the **Compact instructions** section: compaction reads it to decide what to preserve.

### 2. Raw sources — `raw/`

Already started in phase 1. Add `raw/README.md` stating the rule: files here are immutable (`raw/parking-lot.md` was append-only during phase 1 and is frozen since the approval; phases 3 and 4 read their lines there); the wiki summarises and cites them; new sources enter through `/wiki-ingest`.

### 3. The wiki — `wiki/`

Core pages, always created:

| Page | Content |
|---|---|
| `wiki/index.md` | Catalogue of every page, one line each: link, summary of at most 150 characters, category. Lists on-demand pages under "Not yet created". At most 200 lines: past that, group pages under a sub-index. Read first by every query. |
| `wiki/log.md` | Append-only. One line per operation: `## [YYYY-MM-DD] <op> \| <title>` where op is `ingest`, `decision`, `phase`, `milestone`, `release`, `lint`, `error`. First entry: `phase \| Foundation`. |
| `wiki/overview.md` | Product synthesis from the brief: problem, user, outcome, scope, non-goals. |
| `wiki/handoff.md` | Session state: done, in progress (the exact point), next with its VERIFY criterion, files to read first, stable files not to re-read (at most 80 lines). |
| `wiki/priorities.md` | What is queued, each item with `→ VERIFY:` (at most 100 lines). |
| `wiki/todo.md` | The notebook of unplanned items (backlog skill's `templates/todo.md`), with one `question` line (`from: user`) per item still under the brief's **Open questions**: phase 1 has no wiki. |
| `wiki/agents.md` | From `templates/agents.md`: the roster, the routing and the rules of delegation for this project. |
| `wiki/product/roadmap.md` | Milestones (not phases): M1 is the first release scope from the brief; later milestones from the backlog. Each with goal, capabilities and status. |
| `wiki/product/decisions.md` | Append-only `DEC-NNN` entries. DEC-001: interaction mode. DEC-002: working agreements. DEC-003: key reads (step 5b). Every decision lists alternatives and why. |
| `wiki/architecture.md` | Domain model and data flows derived from the brief. No stack yet: "Platform decided in phase 4". |
| `wiki/tech-stack.md` | Stub: constraints copied from the brief, and "Platform decision pending (phase 4)". |
| `wiki/debugging/known-errors.md` | Template for `KE-NNN` entries. |
| `wiki/claude-code.md` | First line `Last checked version: <claude --version>` (the session brief parses it), then the features this project relies on. See **Staying current**. |
| `guardrails/errors-to-avoid.md` | Template for `ERR-NNN` entries. |

When the brief has an interface, also create `wiki/design/registry.md` from the design-studio skill's `templates/registry.md`, with one row per section or feature listed in the first-release scope, status `todo`.

On-demand pages, listed in the index and created on first real use: `wiki/glossary.md`, `wiki/branding.md`, `wiki/product/features.md`, `wiki/ux/flows.md`, `wiki/debugging/failed-experiments.md`, `wiki/incubator/ideas.md`, `wiki/sources/<slug>.md` (one per ingested source).

Write the page conventions first, as a path-scoped rule (next step), and follow them on every page.

### 3b. Path-scoped rules — `.claude/rules/`

Conventions that matter only inside one folder go in `.claude/rules/<area>.md` with a `paths:` list, not in `CLAUDE.md`: Claude Code loads such a rule only when a matching file is read or edited, so it costs nothing in sessions that never touch that folder, and it loads again on demand after compaction. Copy from this skill's `templates/rules/`:

| Rule | `paths` | When |
|---|---|---|
| `.claude/rules/wiki.md` | `wiki/**` | Always: page format, index line, append-only files |
| `.claude/rules/design.md` | `design/**` | When the brief has an interface |

Facts every session needs (phase, `raw/` immutable, secrets, the pointer table) stay in `CLAUDE.md`. Rules for code areas are added once those areas exist, the same way: one topic per file, `paths:` relative to the project root.

### 4. Project skills — `.claude/skills/`

Project skills live in `.claude/skills/<prefix>-<name>/SKILL.md`, where Claude Code discovers them. The prefix is two to four letters from the project name.

Generate now only what the brief supports without knowing the platform:

| Skill | When |
|---|---|
| `<prefix>-domain` | Always: the domain model, business rules and invariants, with examples. |
| `<prefix>-brand-voice` | Always: tone, vocabulary, forbidden words, microcopy patterns, in the brief's language. |
| `<prefix>-release-gate` | Always: the stages from `templates/release-gate.md`. |
| Domain-specific skills | One per distinct domain area in the scope (payments, scheduling, notifications…), only when the brief gives real rules for it. |

Stack skills (framework patterns, deployment) are generated in phase 4, after the platform decision, with `/skill-new`.

**Code map.** `.claude/skills/project-overview/SKILL.md`, from `templates/project-overview.md`, tells every session and subagent where code lives (layers, key directories, entry points, naming) so it does not explore the tree to find out. It is not written now: there is no code yet. The activity that creates the project skeleton in phase 4 writes it, and `--upgrade` writes it for a project that already has code. The folder name is fixed, without the prefix, so agents can preload it by name; a missing preloaded skill is skipped. The generated `CLAUDE.md` carries the rule that keeps it current.

Use `templates/project-skill.md` for every other skill. Descriptions state only when to use the skill (starting "Use when"), never what it does step by step.

Create `wiki/skills-map.md` in the layout of the `synapse` skill's map (Skills with 0 pending notes each, Connections by shared concept, data or rule, an empty Recent propagations table). The synapse skill maintains it.

### 5. Secrets — `secrets/`

1. Create `secrets/README.md` explaining: this folder holds hand-over files with keys (one `.env`-style file per service); it is git-ignored and never published; agents may read it to use keys locally; values are never copied anywhere else.
2. Create or update `.gitignore` with at least:
   ```
   secrets/
   .env
   .env.*
   !.env.example
   ```
3. Create `.env.example` listing the variable names of every external service in the working agreements, with an empty value and a comment saying which file in `secrets/` provides it.
4. Ask the user to drop the real key files into `secrets/` themselves. Never ask them to paste a key into the chat.

The `secrets-guard` hook enforces the rest: it blocks commits while `secrets/` is not ignored, blocks copying a value out of `secrets/` into another file or an Artifact, and blocks inlining a value in a shell command.

### 5b. Project settings — `.claude/settings.json`

The phase, secrets and destructive-command guards are this plugin's hooks: a clone opened without the plugin runs none of them. Write `.claude/settings.json` from `templates/settings.json` so that everyone who opens the repository is offered the plugin (its dependencies follow it):

1. **Plugin id.** Use the id this plugin is installed under here: the `project-scaffolder@…` entry of `claude plugin list --json`, or, when `claude` is not on the PATH (VS Code), of `enabledPlugins` in `~/.claude/settings.json` (read it, never change it). Keep `extraKnownMarketplaces` only for `project-scaffolder-marketplace`; for another marketplace (a local checkout) drop the block and tell the user teammates add that marketplace themselves.
2. **Existing file** (upgrade, or a repository that had one): merge these keys and keep every other key.
3. **Key reads (opt-in).** This step relies on AskUserQuestion, asked here in the main conversation. First explain in two lines: whatever Claude reads from `secrets/` lands in the session transcript; a deny rule stops Claude's file tools and simple file commands such as `cat` from reading the folder for everyone who clones the repository, but not a script that opens the files itself; it also stops Claude from writing there. Then ask one question, header `Key reads`: **Readable** (the plugin's default: agents may read keys to use them locally) or **Block reads**. With Block reads, first change the "agents may read it" line of `secrets/README.md` to say reads are blocked (DEC-003), then add `"permissions": { "deny": ["Read(./secrets/**)"] }`, then, once a key file is in place, run `set -a; . secrets/<file>.env; set +a; echo loaded`: if the rule also blocks loading, say so and offer to remove it. Record the answer as DEC-003.
4. Nothing else goes in this shared file: no hooks (the plugin provides them), no `model` or `fallbackModel` (a per-user choice, see `/setup-check`), no `allow` rules. Personal settings belong in `.claude/settings.local.json`.

Add to `wiki/claude-code.md` the line teammates run once after trusting the folder: `claude plugin install <id> --scope project`. The repository setting enables the plugin; it does not install it.

### 6. Session and audit files

```
daily-log/YYYY-MM-DD.md      today's entry: what the foundation produced
logs/pipeline/  logs/errors/  (pipeline-logger skill)
docs/plans/tasks/  docs/release/
```

### 7. Git

If the folder is not a repository, `git init`. Check that `git check-ignore secrets/x` succeeds, then make the first commit: `chore: foundation (project-scaffolder)`, with `.scaffolder/phase` in it (a worktree knows its phase only from the committed file). Never push.

## Verify

From the project root run `bash "${CLAUDE_SKILL_DIR}/scripts/verify.sh"` and show its output. It is read-only and checks, one line each: every core file above, the `CLAUDE.md` and `wiki/index.md` caps, the Compact instructions section, `@` imports and `{placeholders}` left in `CLAUDE.md`, the path-scoped rules, `.claude/settings.json` (valid JSON, plugin enabled), the project skill descriptions, the code map from phase `build` on, and that `secrets/` and `.env` are git-ignored. Its last line counts the problems: fix each and rerun until it reads `verify: all checks passed`. Without Git Bash, make the same checks by hand and say so.

## Gate out

Show the user: the file tree, the skills generated with one line each, the agent roster, the variable names expecting keys, the key-reads choice (DEC-003), and the on-demand pages. Ask for confirmation. On confirmation, append `## [date] phase | Foundation complete` to the log and give the next command:

- interface in the brief → `/3-design`
- no interface → `/4-build`

## Staying current with Claude Code

`wiki/claude-code.md` records the Claude Code version this project was last checked against and the features it relies on (agents, hooks, skills, Artifact types). `/session-start` compares it with `claude --version`; when the version changed, it reads only the newer entries of https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md, notes what affects this project, and updates the page.
