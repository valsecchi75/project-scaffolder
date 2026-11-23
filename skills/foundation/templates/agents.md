# Agents and model routing

> last-verified: {YYYY-MM-DD}

The orchestrating session plans and decides; specialists do the work. Every specialist is a plugin agent with its model fixed in its definition. Dispatch them by name and never override their model.

## Routing

| Kind of work | Model | Why |
|---|---|---|
| Planning and verification | Fable | Most capable: mistakes here multiply downstream |
| Production (code, tests, design files) | Opus | Strong, efficient implementation from an approved plan |
| Redundant checks and mass testing | Sonnet | Breadth and repetition at lower cost |
| — | Haiku | Not used in this project |

## Roster

| Agent | Model | Writes files | Used in | Job |
|---|---|---|---|---|
| `project-scaffolder:architect` | Fable | plans, decisions | 4 | Platform decision, milestone plans, task plans |
| `project-scaffolder:builder` | Opus | code, tests | 4, 5 | Implements one approved task plan |
| `project-scaffolder:designer` | Opus | `design/` only | 3 | Design system files and artboards |
| `project-scaffolder:verifier` | Fable | no | 4, 5 | Checks a task against its plan with fresh evidence |
| `project-scaffolder:bug-hunter` | Fable | no | 4, 5 | Proves defects: diff at the end of each task, whole project before release |
| `project-scaffolder:design-critic` | Fable | no | 3 | Slop audit, contrast and type accessibility, system fidelity |
| `project-scaffolder:sweeper` | Sonnet | no | 4, 5 | Full suites, second opinions on findings, project-wide sweeps |
| `project-scaffolder:persona-tester` | Sonnet | no | 4 | Walks a changed flow as one end user |

## Rules of delegation

- A specialist gets a bounded brief: the task, the paths to read, the criteria. Not the whole wiki.
- Reviewers never see the producer's reasoning, only the result and the plan.
- At most three correction rounds per task; then stop and report to the user.
- No agent prints a secret value.
- Project-specific agents, if ever needed, go in `.claude/agents/` and are listed here with their model.

## Project notes

{Anything specific to this project: agents that must never run, extra checks, budget limits.}
