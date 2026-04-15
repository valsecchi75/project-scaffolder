# Project Scaffolder

**Automatically generate a complete project knowledge base from a single brief.**

One brief in, entire project structure out — CLAUDE.md hub, Karpathy-style wiki (21+ pages), domain-specific vertical skills, guardrails, handoff protocol, and implementation plans. Ready for Claude Code to start building immediately.

---

## The Problem

Every new software project starts from zero. Without structured context, AI coding agents:

- **Waste 60-70% of tokens** re-explaining the project each session
- **Repeat solved errors** because nobody documented them
- **Produce inconsistent code** across sessions (different patterns, naming, architecture)
- **Suffer context rot** — quality degrades in long conversations as the agent loses track of earlier decisions

The cost compounds: decisions made and forgotten get remade differently, bugs resurface, and the codebase diverges from its original vision.

## The Solution

Project Scaffolder creates a **persistent knowledge layer** that survives between sessions. It combines three proven patterns:

| Pattern | Inspiration | What It Does |
|---------|-------------|-------------|
| **Persistent Markdown wiki** | [Andrej Karpathy's gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) | Durable project memory: decisions, architecture, errors, priorities. Read automatically every session. |
| **Vertical skills** | Claude Code skills system | Specialized guides per area (frontend, domain logic, marketing, release). Contain reusable code patterns, rules, checklists. |
| **Structured handoff** | Original pattern | Session transition protocol that prevents context rot. One phase per chat, wiki as persistent memory. |

**Result:** The AI agent restarts every session with complete context in seconds, without wasting tokens.

## What It Generates

From a single brief like:

> "Mobile app for tracking digital subscriptions. Target: users who lose track of recurring charges. Flutter."

The scaffolder produces:

### 1. CLAUDE.md — Central Hub
The project's single source of truth. Read automatically by Claude Code at every session start. Contains navigation to all files, skill references, operative rules, and session management protocol.

### 2. Wiki — 21+ Interconnected Pages

| Section | Files | Purpose |
|---------|-------|---------|
| **Core** | overview, vision, glossary | Project identity: what it does, why it exists, shared vocabulary |
| **Product** | roadmap, decisions, features | What to build, in what order, why each choice was made |
| **Technical** | architecture, tech-stack, scripts, workflows, prompts | How it's built: structure, tools, automations |
| **Design** | branding, ux/ui-decisions | Visual identity, themes, interface principles |
| **Debug** | known-errors, failed-experiments | Error memory: what didn't work and why |
| **Incubator** | raw-ideas, future-directions | Unvalidated ideas, long-term explorations |
| **Operations** | priorities, log, handoff, setup | Current state, timeline, session transitions |

### 3. Vertical Skills — Domain-Specific Guides

Each skill is a `SKILL.md` with YAML frontmatter, containing code patterns, rules, checklists, and anti-patterns specific to one area. Skills are auto-selected based on your tech stack and domain:

**Always generated:**
- `release-gate` — 5-stage pre-release verification orchestrator
- `brand-voice` — Tone of voice, copy patterns, language rules
- `product-strategy` — RICE scoring, competitor analysis, feature evaluation

**By tech stack** (e.g., Flutter):
- `flutter-patterns` — Themes, state management, folder structure, model conventions

**By domain** (e.g., subscriptions):
- `subscription-domain` — Renewal calculations, cost normalization, validation rules

**By distribution** (e.g., Play Store):
- `play-store-launch` — ASO, store listing, release management

### 4. Guardrails
`errors-to-avoid.md` — Cumulative record of errors, traps, and anti-patterns. Prevents repeating mistakes across sessions.

### 5. Design Spec
Complete project specification derived from brainstorming: architecture, data models, business model, roadmap, and skill ecosystem.

### 6. Handoff Protocol
Structured session transition system. Each session ends by updating `handoff.md` with what was done, what remains, blockers, and which files the next session should read. The next session picks up instantly.

## Interaction Modes

Control how much Claude asks during scaffolding AND all subsequent development sessions.

| Mode | Questions | Best For |
|------|-----------|----------|
| **Normal** | All questions asked | First-time users, learning the methodology |
| **Autopilot** | Only critical questions (~50% fewer) | Experienced users who trust reasonable defaults |
| **Autonomous** | Zero questions (unless truly blocked) | Well-defined projects, maximum speed |

```
/scaffold --mode autopilot Mobile app for tracking expenses. Target: millennials. Flutter.
```

The mode is written into the generated `CLAUDE.md`, so every future session respects your preference. All autonomous decisions are documented in `wiki/product/decisions.md` with full rationale — nothing is lost, you just aren't interrupted.

**Recommended:** Autopilot for most users. Autonomous for experienced developers with clear project specs.

## Token Optimization (Caveman)

The scaffolder automatically installs the [Caveman](https://github.com/JuliusBrussee/caveman) plugin, which compresses Claude's internal reasoning by ~65% without affecting output quality.

| Mode + Caveman | Estimated Token Savings |
|----------------|------------------------|
| Normal + Caveman | ~65% on processing, standard question overhead |
| Autopilot + Caveman | ~70-75% total (fewer questions + compressed reasoning) |
| Autonomous + Caveman | ~80% total (zero questions + compressed reasoning) |

Caveman is installed automatically during scaffolding. If already installed, it's skipped. If installation fails (network, permissions), scaffolding continues without it.

## How It Works

```
User Brief
    │
    ▼
┌─────────────────┐
│  0. Mode         │  Select interaction mode (Normal/Autopilot/Autonomous)
│  1. Analyze      │  Extract domain, tech stack, target, business model
│  2. Brainstorm   │  Architecture, UX, business, technical decisions
│  3. Design Spec  │  Complete project specification
│  4. Structure    │  Create directories + install Caveman
│  5. Wiki         │  3 parallel agents generate 21+ wiki pages
│  6. Skills       │  Generate domain-specific vertical skills
│  7. Verify       │  All files exist, all links resolve
│  8. Handoff      │  Ready for Phase 1 development
└─────────────────┘
    │
    ▼
"claude" → "Proceed with Phase 1"
```

**Time:** 15 minutes (simple project) to 40 minutes (complex platform).

## Installation

### From GitHub

```bash
claude plugin add valsecchi75/project-scaffolder
```

### From local directory

```bash
claude plugin add /path/to/project-scaffolder
```

## Usage

### Option 1: Slash Command

```
/scaffold Mobile app for tracking gym workouts. Target: fitness enthusiasts. Flutter + Dart.
```

### Option 2: With Mode Flag

```
/scaffold --mode autopilot SaaS platform for restaurant reservations. React + Node. Target: Italian restaurant owners.
```

### Option 3: Natural Language

```
New project: E-commerce site for handmade jewelry. My customers are women 25-45 who value artisan quality.
```

The skill detects that you're starting a new project and activates automatically. If no mode is specified, you'll be asked to choose.

## After Scaffolding: The Daily Workflow

```
1. Open terminal
2. cd into project folder
3. claude
4. "Proceed with [what you need to do]"
5. Work...
6. "Update handoff and daily log"
7. /exit
```

The wiki maintains memory between sessions. Every time you reopen Claude Code, it knows exactly where you left off.

## Session Management: One Phase Per Chat

A key innovation of this methodology: **each development phase runs in its own chat session**.

**Why:** Long conversations degrade AI response quality (context rot). After thousands of tokens, the agent forgets earlier decisions, repeats mistakes, and produces declining-quality output.

**How:** At the end of each session, the agent updates `handoff.md`, `priorities.md`, and the daily log. The next session reads `CLAUDE.md` → `handoff.md` and starts fresh with complete context.

**Result:** Every session is as sharp as the first one.

## Measured Benefits

| Benefit | Without methodology | With methodology |
|---------|-------------------|-----------------|
| Project setup | 2-4 hours manual | 15-40 min automated |
| Tokens per session | 100% (baseline) | 30-40% (60-70% savings) |
| Code consistency | Degrades over time | Stable (skills as guardrails) |
| New session onboarding | 5-10 min of context | Automatic (CLAUDE.md + handoff) |
| Repeated errors | Frequent | Rare (documented guardrails) |
| Decision tracking | Lost in chat | Permanent in wiki |
| Parallelism | Sequential | Parallel subagents (3-5x faster) |

## Supported Project Types

| Type | Example Skills Generated |
|------|------------------------|
| **Mobile app (Flutter)** | flutter-patterns, [domain]-domain, brand-voice, growth-marketing, play-store-launch, release-gate |
| **Mobile app (React Native)** | react-native-patterns, [domain]-domain, brand-voice, app-store-launch, release-gate |
| **Web app (React/Next.js)** | react-patterns, [domain]-domain, brand-voice, seo-strategy, deploy-pipeline, release-gate |
| **API / Backend** | api-patterns, [domain]-domain, database-schema, auth-security, deploy-pipeline, release-gate |
| **E-commerce** | frontend-patterns, product-catalog, payment-flow, brand-voice, seo-strategy, release-gate |
| **SaaS** | frontend-patterns, [domain]-domain, pricing-strategy, onboarding-flow, growth-marketing, release-gate |

## Real-World Results

Tested on a production mobile app project (Android, Flutter, freemium model):

| Metric | Value |
|--------|-------|
| Files generated (Phase 0) | 33 |
| Wiki pages | 21 |
| Vertical skills | 8 |
| Documented decisions | 7 |
| Catalogued errors | 1 |
| Phase 0 time | ~1 session |
| Estimated token savings | 60-70% in subsequent sessions |

## Project Structure

```
project-scaffolder/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── commands/
│   └── scaffold.md           # /scaffold slash command
├── skills/
│   └── project-scaffolder/
│       └── SKILL.md          # Main scaffolding skill
└── README.md                 # This file
```

## Contributing

Found a domain or tech stack that's not covered? Want to improve a template?

1. Fork this repository
2. Add your domain/stack templates to the skill file
3. Test on a real project
4. Submit a pull request

## Credits

- **Methodology:** Developed by [@valsecchi75](https://github.com/valsecchi75)
- **Knowledge pattern:** Inspired by [Andrej Karpathy's Markdown wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- **Built with:** [Claude Code](https://claude.com/product/claude-code) by Anthropic
- **Skills system:** [Claude Code plugins](https://claude.com/plugins)

## License

MIT License — use it, fork it, improve it.
