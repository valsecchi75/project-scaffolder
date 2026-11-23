---
description: Setup check - Git Bash, hooks, workflows, fallback model, Artifact, auto memory, companion plugins, agents, project phase and secrets. Read-only; prints exact fixes.
context: fork
agent: general-purpose
model: sonnet
background: false
---

You run in a fresh subagent with no conversation history. Check what project-scaffolder depends on and report. Change no file, install nothing, edit no setting: every fix is for the user to apply.

**How to read settings.** A key can sit in any of these files, highest precedence first: managed (`C:\Program Files\ClaudeCode\managed-settings.json`, `/Library/Application Support/ClaudeCode/managed-settings.json`, `/etc/claude-code/managed-settings.json`), `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`. Read the ones that exist. Also read the environment (`env` in the shell). Server-managed settings are not on disk: when a check looks fine but the feature still misbehaves, say that an organization policy may be the cause. Use the Bash tool if you have it, otherwise PowerShell.

**Machine**

1. **Claude Code version**: `claude --version`. The plugin needs 2.1.323 or later (`engines` in its manifest). Older → `WARN`, fix: `claude update`.
2. **Git Bash** (Windows only; elsewhere `OK` if `bash --version` works). Every hook runs as `bash "<plugin>/hooks/<name>.sh"`. `OK` when `bash --version` works from the Bash tool, or `CLAUDE_CODE_GIT_BASH_PATH` names an existing `bash.exe`, or `C:\Program Files\Git\bin\bash.exe` exists. Otherwise `MISSING`: without Git Bash the hooks run in PowerShell, where the bash scripts fail, and the three guards fail closed (`onFailure: "block"`): every Bash, PowerShell, Write, Edit, NotebookEdit, Artifact, MCP, WebFetch, WebSearch and SendMessage call is refused with `PreToolUse:<Tool> hook error: … blocking because onFailure is "block"`. Fix: install Git for Windows, or set `CLAUDE_CODE_GIT_BASH_PATH` to the `bash.exe` path in the `env` block of `~/.claude/settings.json`, then start a new session. The same refusal with Git Bash present means a broken install: `claude plugin update project-scaffolder` (or reinstall); as a last resort `/plugin disable project-scaffolder`.
3. **Hooks on**: `FAIL` if any file sets `"disableAllHooks": true`, or managed settings set `"allowManagedHooksOnly": true` without force-enabling this plugin in managed `enabledPlugins`. Then no guard runs and the phase gates are instructions only. Fix: remove the key (managed keys: ask the administrator).
4. **Companion plugins** enabled, checked with `claude plugin list`: `interfaces@interfaces` and `web-design-skills@garden-skills`. Missing → `MISSING` with:
   ```
   claude plugin marketplace add jakubkrehel/skills
   claude plugin install interfaces@interfaces
   claude plugin marketplace add ConardLi/garden-skills
   claude plugin install web-design-skills@garden-skills
   ```
5. **Bundled skills and agents**: skills `project-scaffolder:no-ai-design-slop` and `project-scaffolder:audit-ai-design-slop`; agents architect, builder, designer, verifier, bug-hunter, design-critic, sweeper, persona-tester. Copies of the same skills loaded from elsewhere (`~/.claude/skills/`, other plugins) → `WARN` with their paths; removing them is the user's choice.

**Session features** (each optional: say what degrades, never present the fallback as equivalent)

6. **Workflows** (the three loops: `/project-scaffolder:release-rounds` in `/5-release`, `improve-segment` in `/improve`, `research-rounds` in `/research`). Off when `CLAUDE_CODE_DISABLE_WORKFLOWS=1`, `"disableWorkflows": true` in any file, or `"enableWorkflows": false`. With no key at all: `WARN` "off by default on the Pro plan". Fix: turn on **Dynamic workflows** in `/config`. Degraded: the same loop runs as a sequential subagent loop from the main session; slower, and every round report enters the main context.
7. **Fallback model**: `fallbackModel`, or the `--fallback-model` flag. The highest-precedence file that sets it supplies the whole chain; files do not merge. Unset → `WARN`: when Fable is overloaded the request fails and the user retries or switches by hand. Fix (a plugin cannot set it): add `"fallbackModel": ["opus"]` to `~/.claude/settings.json`. Also `WARN` when `availableModels` leaves out `fable`, `opus` or `sonnet`. Say plainly: a turn served by the fallback is not Fable planning or verification, and a report produced that way must say so.
8. **Artifact** (phase 3 publishes one page per section). Off when `"enableArtifact": false` or `"disableArtifact": true` in any file, `CLAUDE_CODE_DISABLE_ARTIFACT=1`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` set, `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX` or `CLAUDE_CODE_USE_FOUNDRY` set, `ANTHROPIC_API_KEY` or an `apiKeyHelper` setting present (they take precedence over the claude.ai login, and an API-key session cannot publish), or Claude Code older than 2.1.281. The supported surfaces are the CLI and the desktop app; the VS Code extension is not listed, so `WARN` that it may lack the tool. Report the cause. Fix for a login cause: remove the competing credential, then `/login` with "Claude account with subscription". Degraded: phase 3 runs in Local mode, with one self-contained page per section at `design/<slug>/index.html`, recorded by path in `wiki/design/registry.md`.
9. **Auto memory** (personal notes outside the repo; also required by any agent that declares `memory`). Off when `"autoMemoryEnabled": false` or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` → `WARN`. Fix: the toggle in `/memory`. The project wiki does not depend on it.
**Current project** (skip when there is no `.scaffolder/` folder)

10. `.scaffolder/phase` holds one of brainstorm, foundation, design, build, release.
11. `secrets/` exists, `git check-ignore -q secrets/probe` succeeds, `git ls-files secrets` is empty; `.env.example` lists names without values.
12. Project skills live in `.claude/skills/` (a top-level `skills/` folder means `/2-foundation --upgrade`).
13. No entries in `.claude/settings.json` that duplicate the plugin's guard or format hooks.

**Report** (this is all the main conversation receives): one line per item, `N. Name: OK | WARN | MISSING | FAIL - finding`, then a **Fixes** list with the exact command or settings line for each item that is not `OK`, most severe first. No narration of the steps you ran; at most 25 lines.
