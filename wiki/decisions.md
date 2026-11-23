# Decisions — project-scaffolder

> last-verified: 2026-11-23
> Append-only. A superseded decision is marked, never removed.

## DEC-001: Five sequential phases with hard gates (v4.0.0)

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** the v3 single-pass `/scaffold`

**Question:** How should the plugin structure the work from idea to release?
**Options:** A — one scaffold pass, then a task pipeline (v3) · B — five phases, each with one kind of work and one approved exit artifact.
**Choice:** B. Brainstorm (questions only) → foundation → design → build → release.
**Why:** v3 asked at most three questions, then generated everything; Autopilot and Autonomous skipped even those. Mistakes made at brainstorm time were baked into the wiki and the skills. A phase that may only ask questions cannot anchor on a premature solution.
**Consequences:** A mechanical phase guard (`hooks/phase-guard.sh`) refuses later-phase writes; `.scaffolder/phase` holds the state. Interaction modes apply only from phase 4. The roadmap unit is now "milestone", to avoid two meanings of "phase".

## DEC-002: Binding model routing — Fable plans and verifies, Opus builds, Sonnet re-checks, no Haiku

**Date:** 2026-11-23 · **Status:** [DECISION], partly superseded by DEC-009 (phase commands no longer set a model) · **Supersedes:** the v3 Execution Doc routing table (Fable for long implementations, Opus for architecture, Haiku for mechanical work)
**Options:** A — a routing table the orchestrator should follow · B — the model fixed in each agent's frontmatter, phase commands set to Fable.
**Choice:** B.
**Why:** a table in prose is a hint; an omitted model silently inherits the session's. Fixing the model per agent makes the routing hold even when the orchestrator forgets.
**Consequences:** eight agents. Changing routing means editing their frontmatter (see `CLAUDE.md`).

## DEC-003: Numbered phase commands, old names dropped

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — numbered phase commands (`/1-brainstorm` … `/5-release`) plus grouped service commands · B — Italian names · C — keep the 19 v3 commands and add new ones.
**Choice:** A (maintainer's choice).
**Why:** the order is visible in autocomplete; names say what they do; v3 names (`/forge`, `/gate`, `/wrap`, `/kickoff`) were opaque, and some collided with built-in commands (`/plan`, `/review`, `/debug`, `/skills`, `/stats`).
**Consequences:** breaking change, major version 4.0.0. A v3 project gets a hint at session start and migrates with `/2-foundation --upgrade`.

## DEC-004: `secrets/` is readable by the agent and never published

**Date:** 2026-11-23 · **Status:** [DECISION], refined by DEC-016 (opt-in deny rule, keys loaded in the shell)
**Options:** A — readable locally, every way out blocked · B — unreadable (`permissions.deny` on `Read(./secrets/**)`), keys entered by hand.
**Choice:** A (maintainer's choice).
**Why:** the folder exists to hand keys to the agent for local use.
**Consequences:** `hooks/secrets-guard.sh` blocks: git add/commit/push while `secrets/` is not ignored or is tracked; copying a value into any other file except git-ignored `.env` files; inlining a value in a shell command; publishing a file from `secrets/` or a page containing a value as an Artifact. Network uploads of a `secrets/` file ask for confirmation. Best effort, not DLP.

## DEC-005: Companion design plugins as dependencies, anti-slop skills bundled

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — dependencies plus bundled copies where there is no plugin · B — copy everything · C — only check and print install commands.
**Choice:** A (maintainer's choice).
**Why:** `interfaces` and `web-design-skills` are maintained plugins: depending on them keeps them current. The two MengTo skills are loose folders, not a plugin, so they are copied with MIT attribution.
**Consequences:** the marketplace entry declares both dependencies with `allowCrossMarketplaceDependenciesOn`. `/setup-check` verifies and prints the install commands when a marketplace is missing. Copies must be refreshed by hand (see `wiki/sources.md`).

## DEC-006: A bug hunt at the end of every task, a whole-project hunt before every release

**Date:** 2026-11-23 · **Status:** [DECISION], partly superseded by DEC-014 (refutation instead of a second opinion)
**Options:** A — adopt Claude-BugHunter · B — a defensive `bug-hunter` agent with a proof gate, plus a Sonnet second opinion.
**Choice:** B.
**Why:** Claude-BugHunter is an offensive toolkit for third-party HTTP targets. Its 83 skills auto-load by topic and would pull attack payloads into normal feature work. Its "never stop, never ask" directive contradicts the gates, and its own eval shows no gain over the baseline. Its validation discipline is worth keeping and was adapted.
**Consequences:** `agents/bug-hunter.md` (Fable), `agents/sweeper.md` (Sonnet) for second opinions; `/bug-hunt`, `/fix-bug`; the release skill runs up to four hunters in parallel.

## DEC-007: Project skills live in `.claude/skills/`

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** v3 generating them in `skills/` at the project root
**Why:** Claude Code discovers project skills only in `.claude/skills/`. The v3 skills never loaded on their own. Their counters (maturity, tasks completed, connections) move under the `metadata:` map, which Claude Code supports for free-form data.

## DEC-008: Hooks are provided by the plugin only

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** v3 copying the guard scripts into each project's `.claude/hooks/`
**Why:** with both the plugin and the project copy wired, every guarded command asked twice and every edited file was formatted twice. The auto-format hook now runs only in projects that have a `.scaffolder/` folder.

## DEC-009: No `model:` on commands that run in the main conversation

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** the "phase commands set to Fable" half of DEC-002
**Options:** A — keep `model: fable` / `model: sonnet` on the commands · B — no model on interactive commands; read-only reports run as `context: fork` with a `model`.
**Choice:** B.
**Why:** a command whose `model` differs from the session's is a model switch: the next request re-reads the whole history with no cache hits, and the session model resumes on the next prompt anyway (`prompt-caching.md`, "Switching models"). The pin bought one turn on Fable at the price of an uncached re-read. A forked report runs in a subagent and leaves the main cache alone.
**Consequences:** routing holds only through the agents' frontmatter. The SessionStart banner names the model the flow is designed for and gives `/model fable`. User-only commands carry `disable-model-invocation: true`, which also takes their descriptions out of the per-turn listing; the skills they load never do.

## DEC-010: The loops ship as plugin workflows, with a main-session fallback

**Date:** 2026-11-23 · **Status:** [DECISION]; `improve-loop.js` and `idea-research.js` renamed `improve-segment.js` and `research-rounds.js` by DEC-017
**Options:** A — loops run as agent chains in the main session · B — `workflows/*.js` started by the skill that owns the questions.
**Choice:** B for release rounds (`release-rounds.js`), improvement (`improve-loop.js`) and research (`idea-research.js`).
**Why:** a workflow keeps intermediate results in script variables, not in the conversation, and `/workflows` shows progress and tokens per agent. A workflow cannot ask the user, so every question, the cost estimate and the caps come first, in the skill.
**Consequences:** workflows can be off (Pro until Dynamic workflows is on, `disableWorkflows`, `CLAUDE_CODE_DISABLE_WORKFLOWS`), so each skill keeps a fallback that runs the same agents one after another. Because reports then land in the conversation, the fallback is capped lower: 10 improvement iterations, 5 release rounds per session. A journal file per run makes both paths resumable. `/setup-check` reports which path applies.

## DEC-011: What the user sees comes from hooks, not from model text

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — an output style with `force-for-plugin` that tells the model to print a banner · B — a `statusLine` · C — a mod pane · D — hook output: SessionStart `systemMessage` and a `UserPromptExpansion` gate.
**Choice:** D.
**Why:** an output style is sent with every request and is not enforced; a `statusLine` is a settings key a plugin cannot ship, and VS Code is not confirmed to render it; a mod needs recent versions and can be turned off. A `systemMessage` and a block `reason` are shown to the user and never enter the model's context.
**Consequences:** `hooks/command-gate.sh` refuses a typed phase command that comes too early, before its body loads; when Claude starts a command itself, `phase-guard.sh` still refuses the early writes. The session model goes only into the `systemMessage`, so `additionalContext` stays stable for the prompt cache. A mod remains a candidate (see `claude-code-changelog.md`).

## DEC-012: Behaviour evals for the gates, without shell grants

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — hook unit tests only · B — add `claude plugin eval` cases that push against each gate in a real session.
**Choice:** B, next to `tests/test-hooks.sh`.
**Why:** the unit tests prove each script, not that skill and hook together hold under a prompt that pushes against them.
**Consequences:** three cases in `evals/`, granting only `Write` and `Edit`, because native Windows has no sandbox for `Bash` or `PowerShell` grants. Shell-guard cases need WSL2 or Linux. The cases cost model usage, so they run before a release, not on every commit.

## DEC-013: The guards fail closed and follow the hook input's `cwd`

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — guards fail open (a crash lets the call through) and find the project from `CLAUDE_PROJECT_DIR` · B — `onFailure: "block"` on the three PreToolUse guards; the project is the nearest `.scaffolder/phase` above the input's `cwd`, `CLAUDE_PROJECT_DIR` the fallback.
**Choice:** B.
**Why:** a guard that crashed or lost its rules passed everything silently, and a worktree or subfolder was judged by the wrong phase or none. `onFailure` needs 2.1.295, below the `engines` floor.
**Consequences:** on Windows without Git Bash every Bash, PowerShell, Write, Edit, NotebookEdit and Artifact call is refused; `/setup-check` gives the fix and the recovery. `session-start`, `pre-compact`, `command-gate` and `auto-format` stay fail-open: they inform, they do not guard. Phase state follows a worktree only when `.scaffolder/phase` is committed.

## DEC-014: Every finding is refuted before it counts

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** the Sonnet "second opinion" of DEC-006
**Options:** A — a second agent follows the reproduction and confirms · B — a second agent tries to refute: it re-derives the finding with its own commands; uncertain counts as refuted; a check that could not run never confirms.
**Choice:** B, for the end-of-task hunt, `/bug-hunt`, the release rounds and the improvement loop's verifier.
**Why:** a confirming pass inherits the hunter's framing and tends to agree; plausible but wrong findings each cost a fix round.
**Consequences:** the sweeper keeps one re-check job (refutation). Reports and pipeline lines carry `confirmed`, `refuted`, `unverified`; a release round with an unverified re-check is never dry.

## DEC-015: Read-only scripts instead of reading files into context

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — the model opens each file and derives the facts · B — bundled bash scripts print fixed-format facts, pre-approved through each skill's `allowed-tools`.
**Choice:** B: `phase-status.sh`, `session-brief.sh`, `session-close.sh`, `wiki-report.sh`, `pipeline-stats.sh`, `verify.sh`, `contrast.sh`.
**Why:** the facts are the same every time and cost one short output instead of several file reads; budgets and contrast ratios are computed, not estimated.
**Consequences:** the scripts depend on markers written elsewhere (`phase | Foundation complete`, the registry tables, `> Status:`, the pipeline line format), so both sides change together. Each skill keeps a by-hand fallback for sessions without Git Bash. `tests/test-hooks.sh` covers the scripts, and `.gitattributes` keeps every `*.sh` LF.

## DEC-016: Generated projects carry their context in small, scoped pieces

**Date:** 2026-11-23 · **Status:** [DECISION] · **Refines:** DEC-004
**Options:** A — one large `CLAUDE.md` with every convention · B — a pointer-index `CLAUDE.md`, path-scoped `.claude/rules/`, a `project-overview` code map, a `verify` skill and a shared `.claude/settings.json`.
**Choice:** B.
**Why:** `CLAUDE.md` loads into every session and subagent, while a rule loads only on a matching path and `@` imports save nothing; a skill named `verify` makes Claude Code run its checks before each commit; the shared settings bring the plugin's guards to every clone.
**Consequences:** `secrets/` stays readable by default (DEC-004). Phase 2 offers an opt-in `Read(./secrets/**)` deny rule, recorded as the project's DEC-003, and the hub teaches loading keys in the shell so values never enter the transcript.

## DEC-017: One name per component

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — keep the skill `bug-hunt` beside the command `/bug-hunt`, and workflows named like their skills · B — distinct names.
**Choice:** B: the skill `debugging`; the workflows `improve-segment` and `research-rounds` beside the skills `improve-loop` and `idea-research`.
**Why:** skills, commands and workflows all answer to `/project-scaffolder:<name>`. The docs say which one wins only for project-level skills and command files, so a shared name could load the wrong component, for example a workflow without its arguments.
**Consequences:** command names are unchanged (DEC-003). `CLAUDE.md` carries the rule.

## DEC-018: Compaction keeps state through a PreCompact snapshot

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — the user types a `/compact` focus line and the handoff is the only record · B — a PreCompact hook flushes facts read from disk to `.scaffolder/compact-snapshot.md` and hands the summary its keep-list; SessionStart on `compact` points the new context at it.
**Choice:** B.
**Why:** a summary blurs ids, verdicts and the exact next step; facts read from disk do not, and the user no longer has to remember a focus line.
**Consequences:** plain `/compact` is the default. The snapshot is git-ignored through `.scaffolder/.gitignore`, `/session-start` flags a handoff older than it, and the hook never blocks a compaction.

## DEC-019: A project notebook separate from the committed queue

**Date:** 2026-11-23 · **Status:** [DECISION], partly superseded by DEC-021 (no `wiki/todo.md` write in phase 1)
**Options:** A — add loose items to `wiki/priorities.md` · B — a separate `wiki/todo.md` inbox (`/todo`, skill `backlog`) with one parsable line per item, read through a script, feeding `/milestone-plan`.
**Choice:** B.
**Why:** the maintainer wants advice, ideas and checks never run kept as a priority list for the next plan. Mixed into `priorities.md` they would break its 100-line cap and blur what is committed for the milestone; a script-read inbox costs no context until it is asked for.
**Consequences:** deferred MEDIUM/LOW findings, persona frictions, release leftovers and session loose ends go to `wiki/todo.md`; the file exists from phase 2 (the phase guard keeps phase 1 to the brief and `raw/`, where loose ends go under the brief's Open questions); lines are never deleted, so the page has no size cap.

## DEC-020: The secrets guard covers every outward tool

**Date:** 2026-11-23 · **Status:** [DECISION]
**Options:** A — guard shell, file writes and the Artifact page only · B — also MCP tools, WebFetch/WebSearch, messages to other sessions, and every file an Artifact publish carries.
**Choice:** B.
**Why:** the maintainer's rule is that secrets are never published online anywhere; a GitHub, mail or docs connector, or an Artifact's supporting file, was an open way out.
**Consequences:** in projects with `secrets/`, each such call scans its input and the files it names (the session's transcript path excluded). Reading `secrets/` stays allowed (DEC-004).

## DEC-021: Phase 1 stays brief-and-raw only; the notebook starts in phase 2

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** the phase-1 consequence of DEC-019
**Options:** A — the phase guard allows `wiki/todo.md` in the brainstorm · B — the brainstorm writes only the brief and `raw/`; items for later go under the brief's Open questions (solutions to `raw/parking-lot.md`), and `/2-foundation` seeds the notebook from them.
**Choice:** B (regression review of the improvement branch).
**Why:** A created `wiki/` before phase 2 and contradicted DEC-001, the brainstorm skill ("do not create the wiki now"), the session bootstrap, `/1-brainstorm`, the README and the `no-wiki-yet` eval grader. Phase 1 already has two capture places, so nothing is lost.
**Consequences:** `tests/test-hooks.sh` expects a deny for `wiki/todo.md` in phase 1. Same review: the secrets guard's outward check reads the secret values once and checks named files in batches (60 files went from about 40 s, past the 15 s timeout that refuses the call, to about 1 s).

## DEC-022: The command gate checks gate facts, read by the /phase-status script

**Date:** 2026-11-23 · **Status:** [DECISION] (v4.1.1, T-001)
**Options:** A — the gate checks only the phase word; the approved brief and the closed design phase are checked by the skills' instructions · B — the gate also refuses `/2-foundation` without `status: approved` and `/4-build` without `phase | Design complete` (unless `has_interface: no`), with its own parsing · C — as B, reading the facts from `phase-status.sh --facts`.
**Choice:** C.
**Why:** the blind judge on 4.1.0 found both steps passing on instructions alone. A second parser of the brief and the log would drift from the one `/phase-status` shows the user; one script keeps the report and the refusal in agreement.
**Consequences:** `2-foundation` joins the `UserPromptExpansion` matcher. After the Fable review: `--upgrade` has no exemption (a v3 project has no phase file and passes anyway; `upgrade.md` refuses when one exists); `/3-design` and `/4-build` from phase 2 also need `phase | Foundation complete`; `design=complete` needs the registry clean as well as the log line; the brief's values are compared exactly after stripping quotes, in the report and the gate alike. The fact gates apply only to the step forward from brainstorm, foundation or design. The gate still fails open: without the script it falls back to the phase check.

## DEC-023: Keys never ship; the release gate scans the build with the guard's own secret map

**Date:** 2026-11-23 · **Status:** [DECISION] (v4.1.1, T-003)
**Options:** A — the guard's repository checks are enough · B — a release-gate grep with its own idea of a secret · C — `ps_secret_map` moves to `hooks/secrets-lib.sh`, sourced by the guard and by `skills/release/scripts/build-secrets.sh`, which scans the build output and prints file and variable names only.
**Choice:** C, plus an architect rule: a client-only product that needs a keyed service gets a proxy or a keyless service.
**Why:** a key read at build time (a bundler env prefix) lands in the files users download, where no guard looks; two recognisers would disagree on what a secret is.
**Consequences:** a `leak:` line is a CRITICAL release finding (fix, rotate, rebuild). The script exits 2 (`NOT CHECKED`), never "clean", when a key file cannot be read in full (sandbox, UTF-16, 256 KiB+), nothing is built, a path lies outside the project or inside `secrets/`, or `.env.example` names keys and no `secrets/` exists; it finds the project root itself (no `--project`, so it cannot be pointed at a decoy folder) and takes the main checkout's `secrets/` from a worktree. The loading command gains `2>/dev/null` so a malformed line is never echoed. `wiki/tech-stack.md` records the build output folder at the platform decision. The guard fails closed without `secrets-lib.sh`.

## DEC-024: Blocking reads of `secrets/` is the recommended answer in phase 2

**Date:** 2026-11-23 · **Status:** [DECISION] (v4.1.1, T-005) · **Refines:** DEC-004, DEC-016
**Options:** A — Readable recommended, Block reads opt-in (4.1.0) · B — Block reads recommended, keys loaded in the shell (`set -a; . secrets/<file>.env; set +a; <command>`), Readable still offered.
**Choice:** B.
**Why:** whatever Claude reads lands in the transcript; loading a key inside the command that uses it needs no read at all. DEC-004's purpose (keys usable locally) holds either way.
**Consequences:** the foundation explains the trade-off and checks that loading still works once a key file is in place; when a sandbox applies the rule to every process, it says so and offers Readable. `phase-flow` states the shell-loading rule for every phase.

## DEC-025: Phase commands stay under about 4.5k tokens at load

**Date:** 2026-11-23 · **Status:** [DECISION] (v4.1.1, T-004)
**Options:** A — keep 4.1.0's skills (3.5–5.8k tokens per phase command, against 2.8–4.5k in 4.0) · B — dispatch and AskUserQuestion rules only in `phase-flow`; steps that run once per project in files read when their case applies (`cortex/platform.md`, `design-studio/entry.md`, `phase-flow/fallback.md`); command bodies reduced to the pointer.
**Choice:** B.
**Why:** every phase command loads `phase-flow` plus its phase skill; the duplicated dispatch blocks and once-only steps were paid on every run and every resume.
**Consequences:** measure = bytes / 4 of the command, `phase-flow/SKILL.md` and the phase skill at the committed version (the method that reproduces the judge's figures). `/task`, `/milestone-plan` and `/milestone-close` now load `phase-flow` too, unless the session already has it. A change that pushes a phase command past ~4.5k moves text out, not in.

## DEC-026: The build scan checks names, and a sandboxed run is a first look only

**Date:** 2026-11-23 · **Status:** [DECISION] (v4.1.2, T-008) · **Refines:** DEC-023
**Options:** A — trust the in-session scan once it reads every key file as text · B — also require every key `.env.example` names to have its line in `secrets/`, and, with the Bash sandbox on and reads blocked, take the verdict from the user's own terminal.
**Choice:** B.
**Why:** the sandbox docs (code.claude.com/docs/en/sandboxing) say Read deny rules reach every process a sandboxed command starts, but not how a denied file looks to it. Empty, missing or unreadable files are now refused by the scan; a stand-in copy could not be told apart from a real file, so only a run outside the sandbox settles it. Native Windows has no sandbox, and hooks run outside it, so the guard always sees the real values.
**Consequences:** a key named in `.env.example` but not handed over makes the scan answer NOT CHECKED: the user drops the file in or removes the unused name. Tested in a git worktree (main checkout's `secrets/`) and with an emptied or removed key file.
