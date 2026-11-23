# project-scaffolder — maintainer hub

This repository is the source of the `project-scaffolder` Claude Code plugin. It is maintained with the same second-brain discipline the plugin generates: `wiki/` is the memory of the plugin's own development.

## First thing in every session

Before any other work, check Claude Code for changes:

1. Read `wiki/claude-code-changelog.md`: the last changelog version already reviewed.
2. Read the newer entries of https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md (raw: `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`). Only the entries after the recorded version.
3. For each entry that touches plugins, skills, commands, agents, hooks, models, permissions, Artifacts or workflows: note it in `wiki/claude-code-changelog.md` with what it means for this plugin (`adopt`, `adapt`, `watch`, `no impact`).
4. A new model more capable than the one in `agents/*.md` for planning and verification → propose updating the `model` of architect, verifier, bug-hunter and design-critic.
5. Update the recorded version, then report the findings in a few lines before starting the user's request.

## Layout

| Path | What |
|---|---|
| `commands/` | Slash commands. Thin: frontmatter (`description`, `argument-hint`, `model`) plus a pointer to a skill. No `name:` field (not valid in commands). |
| `skills/` | The logic. One folder per skill; templates in `skills/<skill>/templates/`. |
| `agents/` | The eight specialists, each with a fixed `model`. |
| `hooks/` | `hooks.json` plus bash scripts; `lib.sh` holds the shared helpers. |
| `tests/test-hooks.sh` | Regression tests for every hook. |
| `wiki/` | Development memory of the plugin. |

## Rules for changing the plugin

- **The flow is sequential.** Five phases, one exit artifact each, hard gates. A change must not let a later phase's work leak into an earlier one. The phase guard in `hooks/phase-guard.sh` is the mechanical half of that rule; keep it and the skills in agreement.
- **Model routing is fixed:** Fable plans and verifies, Opus builds, Sonnet re-checks and mass-tests, Haiku is not used. Change it only when the maintainer asks, and then in `agents/*.md`, `commands/*.md`, `skills/phase-flow`, `skills/foundation/templates/agents.md` and the README together.
- **Skill descriptions** state only when to use the skill and start with "Use when". The process goes in the body.
- **Hooks:** bash, no `jq`, JSON built only from fixed strings, Windows paths handled through `lib.sh`. Every hook change comes with a test case; `bash tests/test-hooks.sh` must pass.
- **Secrets:** nothing in this repository may contain a real key, a local path or personal data. `secrets/` is git-ignored here too.
- **Validate before every commit:** `claude plugin validate .` and `bash tests/test-hooks.sh`.
- **Releases:** bump `version` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` together, add a `CHANGELOG.md` entry, log it in `wiki/log.md`. Never push without the maintainer saying so.

## Wiki

| Page | What |
|---|---|
| `wiki/index.md` | Map of the pages |
| `wiki/claude-code-changelog.md` | Claude Code versions reviewed and what each changes for the plugin |
| `wiki/decisions.md` | Design decisions of the plugin (append-only) |
| `wiki/sources.md` | Third-party projects evaluated, with verdicts |
| `wiki/log.md` | Append-only history: `## [YYYY-MM-DD] <op> \| <title>` |
