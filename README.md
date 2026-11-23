# Project Scaffolder

**A sequential, multi-agent way to build a product with Claude Code — from the first question to the release tag.**

Most agent sessions fail the same way: the agent starts building before the problem is understood, designs while it codes, and declares victory without proof. Project Scaffolder makes the order of work explicit and enforces it. Five phases, one kind of work each, one approved artifact to leave each one.

```
1 BRAINSTORM ──► 2 FOUNDATION ──► 3 DESIGN ──► 4 BUILD ──► 5 RELEASE
 questions only   second brain     design       platform,    whole-project
                  skills, agents   system,      milestones,  debug, gate,
                  secrets/         artboards,   tasks with   version
                                   Artifacts    bug hunts
```

## Install

```
/plugin marketplace add jakubkrehel/skills
/plugin marketplace add ConardLi/garden-skills
/plugin install project-scaffolder --marketplace valsecchi75/project-scaffolder
```

The first two lines add the marketplaces of the two design plugins this one depends on (`interfaces` and `web-design-skills`), so they are installed with it. Then run `/setup-check`.

Requirements: Claude Code 2.1.323 or later, and bash (Git Bash on Windows) for the hooks. The guards fail closed: without bash they refuse every shell and file-writing call, and `/setup-check` says how to fix it.

## The five phases

| Phase | Command | What happens | Leaves with |
|---|---|---|---|
| 1 | `/1-brainstorm` | Questions only, one topic at a time: problem, users, outcome, scope, constraints, business, brand, risks, working agreements. No solutions, no stack; the brief is drafted as you answer, and solutions you volunteer are parked for the phase that decides them. | `docs/brief/BRIEF.md` approved by you |
| 2 | `/2-foundation` | The project's second brain: `raw/` sources, the wiki, the `CLAUDE.md` schema, project skills, the agent roster, a `secrets/` folder that never leaves your machine. | Structure check green, your confirmation |
| 3 | `/3-design` | Design system first. Then each section as artboards (all states, all viewports), an anti-slop audit and a measured contrast and type check, your approval, and one Artifact page per section (a self-contained local page when the Artifact tool is unavailable). | Every section approved in `wiki/design/registry.md` |
| 4 | `/4-build` | Platform decision (you choose), milestone plans, then `/task` for each activity: plan → build → verify → bug hunt → persona test. | Milestones closed with evidence |
| 5 | `/5-release` | A green full test run, then 1, 5, 10 or 100 verification rounds as you choose (five hunters, every finding re-checked), fixes, the release gate, version, changelog, tag. Never pushes. | Release report approved, tag created |

**The gates are mechanical, not just advice.** `.scaffolder/phase` records the current phase and a hook refuses writes that belong to a later one: in phase 1 only the brief and `raw/` can be written, in phases 2 and 3 no application code. Interaction modes (Normal, Autopilot, Autonomous) apply from phase 4 and never skip a gate.

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
| `persona-tester` | Sonnet | Walks a changed flow as one end user |

The flow is designed for a Fable main session. Commands do not switch the model (a switch would re-read the whole conversation without the prompt cache): the session banner says when the session runs another model and gives `/model fable`. Every agent also sets its own effort. Haiku is not used.

**When the Fable usage limit is reached**, the four Fable agents stop until the limit resets. To keep working on Opus in the meantime, start Claude Code with `CLAUDE_CODE_SUBAGENT_MODEL=opus` and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (forces every subagent to Opus, overriding the agents' frontmatter) and run the session on Opus. Verification done this way is weaker: rerun the bug hunt of a release on Fable once the limit resets. `/setup-check` also recommends a `fallbackModel` for overload errors.

## Loops

Three commands run many agents in rounds. Each one asks every question first (a running loop cannot ask), shows a cost estimate and its caps, keeps a journal so a new session can resume it, and runs as a plugin workflow (`release-rounds`, `improve-segment`, `research-rounds`) whose progress and per-agent tokens show in `/workflows`.

| Loop | Command | One round | Caps and stops | Journal |
|---|---|---|---|---|
| Release verification | `/5-release`, step 3 | 5 Fable hunters (security, reliability, accessibility, performance, regression), Sonnet tries to refute each finding | 1, 5, 10 or 100 rounds; stops after two dry rounds, or for a fix of a confirmed critical or high finding | `docs/release/v<version>-rounds.md` |
| Improvement | `/improve` (phase 4, between milestones) | one proposal, built in its own git worktree, then a verifier tries to refute it | 10 to 100 iterations, 150 lines each, a checkpoint after the first 5 then every 5, every 10 or only at the end; stops on a regression or a red baseline; nothing reaches your checkout until you approve the final diff | `logs/improve/<run>/journal.md` |
| Research | `/research <topic>` (phases 1 to 3) | GitHub, Reddit, Hacker News and web reads, then a critic picks the next queries | 1, 3 or 5 rounds; sources are untrusted text, and in the brainstorm findings come back as questions | `raw/research/<slug>/` |

On a subscription, 100 rounds or iterations can use up the weekly allowance. Workflows are off on Pro until Dynamic workflows is turned on in `/config`, and `disableWorkflows` or `CLAUDE_CODE_DISABLE_WORKFLOWS` turns them off: each loop then runs the same steps from the main session, one agent after another (the improvement loop offers at most 10 iterations there, since every report lands in the conversation), and `/setup-check` reports which case applies.

## What you see

- **Session banner:** in a phase-managed project every session opens with one line shown only to you (no model tokens): phase, next command, and whether the session runs the model the flow is designed for.
- **Command gate:** a phase or build command typed too early (`/4-build` in the brainstorm, `/task` or `/improve` before phase 4) is refused before it loads, with the command to run instead.
- **`/phase-status`:** what is approved, what blocks the gate, what you can run now, the next command. It reads the files through a script, so it costs one short report.
- **Compaction:** before every compaction a hook writes the phase, the plan, the handoff's age and the uncommitted files to `.scaffolder/compact-snapshot.md`, and the session after it reads that file first.
- **Who starts what:** phase, milestone, loop and session commands are typed by you; Claude names them as the next step but cannot start them. A loop offered inside a phase (research in the brainstorm, rounds in the release) starts only after you answer its cost question.

## The second brain

Each project follows Andrej Karpathy's [LLM-wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

- `raw/` — immutable sources: the original brief, references, research.
- `wiki/` — maintained by the agents: index first, one concept per page, citations, contradictions marked instead of overwritten, an append-only log.
- `CLAUDE.md` — the schema: how the wiki is kept and how work flows.

`/wiki-ingest` adds a source and updates every page it touches. `/wiki-lint` measures every page against a token budget, then finds contradictions, orphans, broken links, missing pages, stale pages and drift from the code. Lessons from tasks propagate into the project skills (Synapse).

The generated `CLAUDE.md` stays a short index of facts and paths. Folder conventions live in path-scoped rules (`.claude/rules/`), a code-map skill tells every agent where code lives, a `verify` skill holds the checks Claude runs before each commit, and a shared `.claude/settings.json` enables the plugin for everyone who clones the repository.

## Secrets

`secrets/` holds hand-over files with API keys. The agent may read them to use a key locally. The secrets guard blocks every way out it can see: committing while the folder is not git-ignored or is tracked, copying a value into another file (except git-ignored `.env` files), inlining a value in a shell command, publishing a file or page containing one as an Artifact (supporting files and assets included), and sending one through an MCP server (GitHub, mail, docs, chat, hosting), a web request or a message to another session. Uploading a file from `secrets/` over the network asks first. It is a guard rail, not a data-loss-prevention system.

Keys are best loaded inside the command that needs them (`set -a; . secrets/<service>.env; set +a; <command>`), so the value never enters the conversation: anything Claude reads lands in the session transcript. Phase 2 also offers an opt-in rule that blocks reads of `secrets/` for everyone who clones the project.

## Design

Design starts from a design system — one of your existing Design System artifacts, or a new one — and every section is drawn as artboards before any code exists. The skills used:

| Step | Skill |
|---|---|
| Design system and artboard composition | `web-design-skills:web-design-engineer` (ConardLi/garden-skills) |
| Anti-slop gate while composing, and the audit | `no-ai-design-slop`, `audit-ai-design-slop` (MengTo/Skills, bundled) |
| Typography, color, layout, accessibility, final review | `interfaces:better-*` (jakubkrehel/skills) |

Approved sections are saved as Artifact pages, one per section, linked from the design registry; without the Artifact tool each section is a self-contained page under `design/<section>/`. Every contrast ratio is computed by a bundled script, never estimated, and when browser tools are connected the critic also renders each page. Build ports the sections one to one; a missing element stops the task and reopens the section with `/3-design --section <name>`.

## Commands

**Phases**

| Command | |
|---|---|
| `/1-brainstorm [idea]` | Questions only, until the brief is approved |
| `/2-foundation [--upgrade]` | Second brain, skills, agents, secrets. `--upgrade` migrates a v3 project |
| `/3-design [--section <name>]` | Design system, artboards, critique, Artifacts |
| `/4-build [--status]` | Platform, milestone plan, build status |
| `/5-release [version]` | Debug, gate, version, tag |

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
| `/session-start [focus]` · `/session-end [--commit]` | Open and close a session; the start also checks whether Claude Code changed |
| `/phase-status` | Where the project is and the next command |
| `/wiki-ingest <source>` · `/wiki-lint` | Feed and check the second brain |
| `/decision <title>` · `/log-error <title>` | Record a decision or an understood error |
| `/todo [add <text> \| done <id> \| triage]` | The project notebook `wiki/todo.md`: advice, loose ideas, checks and bug hunts never run, deferred findings, sorted by priority; milestone plans start from it |
| `/skill-new <area>` · `/skill-map` | Create a project skill; show the skill network |
| `/pipeline-stats [--week]` | Is the pipeline helping? |
| `/setup-check` | Dependencies, Git Bash, hooks, workflows, fallback model, Artifact, memory, secrets setup; exact fixes |

## Upgrading from v3

v4 is a breaking release: the 19 v3 commands are replaced. Open a v3 project and the session start tells you; run `/2-foundation --upgrade` to add the phase state, move project skills to `.claude/skills/`, rename Execution Docs to milestone plans, create `raw/`, `secrets/` and the agent roster, and remove the duplicated hook entries after asking. See [CHANGELOG.md](CHANGELOG.md).

## Development

`CLAUDE.md` holds the maintainer rules; `wiki/` the plugin's own development memory. Before committing: `claude plugin validate .` and `bash tests/test-hooks.sh`. Before a release, the behaviour evals in [`evals/`](evals/README.md) check the gates end to end in real sessions (brainstorm writes only the brief, `/task` refuses without a milestone plan, `secrets/` values never reach another file); they cost model usage, and on native Windows they run only without shell grants.

## Credits

Methodology by [agent1.it](https://agent1.it). Built on ideas from Andrej Karpathy's LLM-wiki gist and [obra/superpowers](https://github.com/obra/superpowers). Bundled and depended-on skills: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

MIT.
