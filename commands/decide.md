---
name: decide
description: Document a design or product decision with structured rationale. Appends to wiki/product/decisions.md with auto-incremented ID.
---

# /decide

Record a decision with its context, alternatives, and rationale.

## Usage

```
/decide <short title>
```

## Examples

```
/decide Switch from SQLite to Isar for subscription storage
/decide Require biometric auth for premium tier
/decide Freemium model with 5-subscription free cap
```

## Prompt flow

Guide the user through:

1. **Problem:** what question does this decision answer?
2. **Options considered:** minimum 2 alternatives, each with pros/cons
3. **Decision:** which option, in one sentence
4. **Rationale:** why this option beats the others
5. **Consequences:** what becomes true; what is closed off
6. **Status:** tag `[DECISION]` or `[HYPOTHESIS]` (if reversible)
7. **Supersedes:** if this replaces a prior decision, list the `DEC-NNN`

## Output

Append to `wiki/product/decisions.md`:

```
## DEC-NNN: <title>
**Date:** YYYY-MM-DD | **Status:** [DECISION|HYPOTHESIS] | **Supersedes:** DEC-XXX (if any)

**Problem:** ...
**Options:**
- Option A: ...
- Option B: ...
**Decision:** ...
**Rationale:** ...
**Consequences:** ...
```

If a superseded decision exists: edit `DEC-XXX` to add `~~Superseded by DEC-NNN~~` while preserving the original text.

## Rules

- Never delete prior decisions — always supersede.
- Minimum 2 options considered — if only one was evaluated, ask "what else did you consider?".
- Auto-increment `DEC-NNN` from the highest existing ID in the file.
- If no `wiki/product/decisions.md` exists: suggest `/scaffold` first.
