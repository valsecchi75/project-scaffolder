---
name: persona-lab
description: Use after QA passes to simulate end-user testing with diverse profiles. Triggered by Cortex for tasks that impact UI, user flows, or user-facing text. Do NOT use for backend-only or infrastructure tasks. Also triggers on "test with users", "user simulation", "persona test", or "UX validation".
---

# Persona-Lab — The Simulated Focus Group

## Overview

Persona-Lab simulates diverse end-user profiles testing the implemented feature, catching UX problems that code review misses. It operates at code-level understanding — reading widget/component code, evaluating text labels, tracing navigation flows — not rendered pixels.

**Core principle:** If a low-tech user can't complete the flow, the implementation isn't done.

**Important limitation:** Persona-Lab cannot see rendered UI. It evaluates UX through code structure, text content, and flow logic. Visual issues (alignment, color contrast, spacing) belong to QA or manual review.

## When to Run

| Task type | Run Persona-Lab? |
|-----------|-----------------|
| UI feature (new screen, flow) | Yes — full 3-persona test |
| UI modification (copy, layout) | Yes — 2 personas (low-tech + high-tech) |
| Backend/API (no UI) | No |
| Infrastructure/devops | No |
| Bug fix (UX-related) | Yes — 1 persona matching bug reporter profile |
| `--skip-persona` flag | No |

## Inputs from Cortex

Persona-Lab receives this context:

| Input | Source | Purpose |
|-------|--------|---------|
| Task description | `/task` command | What was implemented |
| Files changed (list) | Specialist output | Scope of change |
| Feature description | `wiki/product/features.md` excerpt | Feature context |
| UI flow context | `wiki/ux/ui-decisions.md` excerpt | Navigation patterns |
| Brand/tone rules | `wiki/branding.md` excerpt | Language expectations |
| Relevant widget code | Changed UI files | Actual implementation |

## Profile Generation

Read project context to generate relevant personas:
- `wiki/overview.md` — target user description
- `wiki/ux/ui-decisions.md` — UX principles
- `wiki/branding.md` — tone and visual identity
- `wiki/product/features.md` — feature context

Generate **3 personas** with varying attributes:

| Attribute | Variation range |
|-----------|----------------|
| Tech proficiency | Low → High |
| Age range | Young → Senior |
| Usage context | Casual → Power user |
| Accessibility needs | None → Screen reader, large fonts |
| Patience level | Impatient → Methodical |

**Persona naming:** Give each persona a first name and archetype label (e.g., "Marco, tech-savvy power user"). This makes feedback reports readable.

## Testing Process

For each persona:

1. **Read changed widget/component code** — understand the information hierarchy (what the user sees)
2. **Trace navigation flow** — which screen leads where, what taps/clicks do
3. **Evaluate text** — labels, buttons, error messages, empty states against the persona's profile
4. **Count steps** — how many taps/actions to complete the flow
5. **Identify friction** — points where THIS persona would be confused, blocked, or frustrated
6. **Check error recovery** — what happens if the persona makes a mistake

## Report Format

```markdown
## Persona-Lab Report — [Task Name]
**Date:** YYYY-MM-DD | **Skill:** [skill-used] | **Verdict:** PASS/FAIL

### Persona 1: [Name] ([archetype])
- **Profile:** [age, tech level, context, needs]
- **Flow:** [steps taken]
- **Result:** ✅ Completes / ❌ Blocked at step N
- **Frictions:** (if any)
  - [severity emoji] [description]
- **Suggestions:** [actionable improvements]

### Persona 2: ...
### Persona 3: ...

### Summary
- Blocking issues: N
- Frictions: N
- Verdict: PASS / FAIL
- Recurring pattern: [if any friction repeats across personas]
```

## Severity Classification

| Level | Symbol | Meaning | Action |
|-------|--------|---------|--------|
| Blocking | 🔴 | Persona cannot complete the flow | Task returns to specialist |
| Friction | ⚠️ | Completes but with difficulty or confusion | If 3+ frictions across all personas → returns |
| Suggestion | 💡 | Minor improvement, not blocking | Logged for future iteration |
| Pass | ✅ | No issues for this persona | Continue |

**Majority vote rule:** A single friction from 1 persona = suggestion only. Must be 2+ personas experiencing the same friction, or any blocking issue, to trigger rework.

## Learning Feedback

Recurring friction patterns are passed to Synapse for propagation via the learning packet. Example: if the low-tech persona consistently struggles with English terminology, Synapse propagates to the brand-voice skill as reinforcement.

## Logging

After testing, log to `logs/pipeline/YYYY-MM-DD.md` under the PERSONA-LAB section of the current task:

- **Each persona:** Name, archetype, result (PASS/BLOCKED/friction), step where blocked (if applicable)
- **Verdict:** PASS or FAIL with reasoning
- **Recurring pattern:** If the same friction appears across personas, note it

On FAIL (blocking issue or 3+ frictions): also log to `logs/errors/YYYY-MM-DD-errors.md` with the specific frictions that caused the failure and feedback sent to specialist.

See `skills/pipeline-logger/SKILL.md` for complete log format.

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Flag visual/pixel issues | Only evaluate code structure, text, and flow logic |
| Use the same 3 personas every time | Regenerate personas based on task context |
| Flag a friction from 1 persona as blocking | Use majority vote: 2+ personas or 🔴 blocking required |
| Write vague feedback ("UX is confusing") | Be specific: which step, which text, which persona, why |
| Test backend-only changes | Skip for non-UX tasks |
| Skip logging persona results | Always log every persona test for pattern analysis |
