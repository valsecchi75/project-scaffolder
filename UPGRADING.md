# Upgrading a project from v3 to v4

For projects scaffolded with project-scaffolder 3.0.x. Version 4 is a breaking change: the 19 v3 commands are replaced by a five-phase flow, and the guards moved from files copied into your project to the plugin itself. The migration is one command, makes one commit, and can be reverted with `git revert`.

## 1. Update the plugin (terminal, once per machine)

```
claude plugin marketplace update project-scaffolder-marketplace
claude plugin update project-scaffolder@project-scaffolder-marketplace --scope user
```

In every project where the plugin is installed at project scope, from the project folder:

```
claude plugin update project-scaffolder@project-scaffolder-marketplace --scope project
```

Start a new Claude Code session afterwards: an update applies only after a restart. `claude plugin list` shows the installed version; this guide needs 4.1.3 or later.

## 2. Migrate each project (in a Claude Code session, once per project)

Open the project. The session start says it was scaffolded by v3 and has no phase state. Type:

```
/project-scaffolder:2-foundation --upgrade
```

No other prompt is needed: the command carries the whole procedure. It works in this order and asks before every change that is yours to decide.

1. **Looks before it touches anything.** Uncommitted work: it lists the files and asks whether to commit them first. It reads the handoff and the current Execution Doc and tells you what is in progress.
2. **Shows the plan and waits for your confirmation.**
3. **Migrates.**
   - Sets the phase to `build`.
   - Moves project skills to `.claude/skills/` and writes a code map skill.
   - Renames Execution Docs to milestone plans (`docs/plans/MILESTONE-<n>.md`).
   - Creates `raw/`, `secrets/` (git-ignored), `.env.example`, the agent roster and the notebook `wiki/todo.md`.
   - Rebuilds `CLAUDE.md` on the lean v4 template, keeping your working agreements and project facts.
4. **Asks about the old hooks.** v3 copied guard scripts into `.claude/hooks/`; the plugin now provides them, so they would run twice. It shows the entries and removes them only if you agree.
5. **Asks whether Claude may read `secrets/`.** Blocking reads is recommended: keys load in the shell inside the command that needs them, and their values never reach the conversation.
6. **Writes what changed into `wiki/handoff.md`**: the work that was in progress as the next step, the command map below and the new rules. Later sessions start from that file, so they know the v4 flow without this chat.
7. **Verifies the structure, commits `chore: upgrade to project-scaffolder v4`, and reports.**

Then run `/setup-check` once (Git Bash, hooks, companion plugins, optional features) and `/4-build`, which writes the project's `verify` skill and shows the current milestone.

### Optional: look first, change nothing

If you want a read-only picture before migrating, paste this as the first message:

```
This project was scaffolded with project-scaffolder 3.0.x and the plugin is now 4.1.3 or later.
Change no file. Check git status and read wiki/handoff.md, wiki/priorities.md and the current
Execution Doc in docs/phases/. Tell me in at most ten lines: what is in progress, whether the
tree is clean, which hooks .claude/settings.json wires, and which skills sit in skills/.
I will then type /project-scaffolder:2-foundation --upgrade myself.
```

## 3. What changes in daily use

| v3 | v4 |
|---|---|
| `/scaffold` | `/1-brainstorm`, then `/2-foundation` |
| `/kickoff` · `/wrap` | `/session-start` · `/session-end` |
| `/phase-doc` · `/phase-shift` | `/milestone-plan` · `/milestone-close` |
| `/plan` · `/implement` · `/task` | `/task` (plan, build, verify, bug hunt, persona test in one run) |
| `/review` | inside `/task` (verifier); Claude Code's `/code-review` for a diff |
| `/debug` · `/error` | `/fix-bug` (also `/bug-hunt` to look for bugs) · `/log-error` |
| `/test` | `/test-sweep` |
| `/gate` · `/ship` | `/5-release`; `/ship` is now Claude Code's own pull-request command |
| `/decide` | `/decision` |
| `/forge` · `/skills` | `/skill-new` · `/skill-map` |
| `/stats` | `/pipeline-stats` |
| `/wiki-gc` | `/wiki-lint` (and `/wiki-ingest` for new sources) |

New in v4, with no v3 equivalent:

- `/phase-status`: where the project stands and what you can run now.
- `/todo`: the notebook of things left for later.
- `/3-design --section <name>`: design a screen before it is built.
- `/improve`: an improvement loop between milestones.
- `/research <topic>`: cited research saved in `raw/research/`.
- `/setup-check`: what the plugin depends on, with exact fixes.

Three rules are new, and the hooks hold them mechanically:

- **Build work goes through `/task`** against an approved milestone plan. A task without a plan is refused, unless you pass `--unplanned`.
- **Interface work needs an approved design.** A missing one stops the task and opens `/3-design --section <name>`.
- **Keys never leave `secrets/`.** A value copied into a file, a command, a commit, an Artifact or an online service is blocked, and the release gate checks that none ships in the build.

Model routing is fixed: Fable plans and verifies, Opus builds, Sonnet re-checks and mass-tests. The full list of changes is in [CHANGELOG.md](CHANGELOG.md).

## If something goes wrong

- **Every tool call is refused with a hook error.** Git Bash is missing or the install is broken: `/setup-check` gives the fix; as a last resort, `/plugin disable project-scaffolder`.
- **The command says the project already follows the phase flow.** `.scaffolder/phase` exists, so there is nothing to migrate: run `/phase-status`.
- **You want the old state back.** `git revert` the upgrade commit. The plugin's v4 commands stay; the project files return to v3.
