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

**Date:** 2026-11-23 · **Status:** [DECISION] · **Supersedes:** the v3 Execution Doc routing table (Fable for long implementations, Opus for architecture, Haiku for mechanical work)
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

**Date:** 2026-11-23 · **Status:** [DECISION]
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

**Date:** 2026-11-23 · **Status:** [DECISION]
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
