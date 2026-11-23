# Project Scaffolder

**A sequential, multi-agent way to build a product with Claude Code — from the first question to the release tag.**

Most agent sessions fail the same way: the agent starts building before the problem is understood, designs while it codes, and declares victory without proof. Project Scaffolder makes the order of work explicit and enforces it. Five phases, one kind of work each, one approved artifact to leave each one — with fixed models per role, a second-brain wiki, and a `secrets/` folder that never leaves your machine.

```
1 BRAINSTORM ──► 2 FOUNDATION ──► 3 DESIGN ──► 4 BUILD ──► 5 RELEASE
 questions only   second brain     design       platform,    1–100 verification
 (+ research)     skills, agents   system,      milestones,  rounds, gate,
                  secrets/         artboards,   tasks with   version, tag
                                   Artifacts    bug hunts
```

## What's new in 4.1

| | |
|---|---|
| **Three loops** | Release verification in 1, 5, 10 or 100 rounds · `/improve`, 10 to 100 improvement iterations with your checkpoints · `/research` on GitHub, Reddit, Hacker News and the web. Each asks first, shows its cost, keeps a resumable journal and runs as a plugin workflow. |
| **`/todo` notebook** | Advice, loose ideas, bug hunts asked for and never run, deferred findings — one prioritised line each in `wiki/todo.md`. Milestone plans start from it. |
| **You always see where you are** | A session banner (phase, next command, model check), a command gate that refuses a command typed too early and says which one to run, a script-backed `/phase-status`. None of it costs model tokens. |
| **Leaner sessions** | Commands no longer switch the model (that re-read the whole conversation without the cache); counting, linting and status come from bundled scripts that print short reports; generated projects get a lean `CLAUDE.md` and path-scoped rules. |
| **Stricter verification** | Every critical or high finding is attacked by a second agent before it counts; the guards fail closed; hooks follow the session into worktrees. |
| **Secrets guarded on every way out** | The guard now also covers MCP connectors (GitHub, mail, docs, chat, hosting), web requests, messages to other sessions, every file an Artifact publish carries, and what a commit or push would record. It recognises keys in `.env` lines, URLs, JSON, Markdown and free text, and its refusals name the file and variable — never the value. |
| **Fable out of quota** | A planning or verification agent that hits the Fable usage limit is offered on Opus now or after the reset, and the step is queued in `/todo` to be repeated on Fable. |

Full list: [CHANGELOG.md](CHANGELOG.md).

## Performance

Measured on the plugin itself, 4.0.0 against 4.1.0 (tokens estimated as bytes / 4).

| Measure | 4.0.0 | 4.1.0 |
|---|---|---|
| Context loaded on every message (descriptions the model sees) | 2,291 tokens | **1,805 tokens** (−21%) |
| Model switch when a command starts (full uncached re-read of the conversation) | 18 commands | **none** |
| `/phase-status` | 1,834 tokens | **345 tokens (−81%)** — a script reads the files |
| Status, statistics and wiki checks | read by the model | counted by bundled scripts, short output |
| Hook and script regression tests | 57 | **217** |
| Behaviour evals of the gates (`claude plugin eval`) | — | 3 cases |
| Quality score on a micro-project, blind Fable review (rubric below) | **57**/100 | **81**/100 |

The score comes from a blind review by Fable 5.2: both versions, anonymised, were walked through the same micro-project (a small water-intake web app with a weather API key in `secrets/`, five release rounds, ten improvement iterations) and scored on twelve weighted dimensions: phase gates, token economy, project understanding, memory, visibility, design flow, verification and loops, research, secrets, platform fit, clarity, robustness. 4.1 scored higher on all twelve. A separate Fable 5.2 pre-release review found no blocker; its findings on the secrets guard were fixed before this release.

The phase commands load more text than in 4.0 (about +25% to +60% per phase command), because they now carry the loops, the resume logic and the no-workflow fallbacks. That cost is paid once per phase; the model-switch re-read it replaces was paid on every command.

## Install

```
/plugin marketplace add jakubkrehel/skills
/plugin marketplace add ConardLi/garden-skills
/plugin install project-scaffolder --marketplace valsecchi75/project-scaffolder
```

The first two lines add the marketplaces of the two design plugins this one depends on (`interfaces` and `web-design-skills`), so they are installed with it. Then run `/setup-check`: it checks Git Bash, hooks, workflows, the fallback model, the Artifact tool, auto memory and the companion plugins, and prints the exact fix for anything missing.

Requirements: Claude Code 2.1.323 or later, and bash (Git Bash on Windows) for the hooks. The guards fail closed: without bash they refuse every shell, file-writing and outward call, and `/setup-check` says how to fix it. Updating from an earlier install: `claude plugin update project-scaffolder`.

## The five phases

| Phase | Command | What happens | Leaves with |
|---|---|---|---|
| 1 | `/1-brainstorm` | Questions only, one topic at a time: problem, users, outcome, scope, constraints, business, brand, risks, working agreements. No solutions, no stack; the brief is drafted as you answer, and solutions you volunteer are parked for the phase that decides them. Optional research rounds come back as questions. | `docs/brief/BRIEF.md` approved by you |
| 2 | `/2-foundation` | The project's second brain: `raw/` sources, the wiki, the `CLAUDE.md` schema, path-scoped rules, project skills, the agent roster, a `secrets/` folder. | Structure check green, your confirmation |
| 3 | `/3-design` | Design system first. Then each section as artboards (all states, all viewports), an anti-slop audit and a measured contrast and type check, your approval, and one Artifact page per section (a self-contained local page when the Artifact tool is unavailable). | Every section approved in `wiki/design/registry.md` |
| 4 | `/4-build` | Platform decision (you choose), milestone plans, then `/task` for each activity: plan → build → verify → bug hunt → persona test. `/improve` between milestones. | Milestones closed with evidence |
| 5 | `/5-release` | A green full test run, then 1, 5, 10 or 100 verification rounds as you choose, fixes, the release gate, version, changelog, tag. Never pushes. | Release report approved, tag created |

**The gates are mechanical, not just advice.** `.scaffolder/phase` records the current phase. A hook refuses writes that belong to a later phase (in phase 1 only the brief and `raw/`; in phases 2 and 3 no application code), and another refuses a phase or build command typed too early, before it loads: also `/2-foundation` before you approve the brief and `/4-build` before you close the design phase. Interaction modes (Normal, Autopilot, Autonomous) apply from phase 4 and never skip a gate.

## What you see while you work

- **Session banner:** every session in a phase-managed project opens with one line shown only to you: phase, next command, and whether the session runs the model the flow is designed for.
- **Command gate:** `/4-build` in the brainstorm or before the design phase is closed, `/2-foundation` before the brief is approved, `/task` or `/improve` before phase 4 — refused, with the command to run instead.
- **`/phase-status`:** what is approved, what blocks the gate, what you can run now, the next command.
- **`/todo`:** what is waiting, P1 first and oldest first, with flags for items left too long.
- **Compaction:** before every compaction a hook writes the phase, the plan, the handoff's age and the uncommitted files to `.scaffolder/compact-snapshot.md`; the session after it reads that file first. Plain `/compact` is enough.
- **Who starts what:** phase, milestone, loop and session commands are typed by you; Claude names them as the next step. A loop offered inside a phase starts only after you answer its cost question.

## Agents and models

The routing is fixed in each agent's definition, so it holds even when the orchestrator forgets.

| Agent | Model | Job |
|---|---|---|
| `architect` | Fable | Platform decision, milestone and task plans |
| `verifier` | Fable | Checks a task against its plan with fresh evidence |
| `bug-hunter` | Fable | Proves defects: on the diff after every task, across the project before release |
| `design-critic` | Fable | Slop audit, contrast and type accessibility, design-system fidelity |
| `builder` | Opus | Implements an approved task plan |
| `designer` | Opus | Design-system files and artboards |
| `sweeper` | Sonnet | Full suites, refutation of findings, project-wide sweeps |
| `persona-tester` | Sonnet | Walks a changed flow as one end user, without the project's internals |

The flow is designed for a Fable main session; the banner says when the session runs another model. Every agent sets its own effort. Haiku is not used.

**When Fable is unavailable.** For overload errors, add a fallback chain to your own `~/.claude/settings.json` (a plugin cannot set it): `"fallbackModel": ["opus", "sonnet"]`. A fallback chain does not switch on a usage limit: when a Fable agent stops on its quota, the flow asks whether to wait for the reset or re-run the agent on Opus now, and queues a `/todo` item to repeat that step on Fable. Work verified on another model is always labelled as such.

## Loops

Each loop asks every question first (a running loop cannot ask), shows a cost estimate and its caps, keeps a journal so a new session can resume it, and runs as a plugin workflow whose progress and per-agent tokens show in `/workflows`.

| Loop | Command | One round | Caps and stops | Journal |
|---|---|---|---|---|
| Release verification | `/5-release`, step 3 | 5 Fable hunters (security, reliability, accessibility, performance, regression); Sonnet tries to refute each finding | 1, 5, 10 or 100 rounds; stops after two dry rounds, or for a fix of a confirmed critical or high finding | `docs/release/v<version>-rounds.md` |
| Improvement | `/improve` (phase 4, between milestones) | one proposal, built in its own git worktree, then a verifier tries to refute it | 10 to 100 iterations of at most 150 lines; checkpoints for your approval; stops on a regression; nothing reaches your checkout until you approve the final diff | `logs/improve/<run>/journal.md` |
| Research | `/research <topic>` (phases 1 to 3) | GitHub, Reddit, Hacker News and web reads, then a critic picks the next queries | 1, 3 or 5 rounds; sources are untrusted text, saved with citations in `raw/research/` | `raw/research/<slug>/` |

On a subscription, 100 rounds or iterations can use up the weekly allowance. Workflows are off on Pro until Dynamic workflows is turned on in `/config`; without them each loop runs the same steps from the main session, with a lower cap, and `/setup-check` says which case applies.

## The project notebook — `/todo`

`wiki/todo.md` is the inbox of everything that could go into the project but is not planned yet, one line per item:

```
- [ ] T-007 | P1 | debug | 2026-11-23 | Bug hunt on offline sync, asked in M1, never run | from: user
```

Claude adds to it when you say "later" or give advice outside the current task, when a bug hunt or a release defers a finding, when a persona test reports a friction, and when a session ends with loose ends. `/todo` shows it through a read-only script (so the file never fills the context), `/todo triage` asks you to sort it, `/milestone-plan` takes the open P1 and P2 items as candidates, and `/milestone-close` reconciles them. Lines are never deleted: they are planned, done with evidence, or dropped with a reason.

## The second brain

Each project follows Andrej Karpathy's [LLM-wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

- `raw/` — immutable sources: the original brief, references, research.
- `wiki/` — maintained by the agents: index first, one concept per page, citations, contradictions marked instead of overwritten, an append-only log.
- `CLAUDE.md` — the schema: a short index of facts and paths.

`/wiki-ingest` adds a source and updates every page it touches. `/wiki-lint` measures every page against a token budget, then finds contradictions, orphans, broken links, missing pages, stale pages and drift from the code. Lessons from tasks propagate into the project skills (Synapse). Folder conventions live in path-scoped rules (`.claude/rules/`) that load only when that folder is touched; a code-map skill tells every agent where code lives; a `verify` skill holds the checks Claude runs before each commit.

## Secrets

`secrets/` holds hand-over files with API keys. The agent may read them to use a key locally; nothing in there is ever published. The secrets guard blocks:

- committing while the folder is not git-ignored, or is tracked or staged;
- a commit whose changes contain a value, and a push while a committed file contains one;
- copying a value into another file (`.env` files that git ignores excepted) or inlining it in a shell command;
- publishing a value or a `secrets/` file as an Artifact — page, supporting files and assets included;
- sending a value or a `secrets/` file through an MCP connector (GitHub, mail, docs, chat, hosting), a web request, or a message to another or a cloud session.

A value is recognised in `NAME=value` lines, in URLs (`user:password@`, key-like path and query parts), in JSON, Markdown and free text (long key-like tokens), and in PEM or base64 lines; identifiers such as `…_HOST`, `…_REF` or `…_EMAIL`, hostnames and plain URLs are not treated as secrets. Uploading a file from `secrets/` with a shell command asks first; a plain `cp` out of `secrets/` is not parsed, which is why a commit or push re-checks the content. Keys are best loaded inside the command that needs them (`set -a; . secrets/<service>.env; set +a; <command>`), so the value never enters the conversation: anything Claude reads lands in the local session transcript. Phase 2 also offers an opt-in rule that blocks reads of `secrets/` entirely. It is a guard rail, not a data-loss-prevention system.

## Design

Design starts from a design system — one of your Design System artifacts, or a new one — and every section is drawn as artboards before any code exists.

| Step | Skill |
|---|---|
| Design system and artboard composition | `web-design-skills:web-design-engineer` (ConardLi/garden-skills) |
| Anti-slop gate while composing, and the audit | `no-ai-design-slop`, `audit-ai-design-slop` (MengTo/Skills, bundled) |
| Typography, color, layout, accessibility, final review | `interfaces:better-*` (jakubkrehel/skills) |

Approved sections are saved as Artifact pages, one per section, linked from the design registry; without the Artifact tool each section is a self-contained page under `design/<section>/`. Every contrast ratio is computed by a bundled WCAG script, never estimated, and when browser tools are connected the critic also renders each page. Build ports the sections one to one; a missing element stops the task and reopens the section with `/3-design --section <name>`.

## Commands

**Phases**

| Command | |
|---|---|
| `/1-brainstorm [idea]` | Questions only, until the brief is approved |
| `/2-foundation [--upgrade]` | Second brain, skills, agents, secrets. `--upgrade` migrates a v3 project |
| `/3-design [--section <name>]` | Design system, artboards, critique, Artifacts |
| `/4-build [--status]` | Platform, milestone plan, build status |
| `/5-release [version]` | Verification rounds, gate, version, tag |

**Inside a phase**

| Command | |
|---|---|
| `/task <what> [--parallel <#,#>]` | One piece of build work through the full pipeline; `--parallel` builds two or three independent activities at once, each in its own worktree |
| `/milestone-plan [Mn]` · `/milestone-close [Mn]` | Plan and close a milestone |
| `/bug-hunt [--diff \| --area \| --all]` | Look for unreported defects (read-only) |
| `/fix-bug <symptom>` | Reproduce, root-cause, fix, prove, record |
| `/test-sweep [scope]` | Every test, lint, type check, build and audit |
| `/improve [resume <run-id>]` | Improvement loop, 10 to 100 iterations, final diff for your approval |
| `/research <topic>` | Cited research in rounds; in phase 1 it returns questions |

**Service**

| Command | |
|---|---|
| `/todo [add <text> \| done <id> \| triage]` | The project notebook, by priority |
| `/session-start [focus]` · `/session-end [--commit]` | Open and close a session; the start also checks whether Claude Code changed |
| `/phase-status` | Where the project is and the next command |
| `/wiki-ingest <source>` · `/wiki-lint` | Feed and check the second brain |
| `/decision <title>` · `/log-error <title>` | Record a decision or an understood error |
| `/skill-new <area>` · `/skill-map` | Create a project skill; show the skill network |
| `/pipeline-stats [--week]` | Is the pipeline helping? |
| `/setup-check` | Dependencies, Git Bash, hooks, workflows, fallback model, Artifact, memory, secrets; exact fixes |

## Upgrading

- **From 4.0:** projects keep working; `/4-build` writes the new `verify` skill when it is missing. Path-scoped rules, the code map and the shared settings come with new projects; copy them from `skills/foundation/templates/` if you want them in an existing one.
- **From v3:** a breaking change, the 19 v3 commands are replaced. Open a v3 project and the session start tells you; `/2-foundation --upgrade` adds the phase state, moves project skills to `.claude/skills/`, renames Execution Docs to milestone plans, creates `raw/`, `secrets/` and the agent roster, and removes the duplicated hook entries after asking.

## Development

`CLAUDE.md` holds the maintainer rules; `wiki/` the plugin's own development memory, including the Claude Code changelog review done at the start of every session. Before committing: `claude plugin validate .` and `bash tests/test-hooks.sh`. Before a release, the behaviour evals in [`evals/`](evals/README.md) check the gates end to end in real sessions.

## Credits

Methodology by [agent1.it](https://agent1.it). Built on ideas from Andrej Karpathy's LLM-wiki gist and [obra/superpowers](https://github.com/obra/superpowers). Bundled and depended-on skills: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

MIT.
