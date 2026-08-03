# Changelog

All notable changes to the Project Scaffolder plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 3.0.0 — 2026-08-03 "Fable Edition" (Ondata 1)

### Added
- `/phase-doc` + `templates/execution-doc.md`: per-phase Execution Doc (activities, model routing Fable/Opus/Sonnet/Haiku, token estimates, VERIFY criteria, parallelizable flag). Hard gate: the Cortex refuses `/task` without it (`--no-phase-doc` to skip consciously).
- `context-manager` skill: 300k threshold, proactive handoff, ≤40-line continuation prompt, context minimalism rules.
- `/wiki-gc` + `/wrap` hygiene pass: wiki lifecycle with `wiki/_archive/`, `last-verified` headers, line caps (CLAUDE.md ≤120, handoff ≤80, priorities ≤100).
- Hooks: PreToolUse guardrail against destructive commands (sh + ps1, pattern file), PostToolUse auto-format. Generated projects get a self-contained copy in `.claude/hooks/`.

### Changed
- CLAUDE.md template rewritten: ≤120 lines, style rules (concise output, human comments, performance), context rules, v3 task pipeline.
- Wiki generation: 12 core files + on-demand pages (was 21+ upfront).
- Cortex: concise ≤10-line task report; model routing hint from the Execution Doc.
- Persona-lab: 5k injection budget.

### Removed
- Caveman integration (unverified claims; replaced by structural token diet).

## [2.2.0] — 2026-04-17

### Added
- 15 new workflow slash commands for day-to-day software work:
  - Session lifecycle: `/kickoff`, `/wrap`, `/phase-shift`
  - Development: `/plan`, `/implement`, `/review`, `/debug`, `/test`
  - Release: `/gate`, `/ship`
  - Knowledge: `/decide`, `/error`
  - Skills & analytics: `/skills`, `/forge`, `/stats`
- `CHANGELOG.md` following the Keep a Changelog format, with history for v1.x, v2.0, and v2.1.

### Changed
- `README.md` version references aligned to v2.1+ ("What's New" section, Project Structure).
- `README.md` Caveman token-savings claims softened — explicit disclaimer that numbers vary by task and should be measured with `/stats`.
- `README.md` Project Structure updated to list all 17 commands and 5 skills.

### Fixed
- Version inconsistency: README no longer references v2.0.0 while `plugin.json` reports newer versions.
- Project Structure previously listed 4 skills; now correctly lists all 5 (including `pipeline-logger`).

## [2.1.0] — 2026-04-16

### Added
- `pipeline-logger` skill — structured audit trail for every `/task` execution, with dual log (pipeline + errors) and analytics queries.
- Dual-log protocol: every failure in Cortex, QA, Persona-Lab, or Synapse writes to both `logs/pipeline/` and `logs/errors/` with cross-references.
- Task ID convention `TASK-YYYY-MM-DD-NNN` auto-incremented per day.
- Error ID convention `ERR-NNN` in `guardrails/errors-to-avoid.md`, cross-referenced from skill anti-patterns.

### Changed
- Cortex, Synapse, and Persona-Lab skills now explicitly log each step to the pipeline log.
- `project-scaffolder` Phase 4 creates `logs/pipeline/` and `logs/errors/` directories.
- Synapse backup/restore now validates length >= 80% of backup before committing refactor.

### Fixed
- Synapse propagation no longer cascades beyond one hop (one-hop rule enforced).
- Anti-pattern entries are now strictly append-only during Synapse refactors.

## [2.0.0] — 2026-04-15 — Synaptic Edition

### Added
- **Cortex** (`/task` command) — project leader skill that classifies, delegates, and verifies.
- **Synapse** — learning propagation skill with backup-and-validate merge protocol.
- **Persona-Lab** — simulated end-user focus group for UX validation.
- **On-demand skill generation** — Cortex Step 3 generates skills mid-session when no match exists.
- **Skill maturity lifecycle** — seed → growing → mature → expert based on `tasks_completed`.
- **Karpathy Coding Discipline** — behavioral guardrails injected into CLAUDE.md, every generated skill, release-gate Stage 6, and priorities task format.
- **Assumption Surfacing** — mandatory sub-step in Phase 2 brainstorming, tagged `[HYPOTHESIS]`.
- **Verifiable success criteria** — every task in `priorities.md` requires a `→ VERIFY:` clause.
- **Interaction modes** — Normal / Autopilot / Autonomous control how much Claude asks, propagated to every subsequent session.
- **Caveman integration** — optional auto-install of the Caveman token-compression plugin during scaffolding.

### Changed
- Release-gate now has 6 stages (added Stage 6: Simplicity Check).
- Skill frontmatter extended with `maturity`, `tasks_completed`, `last_synapse_update`, `connections`.
- Skill files now live in `skills/[name]/SKILL.md` (directory per skill) with `.history/` subfolder for backups.

## [1.x] — pre-Synaptic

Initial scaffolding-only version. Generated CLAUDE.md, Karpathy-style wiki, vertical skills, guardrails, handoff, and design spec from a user brief. No orchestration, no learning propagation.

[2.2.0]: https://github.com/valsecchi75/project-scaffolder/releases/tag/v2.2.0
[2.1.0]: https://github.com/valsecchi75/project-scaffolder/releases/tag/v2.1.0
[2.0.0]: https://github.com/valsecchi75/project-scaffolder/releases/tag/v2.0.0
