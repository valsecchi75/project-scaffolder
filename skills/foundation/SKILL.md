---
name: foundation
description: Use when /2-foundation runs after an approved brief, or when a project scaffolded by an older version of this plugin needs migrating to the phase flow (/2-foundation --upgrade).
---

# Foundation — phase 2: the second brain and the agent setup

From the approved brief, build everything the agents will need to work for months without re-explaining the project: the hub, the wiki, the project skills, the agent roster, the secrets folder and the guardrails. No application code and no design files: those are phases 3 and 4.

The structure follows the LLM-wiki pattern (Karpathy): immutable **raw sources**, an LLM-maintained **wiki**, and a **schema** (`CLAUDE.md`) that tells every session how to maintain it. The `wiki-keeper` skill runs the wiki from here on.

## Gate in

1. `docs/brief/BRIEF.md` exists with `status: approved`. If not, stop: "The brief is not approved yet. Finish `/1-brainstorm` first." With `--upgrade`, follow **Upgrading a v3 project** at the end instead.
2. Write `foundation` to `.scaffolder/phase`.
3. Read the brief and everything in `raw/`.

## Generate

Every file starts with meaningful content from the brief. No empty placeholders: a page that has nothing to say yet is not created, it is listed in the index as on demand.

### 1. Hub and schema — `CLAUDE.md` (at most 120 lines)

Use `templates/CLAUDE.md` from this skill's folder. It is the schema of the wiki: fill it, do not restructure it.

### 2. Raw sources — `raw/`

Already started in phase 1. Add `raw/README.md` stating the rule: files here are immutable; the wiki summarises and cites them; new sources enter through `/wiki-ingest`.

### 3. The wiki — `wiki/`

Core pages, always created:

| Page | Content |
|---|---|
| `wiki/index.md` | Catalogue of every page: link, one-line summary, category. Lists on-demand pages under "Not yet created". Read first by every query. |
| `wiki/log.md` | Append-only. One line per operation: `## [YYYY-MM-DD] <op> \| <title>` where op is `ingest`, `decision`, `phase`, `milestone`, `release`, `lint`, `error`. First entry: `phase \| Foundation`. |
| `wiki/overview.md` | Product synthesis from the brief: problem, user, outcome, scope, non-goals. |
| `wiki/handoff.md` | Session state: done, in progress, next, files to read (at most 80 lines). |
| `wiki/priorities.md` | What is queued, each item with `→ VERIFY:` (at most 100 lines). |
| `wiki/agents.md` | From `templates/agents.md`: the roster, the routing and the rules of delegation for this project. |
| `wiki/product/roadmap.md` | Milestones (not phases): M1 is the first release scope from the brief; later milestones from the backlog. Each with goal, capabilities and status. |
| `wiki/product/decisions.md` | Append-only `DEC-NNN` entries. DEC-001: interaction mode. DEC-002: working agreements. Every decision lists alternatives and why. |
| `wiki/architecture.md` | Domain model and data flows derived from the brief. No stack yet: "Platform decided in phase 4". |
| `wiki/tech-stack.md` | Stub: constraints copied from the brief, and "Platform decision pending (phase 4)". |
| `wiki/debugging/known-errors.md` | Template for `KE-NNN` entries. |
| `wiki/claude-code.md` | Claude Code version last seen and features this project relies on. See **Staying current**. |
| `guardrails/errors-to-avoid.md` | Template for `ERR-NNN` entries. |

When the brief has an interface, also create `wiki/design/registry.md` from the design-studio skill's `templates/registry.md`, with one row per section or feature listed in the first-release scope, status `todo`.

On-demand pages, listed in the index and created on first real use: `wiki/glossary.md`, `wiki/branding.md`, `wiki/product/features.md`, `wiki/ux/flows.md`, `wiki/debugging/failed-experiments.md`, `wiki/incubator/ideas.md`, `wiki/sources/<slug>.md` (one per ingested source).

Page conventions (all pages):

- First line after the title: `> last-verified: YYYY-MM-DD`.
- One concept per page. Link related pages with relative links, and cite the raw source a claim comes from.
- Tag claims `[FACT]`, `[DECISION]`, `[HYPOTHESIS]`.
- When a new fact contradicts a page, do not overwrite it: mark the old claim `~~superseded~~`, add the new one with its source, and log it.

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

Use `templates/project-skill.md` for every skill. Descriptions state only when to use the skill (starting "Use when"), never what it does step by step.

Create `wiki/skills-map.md` with the connections between these skills (shared concepts, data, rules) and `pending_notes: 0` for each. The `synapse` skill maintains it.

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

### 6. Session and audit files

```
daily-log/YYYY-MM-DD.md      today's entry: what the foundation produced
logs/pipeline/  logs/errors/  (pipeline-logger skill)
docs/plans/tasks/  docs/release/
```

### 7. Git

If the folder is not a repository, `git init`. Check that `git check-ignore secrets/x` succeeds, then make the first commit: `chore: foundation (project-scaffolder)`. Never push.

## Verify

Run and show the output:

```bash
for f in CLAUDE.md raw/README.md docs/brief/BRIEF.md wiki/index.md wiki/log.md wiki/overview.md \
  wiki/handoff.md wiki/priorities.md wiki/agents.md wiki/product/roadmap.md \
  wiki/product/decisions.md wiki/architecture.md wiki/tech-stack.md \
  wiki/debugging/known-errors.md wiki/claude-code.md wiki/skills-map.md \
  guardrails/errors-to-avoid.md secrets/README.md .env.example .gitignore; do
  [ -f "$f" ] && echo "OK       $f" || echo "MISSING  $f"
done
awk 'END { print (NR > 120 ? "FAIL" : "OK  ") "     CLAUDE.md " NR " lines" }' CLAUDE.md
for f in .claude/skills/*/SKILL.md; do
  head -6 "$f" | grep -q '^description: Use when' && echo "OK       $f" || echo "BAD DESC $f"
done
git check-ignore -q secrets/probe && echo "OK       secrets/ ignored" || echo "FAIL     secrets/ not ignored"
grep -c '^## \[' wiki/log.md | sed 's/^/OK       log entries: /'
```

Every line must be `OK`. Fix and rerun until it is.

## Gate out

Show the user: the file tree, the skills generated with one line each, the agent roster, the variable names expecting keys, and the on-demand pages. Ask for confirmation. On confirmation, append `## [date] phase | Foundation complete` to the log and give the next command:

- interface in the brief → `/3-design`
- no interface → `/4-build`

## Staying current with Claude Code

`wiki/claude-code.md` records the Claude Code version this project was last checked against and the features it relies on (agents, hooks, skills, Artifact types). `/session-start` compares it with `claude --version`; when the version changed, it reads only the newer entries of https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md, notes what affects this project, and updates the page.

## Upgrading a v3 project (`--upgrade`)

A v3 project has `CLAUDE.md`, the wiki and `skills/` but no `.scaffolder/phase`. Show the plan below, wait for confirmation, then apply it:

1. `.scaffolder/phase` ← `build` (the project is already in development). If there is no `docs/brief/BRIEF.md`, derive one from `wiki/overview.md` and the design spec, mark it `status: approved` with a note that it was reconstructed, and ask the user to confirm it.
2. Move `skills/<name>/` to `.claude/skills/<name>/` with `git mv`; move `skills/_synapse-map.md` to `wiki/skills-map.md`.
3. Rename `docs/phases/PHASE-<n>-execution.md` to `docs/plans/MILESTONE-<n>.md` and add the `Agent` column (see the cortex skill's milestone template).
4. Create `raw/` (copy the original brief or design spec there), `wiki/agents.md`, `wiki/claude-code.md`, `secrets/` with the `.gitignore` lines, `.env.example`.
5. Hooks: v3 copied the guard scripts into `.claude/hooks/` and wired them in `.claude/settings.json`. The plugin now provides them, so they run twice. Show the user the hook entries and ask before removing them.
6. Replace the CLAUDE.md sections "Task Pipeline" and "Navigation" with the v4 template's; keep Working Agreements and everything project-specific.
7. Interface projects: create `wiki/design/registry.md` and register existing designs as `approved (pre-v4)` with their location.
8. Run **Verify**, commit `chore: upgrade to project-scaffolder v4`, report.
