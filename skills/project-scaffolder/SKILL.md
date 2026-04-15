---
name: project-scaffolder
description: Use when starting ANY new project from a user brief. Generates the complete project structure automatically — CLAUDE.md hub, Karpathy-style wiki (21+ pages), vertical skills, guardrails, handoff protocol, design spec, and implementation plan. Also triggers on "new project", "setup project", "scaffolding", "scaffold", or when a user provides a project brief/description.
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

## Token Optimization: Caveman Integration

The scaffolder automatically integrates [Caveman](https://github.com/JuliusBrussee/caveman) for ~65% token reduction across all project sessions.

### Auto-Installation Flow

During Phase 4 (Create Directory Structure), the scaffolder runs:

```bash
# Check if Caveman is already installed
if ! claude plugin list 2>/dev/null | grep -q "caveman"; then
  echo "Installing Caveman plugin for token optimization..."
  claude plugin add JuliusBrussee/caveman
  echo "✅ Caveman installed — ~65% token savings active"
else
  echo "✅ Caveman already installed"
fi
```

**If installation fails** (network issues, permissions): log to `guardrails/errors-to-avoid.md`, continue without it. Caveman is an optimization, not a requirement.

### What Gets Added to CLAUDE.md

The generated CLAUDE.md includes a Token Optimization section:

```markdown
## Token Optimization

This project uses [Caveman](https://github.com/JuliusBrussee/caveman) for compressed communication.

**How it works:** Caveman compresses Claude's internal reasoning and file operations using abbreviated syntax, reducing token usage by ~65% without affecting output quality.

**Important:** Caveman affects HOW Claude processes, not WHAT it produces. All user-facing text, code, and documentation remain full quality.
```

### Caveman + Mode Synergy

| Mode | Caveman Benefit |
|------|----------------|
| Normal | Saves tokens on the many question/answer exchanges |
| Autopilot | Saves tokens on decision documentation (fewer questions = less overhead already) |
| Autonomous | Maximum savings — no question overhead + compressed reasoning. Best combined efficiency. |

**Recommended combination:** Autopilot + Caveman for experienced users. Autonomous + Caveman for maximum speed on well-defined projects.

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

---

## Phase 2: Brainstorming (use superpowers:brainstorming)

Run structured brainstorming on:

1. **Architecture** — layers, data models, dependencies, offline/online strategy
2. **UX/UI** — main flows, key screens, visual style, themes
3. **Business** — model, pricing, competitive positioning
4. **Technical** — patterns, conventions, testing strategy, deployment

Output: list of decisions made with alternatives considered.

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
8. Skill ecosystem (list of skills to generate with justification)
9. Open decisions (things to resolve in Phase 1)

---

## Phase 4: Create Directory Structure

```bash
mkdir -p wiki/product wiki/ux wiki/debugging wiki/incubator
mkdir -p skills/ guardrails/ daily-log/
mkdir -p docs/superpowers/specs docs/superpowers/plans
```

---

## Phase 5: Generate Wiki (parallel subagents)

Launch 3 parallel subagents to create all wiki files simultaneously:

### Agent 1 — Core + Operations (8 files)

| File | Content |
|------|---------|
| `CLAUDE.md` | Central hub with full navigation, skill list, operative rules, session rules |
| `wiki/index.md` | Complete navigation map linking all wiki pages |
| `wiki/overview.md` | Elevator pitch, problem, solution, target audience |
| `wiki/vision.md` | Product philosophy, guiding principles (5 max), tone of voice |
| `wiki/log.md` | Changelog with project inception entry |
| `wiki/glossary.md` | Domain-specific terms (8-12 terms) |
| `wiki/priorities.md` | Current phase tasks, next steps, blockers |
| `wiki/handoff.md` | Session state: what was done, what remains, files to read, template |

### Agent 2 — Technical + Design (7 files)

| File | Content |
|------|---------|
| `wiki/architecture.md` | Layer structure, data flow diagram, primary data model |
| `wiki/tech-stack.md` | Chosen stack, why, rejected alternatives, open decisions |
| `wiki/branding.md` | Name, positioning, tone examples, visual themes |
| `wiki/scripts.md` | Empty template for future scripts/utilities |
| `wiki/workflows.md` | CI/CD placeholder, development workflow |
| `wiki/prompts.md` | AI prompting documentation if relevant |
| `wiki/setup-claude-code.md` | Step-by-step setup guide for the project's dev environment |

### Agent 3 — Product + Debug + Incubator (9 files)

| File | Content |
|------|---------|
| `wiki/product/roadmap.md` | All phases with feature lists and status |
| `wiki/product/decisions.md` | All decisions from brainstorming (DEC-001 through DEC-N) |
| `wiki/product/features.md` | Detailed feature specs for Phase 1 |
| `wiki/ux/ui-decisions.md` | UI principles, onboarding flow, user journey |
| `wiki/debugging/known-errors.md` | Empty with template for bug documentation |
| `wiki/debugging/failed-experiments.md` | Empty with template for failed approaches |
| `wiki/incubator/raw-ideas.md` | 3-5 initial ideas from brainstorming |
| `wiki/incubator/future-directions.md` | 3-4 long-term explorations |
| `guardrails/errors-to-avoid.md` | Template + any errors encountered during setup |

### Content Rules for All Wiki Files

- **Never empty.** Every file must have meaningful initial content from the brief/brainstorming.
- **Cross-linked.** Files reference each other where relevant.
- **Tagged.** Use `[FACT]`, `[DECISION]`, `[HYPOTHESIS]`, `[IDEA]`, `[DEPRECATED]` tags.
- **Decisions documented.** Every decision includes alternatives considered and why chosen.
- **Templates included.** Debug and incubator files include templates for future entries.

---

## Phase 6: Generate Vertical Skills

Analyze the domain and tech stack to determine which skills are needed.

### Always Present (every project)

| Skill | Purpose |
|-------|---------|
| `[name]-release-gate` | 5-stage pre-release verification orchestrator |
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

## Common Mistakes
| Mistake | Fix |
|---------|-----|
| [mistake] | [how to fix] |
```

---

## Phase 7: Verify Structure

Run automated verification:

```bash
# Check all expected files exist
for f in CLAUDE.md wiki/index.md wiki/overview.md wiki/vision.md wiki/log.md \
  wiki/glossary.md wiki/priorities.md wiki/handoff.md wiki/architecture.md \
  wiki/tech-stack.md wiki/branding.md wiki/scripts.md wiki/workflows.md \
  wiki/prompts.md wiki/setup-claude-code.md wiki/product/roadmap.md \
  wiki/product/decisions.md wiki/product/features.md wiki/ux/ui-decisions.md \
  wiki/debugging/known-errors.md wiki/debugging/failed-experiments.md \
  wiki/incubator/raw-ideas.md wiki/incubator/future-directions.md \
  guardrails/errors-to-avoid.md; do
  [ -f "$f" ] && echo "OK  $f" || echo "MISSING  $f"
done

# Check all cross-links in CLAUDE.md resolve
grep -oP '\[.*?\]\(([^)]+)\)' CLAUDE.md | grep -oP '\(([^)]+)\)' | tr -d '()' | while read link; do
  [ -f "$link" ] || [ -d "$link" ] && echo "OK  $link" || echo "BROKEN  $link"
done

# Check all skills have valid frontmatter
for f in skills/*/SKILL.md; do
  head -5 "$f" | grep -q "^name:" && echo "OK  $f" || echo "NO FRONTMATTER  $f"
done
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

> This file is read at the start of every session.

## What is [Project Name]?

[Description from brief + brainstorming decisions]

- **Target:** [target user]
- **Positioning:** [one-liner]
- **Model:** [business model]
- **Tech stack:** [chosen stack]
- **Current phase:** Phase 1 — [phase name] (Phase 0 completed [date])

## Wiki Navigation

| Area | File | Contents |
|------|------|----------|
[Complete table linking ALL wiki files]

## Debugging & Guardrails

| Area | File | Contents |
|------|------|----------|
[Links to known-errors, failed-experiments, errors-to-avoid]

## Daily Log

Files in daily-log/ document daily work.

## Ideas & Incubator

| Area | File | Contents |
|------|------|----------|
[Links to raw-ideas and future-directions]

## Vertical Skills

[Table organized by category: Orchestrator, Technical, Marketing, Strategic]

## Specs & Plans

[Links to design spec and implementation plans]

## Session Rule: One Phase Per Chat

> **[DECISION] DEC-001** — Each development phase runs in a dedicated chat session.

**Why:** Long conversations degrade response quality (context rot).

**How it works:**
1. 1 chat = 1 phase. Never mix phases.
2. Structured handoff at end of session.
3. The wiki is the memory between sessions.
4. If context runs out mid-phase, update wiki and start fresh.

**End-of-session checklist (mandatory):**
- [ ] wiki/priorities.md updated
- [ ] daily-log/YYYY-MM-DD.md created/updated
- [ ] wiki/log.md updated if significant changes
- [ ] If phase complete: update wiki/product/roadmap.md
- [ ] If new decisions: document in wiki/product/decisions.md

## Operative Rules for Claude

### Every session
1. Read this file for context
2. Read wiki/handoff.md for last session state
3. Check wiki/priorities.md for what to do
4. Check guardrails/errors-to-avoid.md to avoid past mistakes
5. Verify you're in the correct phase

### While working
1. Before starting: update priorities with current task
2. During: document significant decisions in decisions.md
3. If you hit a bug: document in known-errors.md
4. If something fails: document in failed-experiments.md AND guardrails
5. End of session: create/update daily log

### Memory rules
- Never overwrite history (mark as ~~superseded~~)
- Preserve the why (alternatives considered)
- Failures = intelligence (every error deserves an entry)
- Tag certainty: [FACT], [DECISION], [HYPOTHESIS], [IDEA], [DEPRECATED]
- Daily log is mandatory
```

---

## Completion Checklist

Before declaring scaffolding complete:

- [ ] CLAUDE.md created and all links resolve
- [ ] 21+ wiki files created with meaningful content (never empty)
- [ ] N vertical skills created with valid SKILL.md frontmatter
- [ ] guardrails/errors-to-avoid.md exists with template
- [ ] wiki/handoff.md ready for Phase 1
- [ ] wiki/priorities.md with Phase 1 tasks
- [ ] daily-log with today's file
- [ ] Design spec in docs/superpowers/specs/
- [ ] Structure verification passed (all files + all links)
- [ ] Git init + first commit (if environment supports it)

---

## Estimated Time

| Project Type | Skills | Total Files | Time |
|-------------|--------|-------------|------|
| Simple (portfolio, landing page) | 3-4 | 25-28 | ~15 min |
| Medium (mobile app, SaaS) | 6-8 | 30-35 | ~25 min |
| Complex (marketplace, platform) | 8-12 | 35-45 | ~40 min |

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
