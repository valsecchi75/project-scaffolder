# Claude Code changelog — reviewed for the plugin

> last-verified: 2026-11-23

**Last changelog version reviewed: 2.1.330** (entries 2.1.321 to 2.1.330 read on 2026-11-23; checked again at the start of the v4.1.1 session, same day: no newer entry). Installed version at that check: 2.1.329.

Source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md. At the start of each session, read only the entries after the version above, then update this page (see `CLAUDE.md`).

Impact: `adopt` (use it now) · `adapt` (change the plugin) · `watch` (may matter later) · `no impact`.

## Reviewed entries

| Version | Change | Impact | Notes |
|---|---|---|---|
| 2.1.330 | `claude plugin install --json` gains fields; `/mcp` groups plugin servers | no impact | |
| 2.1.329 | `/code-review` reports only bugs and CLAUDE.md violations; cleanups moved to `/simplify` | adopt | `/5-release` offers `/code-review <last tag>..HEAD` and starts it on a yes (Claude can start it since 2.1.246) |
| 2.1.329 | A failing PreToolUse hook no longer blocks unless `onFailure: "block"` | adopt | v4.1.0: the three PreToolUse guards set `onFailure: "block"` (DEC-013); the other hooks stay fail-open |
| 2.1.329 | Scheduled tasks saved earlier must be rescheduled | no impact | |
| 2.1.328 | `network` field in plugin.json | adopt | Declared `raw.githubusercontent.com`, `github.com` |
| 2.1.327 | `claude plugin eval` keeps deny rules | watch | Eval suite for the phase gates is a candidate (see below) |
| 2.1.325 | `.claude/skills` in `--plugin-dir` plugins no longer load from a session started higher up | no impact | The plugin ships skills under `skills/` |
| 2.1.325 | `pluginDigests` deprecated | no impact | |
| 2.1.323 | `engines["claude-code"]` in plugin.json | adopt | Set to `>=2.1.323` |
| 2.1.323+ | Code Mode (experimental, `CLAUDE_CODE_EXPERIMENTAL_CODE_MODE`): Claude writes JavaScript that calls its tools; PreToolUse hooks still judge each call, and an erroring hook refuses only with `onFailure: "block"` | adopt | v4.1.1: `/setup-check` recommends it in terminal sessions (user settings only, not in the VS Code panel); composed-command cases in `tests/test-hooks.sh` |
| 2.1.323 | The plugin `agent` setting warns (deprecated) | no impact | Not used |
| 2.1.323 | Hook `decision: "block"` applies in more cases | no impact | Hooks use `permissionDecision` |
| 2.1.321 | Fable 5.2 (`claude-fable-5-2`), default model | adopt | Planning and verification agents use `fable` |

## Capabilities the plugin relies on

| Capability | Where | Verified |
|---|---|---|
| Agent frontmatter `model: fable \| opus \| sonnet`, `effort`, `disallowedTools`, `omitClaudeMd` (2.1.271+); the Agent tool's per-call `effort` (2.1.292+) and `isolation: "worktree"` | `agents/*.md`, `skills/cortex` | docs, 2026-11-23 |
| Skill `allowed-tools` pre-approving the bundled `scripts/*.sh`; `!` shell injection in `/phase-status` | `skills/*/SKILL.md`, `commands/phase-status.md` | docs |
| PreCompact hook stdout as summary instructions; `onFailure: "block"` (2.1.295+) on the guards | `hooks/` | docs + `tests/test-hooks.sh` |
| A project skill named `verify` runs before each commit (2.1.286+) | generated projects, `skills/cortex` | docs |
| Workflow script globals `args`, `agent()`, `parallel()`, `pipeline()`, `phase()`, `log()`; the guarded `budget` (the user's `+500k` target) | `workflows/` | docs; `budget` only in the bundled `/workflow-authoring` reference |
| Command frontmatter `argument-hint`, `disable-model-invocation`; `context: fork` + `model` only on read-only reports; no `name` (DEC-009) | `commands/*.md` | docs + `claude plugin validate` |
| Command names starting with a digit (`1-brainstorm`) | `commands/` | `claude plugin validate`, 2026-11-23 |
| SessionStart `additionalContext` plus top-level `systemMessage` (the banner), matchers `startup\|resume\|clear\|compact\|fork` | `hooks/session-start.sh` | docs |
| `UserPromptExpansion` block with `reason` (shown to the user), matcher on the namespaced command name | `hooks/command-gate.sh` | docs + `tests/test-hooks.sh` |
| Plugin workflows (`workflows/*.js`, pure-literal `meta` first), run as `/project-scaffolder:<name>` (DEC-010) | `workflows/` | docs, 2026-11-23 |
| `claude plugin eval` with `evals/<case>/prompt.md` and graders (DEC-012) | `evals/` | docs, 2026-11-23 |
| PreToolUse `permissionDecision: deny \| ask` | guards | docs + `tests/test-hooks.sh` |
| Marketplace `dependencies` with `allowCrossMarketplaceDependenciesOn` | `.claude-plugin/marketplace.json` | docs; install behaviour when a dependency's marketplace is not added: not verified |
| Artifact `quickstart` with `intent: "design"` / `"other"`, Design and Design System types | `skills/design-studio` | tool description, 2026-11-23 |
| Bash sandbox: macOS, Linux, WSL2 only (native Windows unsandboxed); `Read` deny rules merge into it and reach the command's child processes; hooks run outside it; how a denied file looks to a process is not documented | `skills/release` (build scan), `skills/foundation` (key reads) | docs https://code.claude.com/docs/en/sandboxing, 2026-11-23 |

## Known operational limits

- **Fable usage limit (seen 2026-11-23):** a subagent pinned to `model: fable` fails with HTTP 429 when the account's Fable limit is reached. Documented fallback: `CLAUDE_CODE_SUBAGENT_MODEL` with `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (overrides agent frontmatter; from the sub-agents docs summary, exact behaviour not yet tested), with the session itself on Opus (commands no longer pin a model, DEC-009). For overload errors, `fallbackModel` is a user or project setting the plugin cannot set: `/setup-check` detects it and recommends it.

## Candidates

- **Monitors** (`monitors/monitors.json`): not needed yet.
- **Mod pane** (`modules` in `hooks/hooks.json`): an optional phase pane for VS Code; the band above the prompt does not render there (DEC-011).
- Adopted since: plugin evals (`evals/`, DEC-012), workflows (`workflows/`, DEC-010) and `onFailure: "block"` on the guards (DEC-013).
