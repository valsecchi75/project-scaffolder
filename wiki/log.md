# Log — project-scaffolder development

> Append-only. `grep "^## \[" wiki/log.md | tail` shows the recent history.

## [2026-08-03] release | v3.0.0 Fable Edition
Execution Docs with model routing, context handoff, wiki lifecycle, guard hooks. End-to-end test on a real Complex project.

## [2026-08-03] release | v3.0.1–v3.0.4
Workflow opt-in with cost estimates; the workflow question made critical in Autopilot; Working Agreements; design gate.

## [2026-11-23] review | Audit of v3.0.4
Findings: single-pass scaffold with skippable questions; no visual design phase; no secrets handling; routing in prose only and opposite to the maintainer's policy; hooks running twice; project skills generated where Claude Code does not discover them; partial LLM-wiki pattern; opaque and colliding command names.

## [2026-11-23] review | Claude Code changelog 2.1.321–2.1.330
See claude-code-changelog.md.

## [2026-11-23] decision | DEC-001 to DEC-008
Phase flow, binding model routing, numbered commands, secrets folder, design dependencies, bug hunting, native skill location, plugin-only hooks.

## [2026-11-23] release | v4.0.0 (prepared)
Phases, agents, guards, design studio, bug hunt, release debug, second-brain wiki. Branch `v4-sequential-flow`; not pushed.

## [2026-11-23] decision | DEC-009 to DEC-012
Improvement loop on branch `v4-improve-50` (baseline tag `v4.0.0-baseline`): no model pins on main-conversation commands, loops as plugin workflows with a fallback, user-facing status from hooks, behaviour evals for the gates. DEC-002 marked partly superseded; `claude-code-changelog.md` capabilities and candidates brought up to date.

## [2026-11-23] release-prep | Unreleased changelog and version source
`CHANGELOG.md` "Unreleased" now covers the whole improvement branch (workflows, command gate, PreCompact, banner, read-only scripts, generated-project rules, local artboards, parallel build, agent and hook changes). Version removed from the marketplace entry: it lives only in `plugin.json`.

## [2026-11-23] integrate | 60 improvement cycles merged
Cross-area fixes: the bug-hunt skill renamed `debugging` and the workflows `improve-segment` and `research-rounds` (one name per component); `/improve` added to the command gate; every bug hunt refutes (cortex aligned, sweeper second-opinion job removed); release hooks and `/phase-status` agree on `/milestone-plan` after a release; the rounds journal no longer read as a release report; `/code-review` and `/security-review` started by Claude after the user agrees; all `*.sh` LF through the root `.gitattributes`; tests for the bundled scripts. DEC-013 to DEC-018.

## [2026-11-23] release | v4.1.0 (prepared)
Loops as workflows, command gate, session banner, PreCompact snapshot, read-only scripts, refute-first verification, fail-closed guards, lean generated projects. Version only in `plugin.json`. Not pushed.

## [2026-11-23] feature | /todo notebook, outward secrets guard, Fable quota fallback
`/todo` and skill `backlog` (`wiki/todo.md`, read-only `todo-report.sh`), wired into milestone plan and close, bug hunt, persona test, release and session end. Secrets guard extended to MCP, web, session messages and Artifact supporting files. A Fable agent out of quota is offered on Opus, with a `/todo` item to repeat it. DEC-019, DEC-020. Phase 1 stays without wiki writes (regression review): its loose ends go under the brief's Open questions.

## [2026-11-23] review | Fable 5.2 pre-release review and blind quality judge
Release review: SHIP AFTER FIXES, no blocker; HIGH findings on the secrets guard (formats not recognised, non-secrets blocking calls) and on unquoted script paths, fixed with test cases, plus the MEDIUM/LOW ones (git add arguments, staged content on commit/push, Edit removing a value, .env only when ignored, fork sessions, research sweep failures). Blind judge on the Sorsi micro-project: 81/100 against 57/100 for 4.0.0, higher on all twelve dimensions; its five remaining weaknesses are T-001..T-005 in `wiki/todo.md`.

## [2026-11-23] review | Claude Code changelog check (v4.1.1 session)
No entry after 2.1.330. Code Mode (2.1.323+) recorded in claude-code-changelog.md for `/setup-check`.

## [2026-11-23] decision | DEC-022 to DEC-025
Command gate on gate facts through `phase-status.sh --facts`; build output scanned for keys with the guard's shared secret map; blocked reads of `secrets/` recommended; phase commands kept under about 4.5k tokens.

## [2026-11-23] release | v4.1.1 (prepared)
T-001 to T-007 of `wiki/todo.md`: fact gates for `/2-foundation` and `/4-build`, loops sized to the project, `build-secrets.sh` in the release gate and the architect's no-keys-on-device rule, lighter phase commands, Block reads as the phase-2 default, Code Mode in `/setup-check` with composed-command guard tests, auto-format on the input's cwd, `deny-dangerous.ps1` removed. Branch `v4.1.1`; not pushed.
