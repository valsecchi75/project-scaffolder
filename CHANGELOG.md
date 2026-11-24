# Changelog

All notable changes to the Project Scaffolder plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.1.3 — 2026-11-24

Claude Ship (Claude Code's `/ship`, PR Steward and Claude Approvals, announced 2026-11-23) reviewed for the flow. The plugin still never pushes and starts none of it.

### Added
- **`/5-release` names `/ship`** among the actions that are yours after the tag, for github.com repositories that merge through pull requests: you type it in a terminal session and it commits, pushes, opens the pull request, reviews it and watches its checks; you merge. Where the repository squashes or rebases, the tag is recreated on the merged commit before it is pushed.
- **[UPGRADING.md](UPGRADING.md)**: moving a v3 project to v4, step by step, with the v3 to v4 command map.
- **`/setup-check`** says when `/ship` is usable (Claude Code 2.1.330+, `gh` 2.63+, a github.com remote, a terminal session) and notes a Claude Approvals policy when the project has one.

### Changed
- **`/improve` never edits the pull-request approval policy**: `.claude/approvals.yml` and `.claude/classifiers/` join the protected paths, like the settings files and hooks. An edit there can let changes merge unreviewed, so it is your decision, not an iteration.
- **`/2-foundation --upgrade` needs no extra prompt**: it checks for uncommitted work and work in progress before changing anything, creates the notebook `wiki/todo.md`, and writes the command map and the new rules into `wiki/handoff.md`, so later sessions start from the v4 flow.
- `tests/test-hooks.sh` (237 cases): the loop's protected paths agree between the workflow script and the skill, and the script's path check is run on the approval policy.

## 4.1.2 — 2026-11-23

### Fixed
- **The release build scan cannot be fooled by a hidden key file**: every key `.env.example` names must have its line in `secrets/`, so a key file that is empty, missing or not handed over yet makes the scan answer `NOT CHECKED` instead of clean. With the Bash sandbox on (macOS, Linux, WSL2) and reads of `secrets/` blocked, `/5-release` takes the scan's verdict from a run in your own terminal: the sandbox docs do not say how a denied file looks to a command.
- `tests/test-hooks.sh`: the scan in a git worktree (it uses the main checkout's `secrets/`) and with an emptied or removed key file.

## 4.1.1 — 2026-11-23

The open points of the Fable 5.2 review of 4.1.0 (`wiki/todo.md` T-001 to T-007). Existing projects need nothing: the new gates read files they already have.

### Added
- **Release gate scans what ships for keys**: stage 7 of the release gate runs `build-secrets.sh` on the build output and lists every file that holds a value from `secrets/`, by file and variable name, never the value. It recognises secrets exactly as the secrets guard does (the shared `hooks/secrets-lib.sh`). A hit is a critical finding. The scan answers `NOT CHECKED`, never clean, when it cannot read every key file in full (a sandbox, UTF-16, a large file), finds nothing built, is pointed outside the project or into `secrets/`, or keys are expected but the folder is missing; it finds the project root itself, and the main checkout's `secrets/` from a worktree.
- **The architect keeps keys off users' devices**: a client-only product that needs a keyed service gets a small proxy or a keyless service, decided with the platform; `wiki/tech-stack.md` records the build output folder the gate scans.
- **`/setup-check` recommends Code Mode** for terminal sessions (`CLAUDE_CODE_EXPERIMENTAL_CODE_MODE=1` in the `env` of your user settings; a project setting does not turn it on, and the VS Code panel does not run it), with a new `TIP` status for optional advice.

### Changed
- **The command gate checks the facts, not only the phase**: a typed `/2-foundation` is refused until the brief says `status: approved`; `/3-design` and `/4-build` until you confirm the foundation; `/4-build` until the design phase is closed (every section approved and the closing line logged), unless the brief says the product has no interface. `/2-foundation --upgrade` is only for v3 projects, which have no phase file, and refuses on a project that has one. The gate reads them through the same script as `/phase-status` (`phase-status.sh --facts`), so the two never disagree.
- **Loops sized to the project**: `/5-release` recommends 1 verification round instead of 5 for a small project (about 30 source files and 3,000 lines, counted in the release inventory), except a first release with authentication, payments or personal data. `/improve` says in its approval options that iteration 5 is always a checkpoint, also with "Only at the end".
- **Blocking Claude's reads of `secrets/` is now the recommended answer** in `/2-foundation`: keys load in the shell inside the command that needs them (`set -a; . secrets/<file>.env; set +a; <command>`), so values never reach the transcript. "Readable" stays available.
- **Lighter phase commands**: each loads at most about 4.5k tokens again (4.1.0: 3.5–5.8k). The dispatch and question rules live only in `phase-flow`; steps that run once per project moved to files read when they apply (the platform decision and the `verify` skill in `cortex/platform.md`, artboard home, browser check and references in `design-studio/entry.md`, the Fable-quota fallback in `phase-flow/fallback.md`). `/task`, `/milestone-plan` and `/milestone-close` load `phase-flow` when the session does not have it yet.
- **auto-format** finds the project from the hook input's working directory like the other hooks, and formats only files inside it.
- `tests/test-hooks.sh` grows from 188 to 231 cases: the fact gates (and their agreement with `/phase-status`), chained, piped, subshell and PowerShell commands against the guards (as Code Mode scripts send them), the build scan (including the cases where it must answer not checked), auto-format's project lookup.

### Removed
- `hooks/deny-dangerous.ps1`: never wired (the plugin's hooks run in bash), it would have kept a second copy of the patterns.

### Fixed
- The README said phase 1 may write the notebook; since DEC-021 it writes only the brief and `raw/`.

## 4.1.0 — 2026-11-23

Projects started with 4.0 keep working: `/4-build` writes the new `verify` skill when it is missing. Path-scoped rules, the code map and the shared `.claude/settings.json` are written by `/2-foundation` in new projects; copy them from `skills/foundation/templates/` into an existing one if you want them.

### Added
- **Release verification rounds** (`/5-release`, step 3): after a green build and test run you choose 1, 5, 10 or 100 rounds, with a cost estimate. Each round runs five Fable hunters (security, reliability, accessibility, performance, regression) and a Sonnet agent that tries to refute every new finding; it stops after two dry rounds, or to fix a confirmed critical or high finding. A journal (`docs/release/v<version>-rounds.md`) lets a new session resume.
- **Improvement loop** (`/improve`, phase 4 between milestones): 10 to 100 iterations, each one change of at most 150 lines built in its own git worktree and then attacked by a verifier. Checkpoints for your approval, a pre-launch permissions step so the agents do not stall, protected paths (secrets, `.env`, settings, hooks), and nothing reaches your checkout until you approve the final diff. Journal in `logs/improve/<run>/journal.md`.
- **Research** (`/research <topic>`, also offered once in the brainstorm and the design phase): 1, 3 or 5 rounds on GitHub, Reddit, Hacker News and the web, saved as cited raw sources in `raw/research/<slug>/` with a digest. Sources are untrusted text: the script drops off-domain and malformed URLs, reads each page once, and passes only short signals onward. In the brainstorm the findings come back as questions.
- The three loops run as plugin workflows (`release-rounds`, `improve-segment`, `research-rounds`) with progress and per-agent tokens in `/workflows`; without workflows each one runs the same steps from the main session, with a lower cap.
- **Command gate**: a typed `/3-design`, `/4-build`, `/5-release`, `/task`, `/milestone-plan`, `/milestone-close`, `/fix-bug` or `/improve` that comes too early is refused before it loads, with the command to run instead.
- **Session banner**: every session in a phase-managed project opens with one line shown only to you: phase, next command, and whether the session runs the model the flow is designed for (`/model fable` when it does not).
- **Compaction snapshot**: before every compaction a hook writes the phase, the plan, the handoff's age and the uncommitted files to `.scaffolder/compact-snapshot.md` and tells the summary what to keep; the session after it reads that file first, and `/session-start` notices a handoff that fell behind.
- **`/phase-status`** reports facts read by a script (approvals, what blocks the gate, the next command) plus a "You can run now" line per phase.
- **Brainstorm**: questions through AskUserQuestion, one topic per call; the brief is drafted topic by topic, so an interrupted interview resumes where it stopped; solutions you volunteer are parked verbatim in `raw/parking-lot.md` for the phase that decides them; a hand-over check before approval, then `/clear brainstorm` and `/2-foundation`.
- **Design**: a self-contained local page per section when the Artifact tool is unavailable; contrast ratios computed by a bundled WCAG calculator, never estimated; an optional reference-research step whose follow and avoid picks reach the designer and the critic; an optional browser check where the critic renders each page (clipped text, computed colors, focus, console errors).
- **Build**: `/task --parallel <#,#>` builds two or three independent activities at once, each in its own worktree; the platform decision writes a project `verify` skill that Claude Code runs before each commit and the verifier runs on every task, and fills the Commands section of the project's `CLAUDE.md`; a commit per task when the new **Git** line of your working agreements says so; the architect, builder, verifier and bug hunter preload the project's code map instead of exploring the tree.
- **Generated projects**: a lean `CLAUDE.md` (facts and paths, a Commands section filled at the platform decision, Compact instructions), path-scoped rules in `.claude/rules/`, a `project-overview` code-map skill, a shared `.claude/settings.json` that enables the plugin for collaborators, an opt-in rule that blocks reads of `secrets/`, and keys loaded in the shell so values never enter the conversation.
- **Wiki and logs**: `/wiki-lint` starts from a token report against page budgets and finds broken links and `@` imports; the pipeline log is one parsable line per step, and `/pipeline-stats` counts it with a script instead of reading it.
- **`/setup-check`** detects Git Bash, hooks turned off, workflows off, a missing `fallbackModel`, why the Artifact tool is unavailable and auto memory off, each with the exact fix and what degrades.
- **`/todo` — the project notebook** (`wiki/todo.md`, skill `backlog`): advice from users and testers, loose ideas, bug hunts and checks asked for and never run, deferred findings, debt and open questions, one `T-NNN` line each with priority, type, date and source. Claude adds to it when something is left for later; a read-only script shows it P1 first and oldest first and flags old P1 items; `/milestone-plan` starts from it and `/milestone-close` reconciles it; the session brief shows the open count. Created by `/2-foundation` from the brief's open questions; phase 1 still writes only the brief and `raw/`.
- **Secrets guarded on every way out**: the secrets guard now also covers MCP servers (GitHub, mail, docs, chat, hosting), web fetch and search, messages to other or cloud sessions, and every file an Artifact publish carries (supporting files, assets, database rows), by value and by `secrets/` path. The checks run in batches, so a publish that names many files stays well inside the hook's timeout (a timeout refuses the call).
- **Fable out of quota**: a Fable agent that fails on a usage limit is offered again on Opus now or after the reset; a step run on Opus is added to `/todo` to be repeated on Fable.
- **Plugin evals** (`evals/`, `claude plugin eval`): three cases that push against a gate in a real session: the brainstorm creates no code and asks instead; `/task` refuses without an approved milestone plan; a value from `secrets/` never reaches another file.
- `tests/test-hooks.sh` grows from 57 to 188 cases and now also covers the bundled scripts.

### Changed
- **Commands no longer switch the model** (a switch re-reads the whole conversation without the prompt cache). Routing holds through the agents' own models; the read-only reports (`/phase-status`, `/pipeline-stats`, `/skill-map`, `/setup-check`) run in a forked Sonnet subagent.
- **User-only commands**: the phase commands, `/milestone-plan`, `/milestone-close`, `/improve`, `/research`, `/session-start`, `/session-end`, `/wiki-ingest`, `/wiki-lint`, `/skill-map` and `/pipeline-stats` are typed by you; Claude names them as the next step but does not start them, and their descriptions no longer fill the context.
- **Agents** are dispatched by scoped name, chained on their completion notifications, and return short fixed-shape reports; every agent sets its own effort, and the builder's scales with the task size; `persona-tester` starts without the project's `CLAUDE.md`, like a real user.
- **Every bug hunt refutes before it confirms**: after a task, in `/bug-hunt` and in the release rounds, critical and high findings go to a Sonnet agent that tries to prove them wrong. Uncertain counts as refuted; a check that could not run never counts as confirmed.
- **The guards fail closed**: if the phase, secrets or destructive-command guard cannot run (no bash, a broken install), the tool call is refused instead of passing unchecked. `/setup-check` gives the fix.
- **Hooks follow the session into worktrees and subfolders**: the project is found from the hook input's working directory, so a worktree cannot bypass the phase guard.
- **`/5-release`** resumes an interrupted release, runs the rounds only on a green build, and offers `/code-review` and `/security-review`, which Claude starts after you agree.
- **Sessions**: `/session-start [focus]` and `/session-end` each run one read-only script; the handoff is the whole continuation, so a new chat needs only `/session-start <focus>`; plain `/compact` is enough because the hook supplies the keep-list.
- **Synapse** reports skills due for a refactor instead of rewriting them on its own, and reuses the error id already recorded.
- The skill behind `/bug-hunt` and `/fix-bug` is now `debugging` (the commands are unchanged): it had the same name as the `/bug-hunt` command.
- The destructive-command prompt is now in English, like the other guard messages.
- The version is set only in `plugin.json`; the marketplace entry no longer repeats it (with both set, `plugin.json` wins and `claude plugin validate` warns).

### Fixed
- **Secrets guard (pre-release review on Fable 5.2):** keys written other than as `NAME=value` (inside a URL, in JSON, Markdown, free text, PEM or base64 lines) were not recognised, while identifiers, hostnames and plain URLs in `secrets/` blocked ordinary calls; one pass now reads every file and refusals name the file and variable, never the value. A commit whose changes contain a value, and a push while a committed file holds one, are refused; a `git add` is judged on its own arguments, so a commit message mentioning secrets passes; an Edit that removes a leaked value passes; a `.env` file is exempt only when git ignores it.
- `/phase-status`, the phase-flow and wiki-keeper scripts failed when the plugin was installed under a path with a space (unquoted script paths).
- A forked session (`--fork-session`, `/branch`) now gets the session banner and phase context too.
- A research sweep agent that threw was counted as "nothing new" instead of a failure.
- `/phase-status` in phase 5 could take the rounds journal for the release report, and showed a draft brief's interface as `{yes|no}`.
- After a release the session banner and the compaction snapshot pointed to `/4-build`, while the release sets the phase back to build and suggests `/milestone-plan`; all now say `/milestone-plan`.
- Research no longer offers `/deep-research` as the fallback when workflows are off: it is a workflow too.
- Solutions parked in phase 1 were never read again: the design phase and the platform decision now weigh their lines of `raw/parking-lot.md` and say what they adopt or reject.
- Phase 2 read every file under `raw/`, research sources included; it now reads only the research digests, like the brainstorm.
- A loop agent that fails no longer ends the whole run: in `/improve` it discards one iteration instead of the segment, in research a failed critic still leaves the digest, and neither failure counts as "nothing left to do". A launch whose script fails its syntax check is reported instead of being taken as started.
- The workflow opt-in rule in the generated `CLAUDE.md` and the build skill now covers the plugin's own loops, which start on your answer to their cost question.
- Shell scripts under `skills/` are kept LF-only by `.gitattributes`; a CRLF checkout on Windows would have broken them.

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
