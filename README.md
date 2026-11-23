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

Requirements: Claude Code 2.1.323 or later, and bash (Git Bash on Windows) for the hooks.

## The five phases

| Phase | Command | What happens | Leaves with |
|---|---|---|---|
| 1 | `/1-brainstorm` | Questions only, one at a time: problem, users, outcome, scope, constraints, business, brand, risks, working agreements. No solutions, no stack, no files. | `docs/brief/BRIEF.md` approved by you |
| 2 | `/2-foundation` | The project's second brain: `raw/` sources, the wiki, the `CLAUDE.md` schema, project skills, the agent roster, a `secrets/` folder that never leaves your machine. | Structure check green, your confirmation |
| 3 | `/3-design` | Design system first. Then each section as artboards (all states, all viewports), an anti-slop audit and an accessibility check of color and type, your approval, and one Artifact page per section. | Every section approved in `wiki/design/registry.md` |
| 4 | `/4-build` | Platform decision (you choose), milestone plans, then `/task` for each activity: plan → build → verify → bug hunt → persona test. | Milestones closed with evidence |
| 5 | `/5-release` | Whole-project debug with the strongest model, a full test run, fixes, the release gate, version, changelog, tag. Never pushes. | Release report approved, tag created |

**The gates are mechanical, not just advice.** `.scaffolder/phase` records the current phase and a hook refuses writes that belong to a later one: in phase 1 only the brief can be written, in phases 2 and 3 no application code. Interaction modes (Normal, Autopilot, Autonomous) apply from phase 4 and never skip a gate.

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
| `sweeper` | Sonnet | Full suites, second opinions on findings, project-wide sweeps |
| `persona-tester` | Sonnet | Walks a changed flow as one end user |

Phase commands run the orchestrating session on Fable. Haiku is not used.

**When the Fable usage limit is reached**, everything pinned to Fable stops until the limit resets: the phase commands and the four Fable agents. To keep working on Opus in the meantime, start Claude Code with `CLAUDE_CODE_SUBAGENT_MODEL=opus` and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (forces every subagent to Opus, overriding the agents' frontmatter), and load the phase skill directly instead of the command (for example "load project-scaffolder:cortex and run a task: …"), since skills carry no model pin. Verification done this way is weaker: rerun the bug hunt of a release on Fable once the limit resets.

## The second brain

Each project follows Andrej Karpathy's [LLM-wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

- `raw/` — immutable sources: the original brief, references, research.
- `wiki/` — maintained by the agents: index first, one concept per page, citations, contradictions marked instead of overwritten, an append-only log.
- `CLAUDE.md` — the schema: how the wiki is kept and how work flows.

`/wiki-ingest` adds a source and updates every page it touches. `/wiki-lint` finds contradictions, orphans, missing pages, stale pages and drift from the code. Lessons from tasks propagate into the project skills (Synapse).

## Secrets

`secrets/` holds hand-over files with API keys. The agent may read them to use a key locally. The secrets guard blocks every way out it can see: committing while the folder is not git-ignored or is tracked, copying a value into another file (except git-ignored `.env` files), inlining a value in a shell command, publishing a file or page containing one as an Artifact. Uploading a file from `secrets/` over the network asks first. It is a guard rail, not a data-loss-prevention system.

## Design

Design starts from a design system — one of your existing Design System artifacts, or a new one — and every section is drawn as artboards before any code exists. The skills used:

| Step | Skill |
|---|---|
| Design system and artboard composition | `web-design-skills:web-design-engineer` (ConardLi/garden-skills) |
| Anti-slop gate while composing, and the audit | `no-ai-design-slop`, `audit-ai-design-slop` (MengTo/Skills, bundled) |
| Typography, color, layout, accessibility, final review | `interfaces:better-*` (jakubkrehel/skills) |

Approved sections are saved as Artifact pages, one per section, linked from the design registry. Build ports them one to one; a missing element stops the task and reopens the section with `/3-design --section <name>`.

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
| `/task <what>` | One piece of build work through the full pipeline |
| `/milestone-plan [Mn]` · `/milestone-close [Mn]` | Plan and close a milestone |
| `/bug-hunt [--diff \| --area \| --all]` | Look for unreported defects (read-only) |
| `/fix-bug <symptom>` | Reproduce, root-cause, fix, prove, record |
| `/test-sweep [scope]` | Every test, lint, type check, build and audit |

**Service**

| Command | |
|---|---|
| `/session-start` · `/session-end [--commit]` | Open and close a session; the start also checks whether Claude Code changed |
| `/phase-status` | Where the project is and the next command |
| `/wiki-ingest <source>` · `/wiki-lint` | Feed and check the second brain |
| `/decision <title>` · `/log-error <title>` | Record a decision or an understood error |
| `/skill-new <area>` · `/skill-map` | Create a project skill; show the skill network |
| `/pipeline-stats [--week]` | Is the pipeline helping? |
| `/setup-check` | Dependencies, agents, hooks, secrets setup |

## Upgrading from v3

v4 is a breaking release: the 19 v3 commands are replaced. Open a v3 project and the session start tells you; run `/2-foundation --upgrade` to add the phase state, move project skills to `.claude/skills/`, rename Execution Docs to milestone plans, create `raw/`, `secrets/` and the agent roster, and remove the duplicated hook entries after asking. See [CHANGELOG.md](CHANGELOG.md).

## Development

`CLAUDE.md` holds the maintainer rules; `wiki/` the plugin's own development memory. Before committing: `claude plugin validate .` and `bash tests/test-hooks.sh`.

## Credits

Methodology by [agent1.it](https://agent1.it). Built on ideas from Andrej Karpathy's LLM-wiki gist and [obra/superpowers](https://github.com/obra/superpowers). Bundled and depended-on skills: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

MIT.
