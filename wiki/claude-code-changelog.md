# Claude Code changelog — reviewed for the plugin

> last-verified: 2026-11-23

**Last changelog version reviewed: 2.1.330** (entries 2.1.321 to 2.1.330 read on 2026-11-23). Installed version at that check: 2.1.329.

Source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md. At the start of each session, read only the entries after the version above, then update this page (see `CLAUDE.md`).

Impact: `adopt` (use it now) · `adapt` (change the plugin) · `watch` (may matter later) · `no impact`.

## Reviewed entries

| Version | Change | Impact | Notes |
|---|---|---|---|
| 2.1.330 | `claude plugin install --json` gains fields; `/mcp` groups plugin servers | no impact | |
| 2.1.329 | `/code-review` reports only bugs and CLAUDE.md violations; cleanups moved to `/simplify` | adopt | `/5-release` suggests `/code-review` as a user-triggered extra |
| 2.1.329 | A failing PreToolUse hook no longer blocks unless `onFailure: "block"` | watch | Guards fail open by design today; consider `onFailure: "block"` for `secrets-guard` if it ever errors in the field |
| 2.1.329 | Scheduled tasks saved earlier must be rescheduled | no impact | |
| 2.1.328 | `network` field in plugin.json | adopt | Declared `raw.githubusercontent.com`, `github.com` |
| 2.1.327 | `claude plugin eval` keeps deny rules | watch | Eval suite for the phase gates is a candidate (see below) |
| 2.1.325 | `.claude/skills` in `--plugin-dir` plugins no longer load from a session started higher up | no impact | The plugin ships skills under `skills/` |
| 2.1.325 | `pluginDigests` deprecated | no impact | |
| 2.1.323 | `engines["claude-code"]` in plugin.json | adopt | Set to `>=2.1.323` |
| 2.1.323 | The plugin `agent` setting warns (deprecated) | no impact | Not used |
| 2.1.323 | Hook `decision: "block"` applies in more cases | no impact | Hooks use `permissionDecision` |
| 2.1.321 | Fable 5.2 (`claude-fable-5-2`), default model | adopt | Planning and verification agents use `fable` |

## Capabilities the plugin relies on

| Capability | Where | Verified |
|---|---|---|
| Agent frontmatter `model: fable \| opus \| sonnet`, `effort`, `disallowedTools` | `agents/*.md` | docs, 2026-11-23 |
| Command frontmatter `model`, `argument-hint`; no `name` | `commands/*.md` | docs + `claude plugin validate` |
| Command names starting with a digit (`1-brainstorm`) | `commands/` | `claude plugin validate`, 2026-11-23 |
| SessionStart `additionalContext`, matchers `startup\|resume\|clear\|compact` | `hooks/session-start.sh` | docs |
| PreToolUse `permissionDecision: deny \| ask` | guards | docs + `tests/test-hooks.sh` |
| Marketplace `dependencies` with `allowCrossMarketplaceDependenciesOn` | `.claude-plugin/marketplace.json` | docs; install behaviour when a dependency's marketplace is not added: not verified |
| Artifact `quickstart` with `intent: "design"` / `"other"`, Design and Design System types | `skills/design-studio` | tool description, 2026-11-23 |

## Known operational limits

- **Fable usage limit (seen 2026-11-23):** a subagent pinned to `model: fable` fails with HTTP 429 when the account's Fable limit is reached. Documented fallback: `CLAUDE_CODE_SUBAGENT_MODEL` with `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (overrides agent frontmatter; from the sub-agents docs summary, exact behaviour not yet tested), plus loading phase skills directly instead of the model-pinned commands. Watch the changelog for a native model-fallback setting.

## Candidates

- **Plugin evals** (`claude plugin eval`, cases in `evals/`): a suite that checks phase 1 asks one question per message and writes nothing outside the brief, and that `/task` refuses without a milestone plan.
- **Monitors** (`monitors/monitors.json`): not needed yet.
- **Workflows** (`workflows/` in a plugin): a saved release-debug workflow for `/5-release` when the user opts in with `use a workflow`.
