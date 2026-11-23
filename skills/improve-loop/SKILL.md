---
name: improve-loop
description: Use when /improve runs, or when an improvement loop reaches a checkpoint, is resumed, or ends with kept changes waiting for the user's approval.
---

# Improvement loop

10 to 100 contained iterations. Each one looks through one lens, proposes ONE improvement, builds it in its own git worktree, and lets a second agent try to refute it. Kept work is a commit on a branch `improve/<run>/<id>`; the user's checkout is not touched until the user approves the final diff.

The main session asks every question and owns the journal. The `project-scaffolder:improve-segment` workflow (`workflows/improve-segment.js`) runs one segment between two checkpoints and cannot ask anything (workflows have no mid-run input). This skill relies on AskUserQuestion: ask even in auto mode, never guess an answer.

Designed for a Fable main session; the agents keep their own models (architect and verifier Fable, builder Opus, sweeper Sonnet). Do not switch the session model.

## 1. Pre-flight (refuse instead of improvising)

- **Phase.** Runs in phase 4 (`build`, between milestones) or in a git repository without `.scaffolder/phase`. Phases 1 to 3 would leak build work; in phase 5 the release gate comes first.
- **Clean tree.** `git status --porcelain --untracked-files=no` must be empty: the worktrees start from a commit, so uncommitted changes would not be part of the base. Ask the user to commit or stash them. Untracked files (the journal, `logs/`) do not block, but they are not in the base either.
- **A runnable check.** Collect the check commands (build, tests, lint, type check, accessibility) from `wiki/tech-stack.md` or `CLAUDE.md`. None: stop and ask for one. A loop without a pass/fail check is not run.
- **Open run.** `/improve resume <run>`, or a `logs/improve/*/journal.md` with `status: open`: offer to resume it (section 5) before starting a new one.

## 2. Questions, cost, launch

First AskUserQuestion call, four questions:

| Header | Question | Options |
|---|---|---|
| Iterations | How many iterations at most? | 10 · 25 · 50 · 100 |
| Focus | Which lenses? (multiSelect) | Security · Performance + tokens · Accessibility · Design + features |
| Scope | What may change? | Whole project · Application code · Docs and wiki · Agent setup (CLAUDE.md, .claude/, wiki) |
| Approval | When do I stop for you? | Every 5 · Every 10 · Only at the end |

The Approval options say in their descriptions that iteration 5 is always a checkpoint, whatever the choice (the cost check below): `Every 5` "at 5, 10, 15 …", `Every 10` "at 5, then 15, 25 …", `Only at the end` "once at 5 to check the cost, then not until the end".

Map Focus to dimensions (`security`, `performance`, `tokens`, `accessibility`, `design`, `features`) and Scope to path prefixes (`[]` for the whole project; application code from `wiki/architecture.md`). Always out of scope, whatever the answer: `raw/`, `docs/brief/`, `.scaffolder/`, `logs/`, `wiki/log.md`, `wiki/product/decisions.md`, any `secrets/` folder and any `.env`, `.env.*` or `.envrc` file at any depth (`.env.example` stays editable), and the loop's own permissions: `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/`, `.mcp.json`. A change there is a decision for the user, not an iteration.

Then show the estimate and the caps in chat, before the second question:

- 3 agents per iteration plus 1 baseline per segment; agent cap = 3 × N + segments, with segments = 1 + ⌈(N − 5) / 5⌉ for "Every 5", 1 + ⌈(N − 5) / 10⌉ otherwise (100 iterations, "Every 10": cap 311).
- Rough size: about 0.3M tokens per iteration (mostly cached input), so 10 ≈ 3M, 100 ≈ 30M. Measured tokens appear in `/workflows`, which the user sees and Claude does not: at each checkpoint re-estimate from agents used and invite the user to compare.
- On a subscription, 50 or 100 iterations can use up the weekly allowance; with an API key it is per-token cost. On Pro, Dynamic workflows must be on in `/config`. Above 25 agents a `Large workflow` warning appears: it is advisory.
- Each iteration changes at most 150 lines; a candidate outside scope or over the cap is discarded unseen by the user. Scope and size are judged on the verifier's own `git diff`, not on the builder's report.

**Permissions.** Workflow agents use the session's permission rules, and a run pauses at every agent permission prompt. In Manual mode, without allow rules, each agent stops at its first edit, git or check command and waits for the user, so the segment is not unattended. Show the rules the agents need, for `.claude/settings.local.json` (personal; Claude Code reloads it without a restart). Write the Edit path absolute, `//` plus the project root in POSIX form (`//c/Users/...` on Windows): a single `/` anchors at the primary working directory, which in a worktree is the worktree itself.

```
"Bash(git checkout --detach *)", "Bash(git switch -c improve/*)", "Bash(git add -A)", "Bash(git commit -m *)",
"Bash(git rev-list *)", "Bash(git rev-parse *)", "Bash(git diff *)", "Bash(git show *)", "Bash(git log *)",
"Edit(//<project root>/.claude/worktrees/**)", plus "Bash(<command>)" for each check and for the install command
```

The Edit rule pre-approves edits only inside the agents' worktrees, never in the user's checkout. `Bash(git commit -m *)` works in any directory, so the rules are removed at the end (section 6). Leave them out if `.claude/settings.local.json` is tracked in git: the edit would dirty the tree and the rules would wait for folder trust.

Second AskUserQuestion, two questions. Header `Launch`: "Launch with these caps" · "Only the first 5, then re-estimate" · "Cancel". Header `Permissions`: "Add these rules locally" (unless Launch is Cancel, append them to `permissions.allow`; the write prompts because `.claude/` is a protected path, and that prompt is the user's approval) · "I'll answer the prompts" (fine in auto or bypass mode; in Manual mode, expect to stay at the keyboard).

The first segment always stops after 5 iterations at an approval checkpoint, whatever the policy, so the cost estimate is checked early. Later checkpoints count from there: 10, 15, 20 … for "Every 5"; 15, 25, 35 … for "Every 10"; none for "Only at the end".

## 3. Journal and segments

Create `logs/improve/<run>/journal.md`, `<run>` = `imp-<YYYYMMDD>-<n>`:

```
# Improvement loop <run>
status: open
base: <sha>  tip: <sha>  next: 1  total: <N>  agents-used: 0  agent-cap: <cap>
focus: <dims>  scope: <prefixes or whole>  policy: <every 5 | every 10 | end>  permissions: <local rules | prompts>
checks: <command>; <command>

| # | lens | outcome | title | value | risk | lines | commit | reason |
```

Launch the workflow `project-scaffolder:improve-segment` with `args` as a JSON object (not a string): `run, base, tip, start: next, end, total, focus, scope, checks, agentsLeft: cap − used, maxLines: 150, tried` (the `<id> <title>` of earlier rows, at most 40). `agentsLeft` is a number; below 4 the segment returns `agent-cap` without starting an agent. `end` = the next approval checkpoint under the policy; the script runs at most 10 iterations per segment whatever `end` says, so the journal is never more than one segment behind. A launch result with `error` set failed the script's syntax check and never ran: report it and stop. Otherwise the launch is "started": wait for the result, do not poll.

What one iteration does (the script is the source of truth): a lens chosen by iteration number (dimension × angle), a read-only proposal by `architect`, a build by `builder` in a worktree that commits only when every check passes, then `verifier` in another worktree tries to refute it against the plan and the checks. Kept only when the verifier says keep, every check passes, there is no regression, every changed file is in scope and the candidate is exactly one commit whose parent is the accepted tip (the verifier's `git rev-list --parents`), so `base..tip` stays a straight line of kept commits. The run stops early on a red baseline, on two regressions in a row, after three iterations with nothing worth doing, at the agent cap, or when a token target the user set for the turn (`+500k`) is nearly spent (status `budget`).

## 4. Checkpoint

When a segment returns:

1. Check the returned `tip` yourself before trusting it: `git rev-list --reverse <base>..<tip>` must list exactly the commits of every `kept` row (journal plus this segment), in order; a short sha matches by prefix. Any difference: do steps 2 and 3 without updating `tip`, show both lists and stop; no relaunch until the user decides.
2. Append one row per iteration to the journal; update `tip`, `next`, `agents-used`.
3. Remove the returned worktrees that still exist with `git worktree remove --force <path>` (unchanged ones are already gone; `git worktree unlock` first only if git says it is locked). Then run `git branch -D` on the branches of iterations that were not kept: git refuses while a worktree still has the branch checked out, and the guard asks the user to approve each `-D`.
4. Report in chat: kept and discarded counts, the kept titles with value and risk, the status, agents used against the cap and the new estimate for the rest.
5. Act on the returned `status`:

| status | Next step |
|---|---|
| `segment-done`, its last iteration (`next` − 1) is not an approval checkpoint | Relaunch at once with the new `start`, `tip`, `agentsLeft`; no question |
| `segment-done`, its last iteration is an approval checkpoint | Ask (header `Checkpoint`): "Continue" · "Change focus or scope" · "Stop and review" |
| `done`, `dry`, `agent-cap`, `budget` | No relaunch: section 6 |
| `baseline-red`, `regression` | Stop, show the evidence; no relaunch until the user decides |
| `bad-args` | Fix the listed `missing` args and relaunch; never twice in a row |

## 5. Resume

Same session, run interrupted: relaunch with the run's `resumeFromRunId`. Otherwise read the journal: `next` and `tip` are the state; a branch `improve/<run>/<id>` with no journal row is not trusted and is deleted. Relaunch from `next`.

## 6. Final report and approval

At the cap, or on "Stop and review": rank the kept iterations by value (high first), then risk (low first), then lines (fewer first). Show the ranked table, `git diff --stat <base> <tip>`, and the full `git diff <base> <tip>` on request. Ask (header `Apply`): "Apply all kept" · "Apply some (name the ids)" · "Keep branches, decide later" · "Discard all".

- Apply all: `git merge --ff-only <tip>` when HEAD is still `base`, else `git cherry-pick` the kept commits in order.
- Apply some: cherry-pick in order; a conflict stops the pick and is reported, never resolved silently.
- Then run the checks once more in the user's checkout, delete the run's branches that were not applied (unless kept for later), set `status: closed`, and append to `logs/pipeline/<today>.md` an `IMPROVE <run>` block with one `outcome` step line (iterations, kept, applied; pipeline-logger format).
- `permissions: local rules`: remove exactly the entries added at launch from `.claude/settings.local.json`, leaving every other rule. Keep them only if the user says so, for example with "Keep branches, decide later" and a resume planned.

## Fallback without workflows

If the Workflow tool is not in this session (workflows off on Pro, `disableWorkflows`, `CLAUDE_CODE_DISABLE_WORKFLOWS`), run the same iteration from the main session with the Agent tool: `project-scaffolder:architect`, then `project-scaffolder:builder` with `isolation: "worktree"`, then `project-scaffolder:verifier` with `isolation: "worktree"`, using the prompts and keep rules in `${CLAUDE_PLUGIN_ROOT}/workflows/improve-segment.js` (read it when running this fallback). Ask the same `Permissions` question first: background subagents bring every prompt to this session. Start each agent only after the previous one's completion notification, ask for the same short structured reports, and write the journal row after every iteration. Every report lands in this context, so offer at most 10 iterations and a checkpoint every 5.
