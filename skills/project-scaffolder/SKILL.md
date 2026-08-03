---
name: project-scaffolder
description: Use when starting ANY new project from a user brief. Generates the complete project structure automatically — CLAUDE.md hub, Karpathy-style wiki (12 core pages + on-demand), vertical skills, guardrails, handoff protocol, design spec, and implementation plan. Also triggers on "new project", "setup project", "scaffolding", "scaffold", or when a user provides a project brief/description.
---

# Project Scaffolder — Master Skill

## Overview

Automates the creation of an entire project knowledge base from a user brief. Generates a Karpathy-style persistent wiki, domain-specific vertical skills, a CLAUDE.md hub, guardrails, and a structured handoff — everything needed so that Claude Code can start building immediately with full context.

**In one sentence:** From brief to "claude → proceed with Phase 1" in a single session.

## Why This Exists

Without structured context, AI coding agents waste 60-70% of tokens re-explaining the project, repeat solved errors, and produce inconsistent code across sessions. This skill solves that by creating a persistent knowledge layer that survives between sessions.

**Key insight:** The wiki is the memory between sessions. The chat is temporary working memory. This skill builds the long-term memory.

## When to Use

- User provides a brief for a new project
- User says "new project", "setup", "scaffolding", "let's start a project"
- User wants to restructure an existing project with this methodology
- The `/scaffold` command is invoked

## Required Input

A brief from the user containing AT LEAST:
- **What:** description of the app/product/service
- **Who:** target user/audience

Everything else can be discovered during brainstorming.

---

## Interaction Mode

The scaffolder supports three interaction modes that control how much Claude asks during the entire project lifecycle — not just scaffolding, but all subsequent development sessions.

### Mode Selection

At the start of scaffolding, ask the user:

> **How should Claude interact during this project?**
> 1. **Normal** — Asks all questions (best for learning and first-time users)
> 2. **Autopilot** — Asks only critical questions (~50% fewer interruptions)
> 3. **Autonomous** — Makes all decisions independently (zero questions, maximum speed)

If the user specifies mode via command flag (e.g., `/scaffold --mode autopilot`), skip the question.

**Default:** Normal (if the user doesn't specify or skips).

### Mode Behavior Matrix

| Situation | Normal | Autopilot | Autonomous |
|-----------|--------|-----------|------------|
| Missing domain/target/stack | Ask | Ask | Infer from brief, tag `[HYPOTHESIS]` |
| Business model unclear | Ask | Use "Freemium" default | Use "Freemium" default |
| Architecture decisions | Ask with options | Decide, document as `[DECISION]` | Decide, document as `[DECISION]` |
| UI/UX style choices | Ask | Decide based on domain conventions | Decide based on domain conventions |
| Database choice | Ask with pros/cons | Choose best fit, document rationale | Choose best fit, document rationale |
| Testing strategy | Ask | Use minimal strategy (unit on business logic) | Use minimal strategy |
| Ambiguous requirements | Ask for clarification | Make reasonable assumption, tag `[HYPOTHESIS]` | Make reasonable assumption, tag `[HYPOTHESIS]` |
| Naming conventions | Ask | Use industry standard | Use industry standard |
| Phase 1 scope | Ask for confirmation | Propose and proceed | Propose and proceed |
| Critical blocker (no way to infer) | Ask | Ask | Ask (even Autonomous stops for true blockers) |

### How Mode Propagates

The selected mode is written into the generated `CLAUDE.md` as a project-level setting:

```markdown
## Interaction Mode: [Normal|Autopilot|Autonomous]

> **[DECISION] DEC-002** — This project uses [mode] interaction mode.

**What this means:**
- [Normal] Claude asks questions before making decisions. Best for learning and control.
- [Autopilot] Claude asks only critical questions (~50% fewer). Makes reasonable defaults for the rest. All autonomous decisions are tagged [HYPOTHESIS] or [DECISION] with rationale.
- [Autonomous] Claude makes all decisions independently. Zero questions unless truly blocked. Every decision is documented in wiki/product/decisions.md with alternatives considered.

To change mode: edit this section and update the mode name.
```

### Mode Rules for Subsequent Sessions

These rules are injected into the generated CLAUDE.md operative rules:

**Normal mode additions:**
- Before every non-trivial decision, present options and ask.
- Confirm Phase transitions with the user.
- Ask before adding dependencies or changing architecture.

**Autopilot mode additions:**
- Only ask when: (a) the decision is irreversible, (b) the brief is genuinely ambiguous with no reasonable default, or (c) there's a cost/security implication.
- For everything else: decide, document in `wiki/product/decisions.md`, tag `[DECISION-AUTO]`.
- At end of session, include a "Decisions made this session" summary in the daily log.

**Autonomous mode additions:**
- Never ask questions unless truly blocked (no possible inference).
- Every decision documented in `wiki/product/decisions.md` with tag `[DECISION-AUTO]`.
- Use `[HYPOTHESIS]` liberally for uncertain inferences.
- At end of session, produce a "Full Decision Log" in the daily log listing every autonomous decision made.
- If a decision turns out wrong later, document in `guardrails/errors-to-avoid.md` and adjust.

---

## Token Diet (v3)

No compression layers. Token savings are structural:

1. **Core wiki only** — 12 files always generated (see Phase 5); everything else on-demand.
2. **Injection budgets** — the Cortex injects ≤5k tokens of context per subagent (see cortex skill); persona-lab has the same cap.
3. **One report per task** — chat gets ≤10 lines; the pipeline log holds the full record.
4. **Execution Doc token estimates** — cost is planned per activity, not discovered.

---

## The Automated Flow

```
BRIEF → ANALYZE → BRAINSTORM → SPEC → STRUCTURE → WIKI → SKILLS → VERIFY → HANDOFF
```

Total time: 15-40 minutes depending on project complexity.

---

## Phase 1: Analyze Brief (automatic)

Read the brief and extract:

| Element | How to find it | Default if missing |
|---------|---------------|-------------------|
| Domain | From brief context | Ask the user |
| Tech stack | Mentioned or inferred | Ask: mobile/web/API? |
| Target user | From brief | Ask the user |
| Business model | Mentioned | Freemium (safe default) |
| Project name | Mentioned | Ask the user |
| UI language | From context | English (or user's language) |
| Primary language | From user's message | Match user's language |

**Rule (Normal/Autopilot):** If domain, tech stack, or target are missing, ask ONLY those (max 3 questions). For everything else, use reasonable defaults and document assumptions as `[HYPOTHESIS]`.

**Rule (Autonomous):** Never ask. Infer domain, tech stack, and target from the brief. If genuinely impossible to infer, use the safest default (e.g., Flutter for mobile, React for web, Freemium for business model). Document every inference as `[HYPOTHESIS]` in the design spec.

### Scaffold execution options (v3.0.1 — workflow opt-in)

After classifying the project size (Simple / Medium / Complex, see Estimated Time), for **Medium and Complex** projects present the scaffold options with cost estimates BEFORE proceeding. The choice is always the user's — never launch multi-agent orchestration on your own.

| Option | How it runs | Est. tokens* | What you get |
|--------|-------------|--------------|--------------|
| **Standard scaffold** | This skill: brainstorm → spec → 2 parallel wiki agents → skills → verify | ~40–80k | Full knowledge base, sequential quality |
| **Orchestrated scaffold** | User types `use a workflow` — parallel agents for wiki, vertical skills, and technical workspace + a completeness critic at the end | ~120–250k (2–4×) | Same output, higher cross-file coherence, best for Complex projects (8+ skills) |

*Order-of-magnitude estimates — always shown before the choice. Log the decision as `[DECISION]` in `wiki/product/decisions.md` (DEC-003).

**Mode rule:** this question is CRITICAL — ask it in **Normal AND Autopilot** mode (Autopilot never skips it: cost is a user decision). Only in **Autonomous** mode choose Standard silently and log `[DECISION-AUTO]`.

For Simple projects: skip the question, use the standard scaffold.

---

## Phase 2: Brainstorming (use superpowers:brainstorming)

Run structured brainstorming on:

1. **Architecture** — layers, data models, dependencies, offline/online strategy
2. **UX/UI** — main flows, key screens, visual style, themes
3. **Business** — model, pricing, competitive positioning
4. **Technical** — patterns, conventions, testing strategy, deployment

### Assumption Surfacing (mandatory sub-step)

After brainstorming, BEFORE proceeding to Phase 3, explicitly list all assumptions made during the session. For each assumption:

| Assumption | Source | Confidence | Tagged |
|------------|--------|------------|--------|
| [What was assumed] | [Brief / inferred / convention] | [High/Medium/Low] | `[HYPOTHESIS]` or `[FACT]` |

**Rules:**
- Every inference not explicitly stated in the user's brief MUST be tagged `[HYPOTHESIS]`.
- Low-confidence assumptions in Normal/Autopilot mode → ask the user before proceeding.
- Low-confidence assumptions in Autonomous mode → proceed but document prominently in the design spec.
- This table is included in the design spec (Phase 3) under a dedicated "Assumptions" section.

**Why:** LLMs make silent assumptions and run with them (Karpathy). Surfacing them prevents building on wrong foundations.

Output: list of decisions made with alternatives considered + assumption table.

### Working Agreements interview (v3.0.3 — mandatory sub-step)

Before generating any file, collect the project's **standing operating rules** — how this user works, beyond this single project. One short message, 4 questions:

1. **Design pipeline** — where does design come from? (e.g. "Design is born in Claude Design; Claude Code ports it 1:1, never reinterprets. Missing design element mid-development → generate an update prompt for Claude Design and wait for the updated artifact")
2. **Generative models** — which models for images / video / voice, if the project produces media? (or n/a)
3. **Reference projects** — existing projects (paths) to reuse functionality from, and what to take
4. **Custom rules** — any other standing directive (approval flows, forbidden tools, cost limits)

**Mode behavior:** Normal and Autopilot ALWAYS ask (this is a critical question — these rules bind every future task). Autonomous fills sensible defaults tagged `[HYPOTHESIS]` and flags the section for user review.

The answers populate the "Working Agreements" section of the generated CLAUDE.md (template below). The Cortex injects this section into every specialist's context.

---

## Phase 3: Design Spec

Generate `docs/superpowers/specs/YYYY-MM-DD-[project-name]-design.md` with:

1. Project overview (elevator pitch, problem, solution, target)
2. Tech stack with rationale and rejected alternatives
3. Architecture (layers, data flows, primary data models)
4. Branding (name, positioning, tone of voice, themes if UI project)
5. Business model (pricing, tiers, conversion strategy)
6. Roadmap (5-6 phases from foundation to growth)
7. Constraints and risks
8. **Assumptions** (from Phase 2 Assumption Surfacing — full table with confidence levels and tags)
9. Skill ecosystem (list of skills to generate with justification)
10. Open decisions (things to resolve in Phase 1)

---

## Phase 4: Create Directory Structure

```bash
mkdir -p wiki/product wiki/debugging
mkdir -p skills/ guardrails/ daily-log/
mkdir -p docs/superpowers/specs docs/superpowers/plans
mkdir -p logs/pipeline logs/errors
```

Also create `docs/phases/` and copy the guardrail into the project so it is self-contained:

```bash
mkdir -p docs/phases .claude/hooks
cp "${CLAUDE_PLUGIN_ROOT}/hooks/deny-dangerous.sh" .claude/hooks/
cp "${CLAUDE_PLUGIN_ROOT}/hooks/dangerous-patterns.txt" .claude/hooks/
cp "${CLAUDE_PLUGIN_ROOT}/hooks/dangerous-patterns-case-sensitive.txt" .claude/hooks/
cp "${CLAUDE_PLUGIN_ROOT}/hooks/auto-format.sh" .claude/hooks/
```

Then write `.claude/settings.json` in the project:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/deny-dangerous.sh\"" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/auto-format.sh\"" }]
      }
    ]
  }
}
```

(If the file already exists, merge the hooks key instead of overwriting.)

---

## Phase 5: Generate Wiki (parallel subagents)

Launch 2 parallel subagents to create the core wiki files simultaneously:

### Agent 1 — Core + Operations (6 files)

| File | Content |
|------|---------|
| `CLAUDE.md` | Central hub, ≤120 lines (template below) |
| `wiki/index.md` | Navigation map: 12 core pages + "on-demand" section listing pages created on first use |
| `wiki/overview.md` | Elevator pitch, problem, solution, target |
| `wiki/priorities.md` | Phase tasks with `→ VERIFY:` criteria (≤100 lines) |
| `wiki/handoff.md` | Session state template (≤80 lines) |
| `wiki/log.md` | Changelog with inception entry (append-only) |

### Agent 2 — Technical + Product (6 files)

| File | Content |
|------|---------|
| `wiki/architecture.md` | Layers, data flow, primary data model |
| `wiki/tech-stack.md` | Stack, rationale, rejected alternatives, verify/build/test commands |
| `wiki/product/roadmap.md` | Phases with feature lists and status |
| `wiki/product/decisions.md` | DEC-001..N with alternatives (append-only) |
| `wiki/debugging/known-errors.md` | Template for bug documentation |
| `guardrails/errors-to-avoid.md` | Template + any scaffolding errors |

### On-demand pages (created on first real use, never upfront)

`wiki/vision.md`, `wiki/glossary.md`, `wiki/branding.md`, `wiki/scripts.md`, `wiki/workflows.md`, `wiki/prompts.md`, `wiki/setup-claude-code.md`, `wiki/product/features.md`, `wiki/ux/ui-decisions.md`, `wiki/debugging/failed-experiments.md`, `wiki/incubator/raw-ideas.md`, `wiki/incubator/future-directions.md`

Rule: when a task first needs one of these, create it with meaningful content and add it to `wiki/index.md`. The index lists them upfront under "On-demand (not yet created)".

### Wiki page header rule (v3)

Every generated wiki page starts with `> last-verified: YYYY-MM-DD` on its first line after the title. `/wrap` and `/wiki-gc` maintain it.

### Synapse Map Initialization

After all wiki files and skills are generated, create the initial `skills/_synapse-map.md`:

1. Read all generated skills in `skills/`
2. Analyze shared concepts between skills (libraries, data models, domain concepts)
3. Generate the connection table
4. Set all `pending_notes` to 0
5. Leave "Recent Propagations" empty

Also create the history directory for each skill:
```bash
for skill_dir in skills/*/; do
  mkdir -p "${skill_dir}.history"
done
```

### Content Rules for All Wiki Files

- **Never empty.** Every file must have meaningful initial content from the brief/brainstorming.
- **Cross-linked.** Files reference each other where relevant.
- **Tagged.** Use `[FACT]`, `[DECISION]`, `[HYPOTHESIS]`, `[IDEA]`, `[DEPRECATED]` tags.
- **Decisions documented.** Every decision includes alternatives considered and why chosen.
- **Templates included.** Debug and incubator files include templates for future entries.
- **Verifiable tasks.** Every task in priorities.md must include a success criterion. Format: `- [ ] Task description → VERIFY: concrete test or evidence of completion`. Example: `- [ ] Implement login screen → VERIFY: test_login_success passes, screenshot matches mockup`.

---

## Phase 6: Generate Vertical Skills

Analyze the domain and tech stack to determine which skills are needed.

### Always Present (every project)

| Skill | Purpose |
|-------|---------|
| `[name]-release-gate` | 6-stage pre-release verification orchestrator (includes Simplicity Check) |
| `[name]-brand-voice` | Tone of voice, copy patterns, language rules |

### By Tech Stack

| Tech Stack | Skill | Key Content |
|-----------|-------|-------------|
| Flutter/Dart | `[name]-flutter-patterns` | Themes, state management, folder structure, model conventions |
| React/Next.js | `[name]-react-patterns` | Component patterns, hooks, state, routing, styling |
| Python/FastAPI | `[name]-python-patterns` | Project structure, API patterns, error handling, testing |
| Node/Express | `[name]-node-patterns` | Middleware, routing, error handling, validation |
| Swift/iOS | `[name]-swift-patterns` | Architecture (MVVM/MVC), SwiftUI patterns, Core Data |
| Vue/Nuxt | `[name]-vue-patterns` | Composition API, store, routing, component design |

### By Domain

| Domain | Skills | Key Content |
|--------|--------|-------------|
| Subscription tracking | `[name]-subscription-domain` | Renewal calculation, cost normalization, urgency classification |
| E-commerce | `[name]-product-catalog`, `[name]-payment-flow` | Product model, cart logic, payment integration |
| SaaS | `[name]-pricing-strategy`, `[name]-onboarding-flow` | Tier logic, trial flows, conversion triggers |
| Public API | `[name]-api-design`, `[name]-auth-security` | REST/GraphQL patterns, auth flows, rate limiting |
| Content/CMS | `[name]-content-model`, `[name]-seo-strategy` | Content types, taxonomy, SEO patterns |
| Social/Community | `[name]-social-features`, `[name]-moderation` | Feed algorithms, user interactions, content moderation |

### By Distribution Channel

| Channel | Skill | Key Content |
|---------|-------|-------------|
| Google Play Store | `[name]-play-store-launch` | ASO, screenshots, store listing, release management |
| Apple App Store | `[name]-app-store-launch` | App Store guidelines, review process, screenshots |
| Web (SPA/SSR) | `[name]-deploy-pipeline` | CI/CD, hosting, monitoring, rollback strategy |
| Web (SEO-dependent) | `[name]-seo-strategy` | Keyword strategy, technical SEO, content plan |

### Strategic (always present if business model exists)

| Skill | Key Content |
|-------|-------------|
| `[name]-product-strategy` | RICE scoring, competitor analysis, pricing experiments, feature evaluation |
| `[name]-growth-marketing` | Growth funnel, notification strategy, conversion triggers, metrics |

### Skill File Structure

Every skill MUST follow this format:

```markdown
---
name: [skill-name]
description: [When to use this skill — be specific about triggers]
maturity: seed
tasks_completed: 0
last_synapse_update: YYYY-MM-DD
connections: []
---

# [Skill Title]

## Overview
[What this skill covers and why it exists]

## [Domain-specific sections with:]
- Code patterns and templates
- Rules and conventions
- Anti-patterns (what NOT to do)
- Checklists for verification
- Examples with ✅ good and ❌ bad patterns

## Behavioral Rules (for technical skills only)

> Apply these rules every time you write or modify code in this domain.

1. **State assumptions before coding.** If the task is ambiguous in this domain, list what you're assuming and ask if uncertain.
2. **Minimum viable implementation.** Use the simplest pattern from this skill that solves the problem. Add complexity only when the requirement demands it.
3. **Surgical scope.** Changes must stay within the boundary of the current task. Don't refactor adjacent code, even if this skill shows a better pattern for it.
4. **Verify against this skill's checklist** before declaring the task complete.

## Common Mistakes
| Mistake | Fix |
|---------|-----|
| [mistake] | [how to fix] |
```

---

## Phase 7: Verify Structure

Run automated verification:

```bash
# Check all 12 core files exist
for f in CLAUDE.md wiki/index.md wiki/overview.md wiki/priorities.md \
  wiki/handoff.md wiki/log.md wiki/architecture.md wiki/tech-stack.md \
  wiki/product/roadmap.md wiki/product/decisions.md \
  wiki/debugging/known-errors.md guardrails/errors-to-avoid.md; do
  [ -f "$f" ] && echo "OK  $f" || echo "MISSING  $f"
done

# Check CLAUDE.md stays within the token-diet line cap
awk 'END{if(NR>120) print "FAIL CLAUDE.md >120 lines"; else print "OK lines"}' CLAUDE.md

# Cross-links: the Navigation table in CLAUDE.md lists bare wiki paths (no
# markdown [text](path) syntax), so a grep for that syntax is a no-op. The
# core-files loop above already checks every path referenced there — no
# separate link-resolution check is needed.

# Check all skills have valid frontmatter
for f in skills/*/SKILL.md; do
  head -5 "$f" | grep -q "^name:" && echo "OK  $f" || echo "NO FRONTMATTER  $f"
done

# Check v3 artifacts are present (Execution Doc gate + guardrail hooks)
[ -d docs/phases ] && [ -f .claude/hooks/deny-dangerous.sh ] && [ -f .claude/settings.json ] && echo "OK v3 artifacts"
```

All checks must pass before proceeding.

---

## Phase 8: Prepare Handoff

Update these files to be ready for Phase 1:

| File | Update |
|------|--------|
| `wiki/handoff.md` | Phase 0 complete, Phase 1 tasks listed, setup instructions, files to read |
| `wiki/priorities.md` | Phase 0 marked complete, Phase 1 tasks with checkboxes |
| `daily-log/YYYY-MM-DD.md` | Summary of scaffolding work, decisions made, metrics |
| `wiki/log.md` | Project inception entry with key decisions |

---

## CLAUDE.md Template

The CLAUDE.md is the most critical file. It MUST contain:

```markdown
# [Project Name] — Project Hub

> Read at the start of every session. Hub only: details live in the wiki.
> last-verified: YYYY-MM-DD

## What is [Project Name]?

[2-3 lines: what, target, positioning, business model, tech stack]

- **Current phase:** Phase N — [name]
- **Interaction mode:** [Normal|Autopilot|Autonomous] (DEC-002)
- **Context threshold:** 300k

## Navigation (12 core pages)

| File | Contents |
|------|----------|
| wiki/index.md | Full map + on-demand pages list |
| wiki/overview.md · priorities.md · handoff.md · log.md | Product & session state |
| wiki/architecture.md · tech-stack.md | Technical foundation |
| wiki/product/roadmap.md · decisions.md | Direction & history (append-only) |
| wiki/debugging/known-errors.md · guardrails/errors-to-avoid.md | Hard-won lessons |

## Task Pipeline (v3)

1. **No work without an Execution Doc:** `/phase-doc` generates `docs/phases/PHASE-{N}-execution.md` (activities, model routing, VERIFY criteria). `/task` refuses to run without it.
2. `/task <description>` — full pipeline: classify → execute → QA → test → learn.
3. Models per activity follow the Execution Doc routing (Fable: long multi-file work; Opus: architecture; Sonnet: medium tasks; Haiku: mechanical).
4. Activities marked Parallel=yes can run in separate worktrees (`claude --worktree`).
5. Complex tasks: the Cortex presents execution options (standard pipeline / multi-agent workflow / decomposition) with token estimates — your choice, logged in the Execution Doc. Multi-agent runs only if you type `use a workflow`.

## Working Agreements

> Standing operating rules — the Cortex enforces them on every task.

- **Design pipeline:** [from interview — e.g. Claude Design is the source of truth; port 1:1; missing element → update prompt for Claude Design]
- **Generative models:** [image → ..., video → ..., voice → ... — or n/a]
- **Reference projects:** [paths + what to reuse — or none]
- **Custom rules:** [other standing directives — or none]

## Context Rules

- **1 chat = 1 phase.** Above the context threshold: stop, update handoff, emit the continuation prompt (context-manager skill).
- Wrong path → `/rewind` + re-prompt with the lesson. Between large tasks → `/clear` + brief.
- `/compact` always with a hint. Link wiki pages, don't paste them.

## Style Rules

- **Concise output:** one report per task, ≤10 lines in chat; the pipeline log holds the detail.
- **Comments like a senior human:** explain *why*, never the obvious *what*; match the file's density.
- **Performance:** measure before optimizing; no premature abstractions; watch N+1 queries, useless re-renders, I/O in loops.

## Coding Discipline (Karpathy)

1. **Think first:** state assumptions; ask when uncertain.
2. **Simplicity:** minimum code that solves the stated problem.
3. **Surgical:** touch only what the task requires; every changed line traces to the task.
4. **Goal-driven:** verifiable criteria before implementing; "done" only with evidence.

## Session Rules

- Start: read this file → wiki/handoff.md → wiki/priorities.md → guardrails/errors-to-avoid.md → skills/_synapse-map.md.
- End (`/wrap`): update handoff, priorities, daily-log; wiki hygiene pass (last-verified, line caps: CLAUDE.md ≤120, handoff ≤80, priorities ≤100).
- Every mistake becomes a rule: document in guardrails/errors-to-avoid.md (Synapse propagates it).
- History is never destroyed: `~~superseded~~` markers + `wiki/_archive/` (see `/wiki-gc`).
```

---

## Completion Checklist

Before declaring scaffolding complete:

- [ ] CLAUDE.md created
- [ ] 12 core wiki files (+ on-demand list in index) created with meaningful content (never empty)
- [ ] N vertical skills created with valid SKILL.md frontmatter
- [ ] guardrails/errors-to-avoid.md exists with template
- [ ] wiki/handoff.md ready for Phase 1
- [ ] wiki/priorities.md with Phase 1 tasks
- [ ] daily-log with today's file
- [ ] Design spec in docs/superpowers/specs/
- [ ] Structure verification passed: 12 core files exist + v3 artifacts present (docs/phases, .claude/hooks/deny-dangerous.sh, .claude/settings.json)
- [ ] Git init + first commit (if environment supports it)

---

## Estimated Time

| Project Type | Skills | Total Files | Time |
|-------------|--------|-------------|------|
| Simple (portfolio, landing page) | 3-4 | 16-18 | ~15 min |
| Medium (mobile app, SaaS) | 6-8 | 18-22 | ~25 min |
| Complex (marketplace, platform) | 8-12 | 22-28 | ~40 min |

---

## Release-Gate: Simplicity Check (Stage 6)

The generated `[name]-release-gate` skill MUST include a **Simplicity Check** as its final stage. This stage verifies:

| Check | Question | Fail if... |
|-------|----------|------------|
| Scope creep | Does the code implement ONLY what was in priorities.md? | There are features, abstractions, or error handling not traced to a task |
| Over-engineering | Could this be done with significantly less code? | A senior engineer would say "this is overcomplicated" |
| Dead code | Are there unused imports, functions, or variables? | Any dead code from this release exists |
| Speculative features | Are there config options, parameters, or flexibility that nobody asked for? | Yes — remove them |

**Pass criteria:** All 4 checks pass. If any fail, fix before release.

---

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Generate empty placeholder files | Every file needs meaningful content from the brief |
| Skip brainstorming and jump to wiki | Brainstorming decisions feed every wiki page |
| Write skills without code examples | Every technical skill needs actual code patterns |
| Forget cross-links between files | Files reference each other; CLAUDE.md links everything |
| Skip the verification phase | Always verify files exist and links resolve |
| Leave handoff empty | Handoff must list specific Phase 1 tasks |
| Use English in an Italian project | Match the project's primary language everywhere |
| Implement speculative features | Write only the minimum code that solves the stated problem (Karpathy) |
| Make silent assumptions | Surface all assumptions explicitly, tag as `[HYPOTHESIS]` |
| Improve adjacent code during a fix | Touch only what the current task requires (Surgical Changes) |
