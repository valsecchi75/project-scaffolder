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
| `commands/` | Slash commands. Thin: frontmatter (`description`, `argument-hint`, `disable-model-invocation` on user-only commands) plus a pointer to a skill. No `name:` field (not valid in commands). No `model:` on commands that run in the main conversation (it forces an uncached re-read); a read-only report may use `context: fork` with a `model`. |
| `skills/` | The logic. One folder per skill; templates in `skills/<skill>/templates/`; read-only bash helpers in `skills/<skill>/scripts/`, pre-approved by the skill's `allowed-tools`, each with a by-hand fallback for sessions without Git Bash. |
| `agents/` | The eight specialists, each with a fixed `model` and `effort`. |
| `hooks/` | `hooks.json` plus bash scripts; `lib.sh` holds the shared helpers. |
| `workflows/` | The three loops as plugin workflows: `release-rounds.js` (skill `release`, `rounds.md`), `improve-segment.js` (skill `improve-loop`), `research-rounds.js` (skill `idea-research`). The skill owns the questions, the journal and the fallback; the script owns one run. |
| `tests/test-hooks.sh` | Regression tests for every hook and for the bundled scripts. |
| `evals/` | `claude plugin eval` cases for the gates (see `evals/README.md`). Paid model runs: before a release, not every commit. |
| `wiki/` | Development memory of the plugin. |

## Rules for changing the plugin

- **The flow is sequential.** Five phases, one exit artifact each, hard gates. A change must not let a later phase's work leak into an earlier one. The phase guard in `hooks/phase-guard.sh` is the mechanical half of that rule; keep it and the skills in agreement.
- **Model routing is fixed:** Fable plans and verifies, Opus builds, Sonnet re-checks and mass-tests, Haiku is not used. Change it only when the maintainer asks, and then in `agents/*.md`, the forked reports in `commands/*.md`, the `model` options in `workflows/*.js`, `skills/phase-flow`, `skills/foundation/templates/agents.md` and the README together.
- **Skill descriptions** state only when to use the skill and start with "Use when". The process goes in the body.
- **One name, one component:** skills, commands and workflows share the `/project-scaffolder:<name>` namespace, so no two of them may have the same name (hence the `debugging` skill behind `/bug-hunt`, and workflow names that differ from their skills).
- **Hooks:** bash, no `jq`, JSON built only from fixed strings, Windows paths handled through `lib.sh`. The project root comes from the hook input's `cwd` (nearest `.scaffolder/phase`), `CLAUDE_PROJECT_DIR` only as the fallback. The three PreToolUse guards fail closed (`onFailure: "block"`): every decision path exits 0 with valid JSON or no output, and a guard that lost its rules exits non-zero. The other hooks fail open. Every hook change comes with a test case; `bash tests/test-hooks.sh` must pass.
- **Loops (workflows):** the first statement is a pure-literal `export const meta = {name, description, phases}`; plain JS reading the `args` global; no `Date.now` or `Math.random` (resume replays the script). A workflow cannot ask the user, so the skill asks everything with AskUserQuestion before launch, shows the cost estimate and the caps (rounds or iterations, agents), writes the journal after every run and resumes from it alone. Each skill keeps a fallback section for sessions without workflows (Pro default, `disableWorkflows`, `CLAUDE_CODE_DISABLE_WORKFLOWS`): the same steps from the main session with the scoped agents, one after another. Change a cap, a journal field or a status in the script and the skill together.
- **Visibility costs no model tokens:** user-facing lines go in a hook's top-level `systemMessage` (the SessionStart banner) or in the `reason` of a `UserPromptExpansion` block, which is shown to the user before the command loads (`command-gate.sh`); `additionalContext` stays byte-identical across sessions, with no timestamps or session-specific values.
- **Secrets:** nothing in this repository may contain a real key, a local path or personal data. `secrets/` is git-ignored here too.
- **Validate before every commit:** `claude plugin validate .` and `bash tests/test-hooks.sh`.
- **Releases:** the version lives only in `.claude-plugin/plugin.json`; the marketplace entry has none (with both set, Claude Code silently uses `plugin.json`). Bump it on every push meant for users, or installed copies keep their cache (`claude plugin update` answers "already at the latest version"). Move the `CHANGELOG.md` "Unreleased" entries under the new version, log it in `wiki/log.md`. Never push without the maintainer saying so.

## Wiki

| Page | What |
|---|---|
| `wiki/index.md` | Map of the pages |
| `wiki/claude-code-changelog.md` | Claude Code versions reviewed and what each changes for the plugin |
| `wiki/decisions.md` | Design decisions of the plugin (append-only) |
| `wiki/sources.md` | Third-party projects evaluated, with verdicts |
| `wiki/log.md` | Append-only history: `## [YYYY-MM-DD] <op> \| <title>` |
| `wiki/todo.md` | Notebook of unplanned work, `T-NNN` by priority: `bash skills/backlog/scripts/todo-report.sh .` |
