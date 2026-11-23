# Changelog

All notable changes to the Project Scaffolder plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.0.0 — 2026-11-23 — Sequential Edition

Breaking: the v3 commands are replaced. v3 projects migrate with `/2-foundation --upgrade`.

### Added
- **Five sequential phases with hard gates**: `/1-brainstorm` (questions only, one at a time, until the brief is approved), `/2-foundation`, `/3-design`, `/4-build`, `/5-release`. State in `.scaffolder/phase`; skill `phase-flow` holds the contract.
- **Phase guard hook** (`hooks/phase-guard.sh`): refuses writes that belong to a later phase — only the brief and `raw/` in phase 1, no application code in phases 2 and 3.
- **Eight agents with fixed models**: architect, verifier, bug-hunter, design-critic (Fable); builder, designer (Opus); sweeper, persona-tester (Sonnet). No Haiku.
- **Design studio** (phase 3): design system first, artboards per section with every state and viewport, anti-slop audit, contrast and typography accessibility check, user approval, one Artifact page per section, `wiki/design/registry.md`.
- **Bug hunt after every task** and a **whole-project debug before every release**, with a proof gate (reproducible now, observed, reachable, not known noise) and a Sonnet second opinion on every critical or high finding. Commands `/bug-hunt`, `/fix-bug`.
- **`secrets/` folder** and **secrets guard hook**: readable locally, never committed, copied, inlined in commands or published as an Artifact.
- **Second brain after Karpathy's LLM wiki**: immutable `raw/`, maintained `wiki/`, `CLAUDE.md` as schema; `/wiki-ingest`, `/wiki-lint`; parsable log lines.
- **SessionStart bootstrap**: in a phase-managed project, every session starts knowing the phase, its rules and the next command; v3 projects get an upgrade hint.
- **Claude Code changelog check**: `/session-start` reads the newer changelog entries when the installed version changed (`wiki/claude-code.md` in each project). The plugin repository keeps its own registry in `wiki/claude-code-changelog.md`.
- Dependencies on `interfaces` (jakubkrehel/skills) and `web-design-skills` (ConardLi/garden-skills); bundled `no-ai-design-slop` and `audit-ai-design-slop` (MengTo/Skills, MIT); `/setup-check`.
- `tests/test-hooks.sh`: 57 regression cases for every hook, Windows paths included.

### Changed
- Commands renamed by phase and purpose: `/task`, `/milestone-plan`, `/milestone-close`, `/test-sweep`, `/session-start`, `/session-end`, `/phase-status`, `/decision`, `/log-error`, `/skill-new`, `/skill-map`, `/pipeline-stats`. Every command declares its model.
- The roadmap unit is the **milestone**; the v3 Execution Doc becomes the milestone plan (`docs/plans/MILESTONE-<n>.md`, with an Agent column).
- Platform and stack are chosen in phase 4 against the constraints gathered in phase 1, not at scaffold time.
- Project skills are generated in `.claude/skills/`, where Claude Code discovers them; their counters move under `metadata:`. The skills map moves to `wiki/skills-map.md`.
- Auto-format runs only in projects managed by the plugin.

### Removed
- `/scaffold`, `/phase-doc`, `/kickoff`, `/wrap`, `/phase-shift`, `/plan`, `/implement`, `/review`, `/debug`, `/test`, `/gate`, `/ship`, `/decide`, `/error`, `/wiki-gc`, `/skills`, `/forge`, `/stats` (replaced as above).
- `design-first` skill (superseded by the design studio and the architect's task plans), `persona-lab` skill (now the `persona-tester` agent), `templates/execution-doc.md`.
- Copying the guard hooks into each project, which made them run twice.

## 3.0.4 — 2026-08-03

### Added
- **Design gate** (`design-first` skill + Cortex Step 3b): the first operational task of each phase and every Complex task go through a structured design dialogue BEFORE execution — questions one at a time (max 5, mode-aware), 2-3 approaches with trade-offs, sectioned approval, design doc in `docs/design/`. The approved design has rule-revision authority over scaffold-era artifacts (Execution Doc, architecture, tech-stack, decisions via `[DESIGN-REVISION]`; Working Agreements only with explicit user confirmation). Flags: `--design` / `--no-design`.

## 3.0.3 — 2026-08-03

### Added
- **Working Agreements**: scaffold interview (design pipeline, generative models, reference projects, custom rules) → dedicated section in the generated CLAUDE.md; `/kickoff` recaps it in the briefing; the Cortex injects it (~150 tokens) into every specialist's context. Normal/Autopilot always ask; Autonomous fills `[HYPOTHESIS]` defaults.

## 3.0.2 — 2026-08-03

### Fixed
- Workflow opt-in question (scaffold options and Cortex Step 1b) is now explicitly CRITICAL: asked in Normal AND Autopilot mode; only Autonomous decides silently (Standard, logged `[DECISION-AUTO]`). Found during the first real E2E test: Autopilot skipped the question and self-decided.
- E2E validated on a real Complex project: scaffold 12-core, phase gate, /phase-doc model routing, full /task pipeline with QA feedback loop and Synapse propagation, guardrail hooks, /wrap hygiene — all green.

## 3.0.1 — 2026-08-03

### Added
- **Workflow opt-in**: for Complex tasks the Cortex presents execution options (standard pipeline / multi-agent workflow / decomposition) with order-of-magnitude token estimates before delegating; `/scaffold` offers a standard vs orchestrated scaffold for Medium/Complex projects. Multi-agent orchestration always requires the user to type `use a workflow` — never launched autonomously. Choices are logged as `[DECISION]`.

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
