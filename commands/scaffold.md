---
name: scaffold
description: Generate a complete project structure from a brief. Creates CLAUDE.md, wiki, skills, guardrails, and handoff — everything needed to start building.
---

# /scaffold

Run the project-scaffolder skill to generate a complete project knowledge base from a user brief.

## Usage

```
/scaffold [your project brief]
/scaffold --mode [normal|autopilot|autonomous] [your project brief]
```

## Interaction Modes

| Mode | Flag | Behavior |
|------|------|----------|
| **Normal** | `--mode normal` | Asks all questions. Best for first-time users. (Default) |
| **Autopilot** | `--mode autopilot` | Asks only critical questions (~50% fewer). Makes reasonable defaults. |
| **Autonomous** | `--mode autonomous` | Zero questions. Makes all decisions independently. Maximum speed. |

If no mode is specified, the scaffolder will ask you to choose.

## Examples

```
/scaffold Mobile app for tracking gym workouts. Target: fitness enthusiasts. Flutter.
```

```
/scaffold --mode autopilot SaaS platform for restaurant reservations. React + Node. Target: Italian restaurant owners.
```

```
/scaffold --mode autonomous E-commerce site for handmade jewelry. Shopify + custom theme. Target: women 25-45.
```

## What it generates

1. **CLAUDE.md** — Central project hub read automatically by Claude Code
2. **Wiki (21+ pages)** — Karpathy-style persistent knowledge base
3. **Vertical skills** — Domain-specific coding patterns, marketing guides, release gates
4. **Guardrails** — Error prevention and anti-pattern documentation
5. **Design spec** — Complete project specification
6. **Handoff** — Session transition protocol for context preservation
7. **Daily log** — Work tracking template

## Extras

- **Caveman** — Automatically installs the [Caveman](https://github.com/JuliusBrussee/caveman) plugin for ~65% token savings
- **Interaction mode** — Written into the generated CLAUDE.md so ALL future sessions respect your preferred level of autonomy

After scaffolding, start building with: `claude` → "Proceed with Phase 1"
