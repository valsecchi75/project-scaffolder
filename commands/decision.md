---
description: Record a decision as a new DEC-NNN with options and reasons, superseding an older one without rewriting it.
argument-hint: "<short title>"
---

Record a decision in `wiki/product/decisions.md` for: $ARGUMENTS

Ask, one at a time, only what the conversation has not already settled: the question it answers, at least two options with pros and cons, the choice, why it beats the others, what it closes off, and whether it supersedes a `DEC-NNN`.

Append:

```
## DEC-NNN: <title>
**Date:** YYYY-MM-DD · **Status:** [DECISION] | [HYPOTHESIS] · **Supersedes:** DEC-XXX | —
**Question:** …
**Options:** A — … · B — …
**Choice:** …
**Why:** …
**Consequences:** …
```

The number is the highest existing one plus one. A superseded entry gets `~~Superseded by DEC-NNN~~` added under its title; its text is kept. Log `## [date] decision | DEC-NNN <title>` in `wiki/log.md`.
