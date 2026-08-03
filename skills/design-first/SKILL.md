---
name: design-first
description: Use before executing the first operational task of a phase and any Complex task. Runs a structured design dialogue — questions one at a time, 2-3 approaches with trade-offs, sectioned design approval — before any code is written. The approved design may revise scaffold-era rules. Triggered by the Cortex (Step 3b) or explicitly with "design first" / "/task --design".
---

# Design First — The Design Gate

## Overview

Projects fail at execution when design questions surface mid-implementation. This skill forces the design conversation BEFORE the specialist writes code — and gives the approved design authority to revise decisions made at scaffold time, when knowledge was thinnest.

**Core principle:** the scaffold is an informed draft; the first operational design is where the rules truly settle.

## When the gate triggers (called by Cortex Step 3b)

| Condition | Behavior |
|-----------|----------|
| First operational task of the current phase | MANDATORY |
| Complexity = Complex | MANDATORY |
| Complexity = Medium | Proposed — user may skip with `--no-design` |
| Trivial | Skipped |

## The Design Dialogue

1. **Context read:** CLAUDE.md (including Working Agreements), `docs/phases/PHASE-{N}-execution.md`, the design spec, relevant wiki pages. Never ask what these already answer.
2. **Questions — ONE at a time, max 5.** Prefer multiple choice. Mode-aware: Normal asks all; Autopilot only the critical ones (irreversible choices, cost, genuinely missing requirements); Autonomous skips to step 3 and tags assumptions `[HYPOTHESIS]`.
3. **2-3 approaches with trade-offs** and an explicit recommendation, recommended option first.
4. **Sectioned design:** architecture of the change, data flow, error handling, verification plan. Ask after each section whether it looks right.
5. **Approval** → write `docs/design/TASK-{id}-design.md` (compact, ≤80 lines) → execution proceeds with the design as the specialist's primary context.

## Rule-Revision Authority (the key power)

The approved design MAY amend scaffold-era artifacts — with full traceability:

| Artifact | How |
|----------|-----|
| Execution Doc activities | Add / split / re-scope activities; update token estimates |
| `wiki/architecture.md`, `wiki/tech-stack.md` | Update affected sections; mark superseded content `~~strikethrough~~` |
| `wiki/product/decisions.md` | New DEC-NNN tagged `[DESIGN-REVISION]`, citing the superseded DEC |
| Working Agreements (CLAUDE.md) | Only with explicit user confirmation |

Never rewrite history: revisions add, supersede, and cite — they never erase.

## Outputs

- `docs/design/TASK-{id}-design.md` — the approved design; specialist, QA, and phase verification all check against it
- Updated artifacts per the table above
- Log entry in `logs/pipeline/`: gate trigger, questions asked, approach chosen, revisions made

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Ask questions the wiki already answers | Read first; ask only what is genuinely open |
| Present one approach as fait accompli | 2-3 approaches with trade-offs, explicit recommendation |
| Silently change scaffold decisions | New DEC with `[DESIGN-REVISION]` citing what it supersedes |
| Design forever | Max 5 questions; design doc ≤80 lines; then execute |
| Skip the gate on the phase's first task "because it's obvious" | The first task is where wrong scaffold assumptions surface cheapest |
