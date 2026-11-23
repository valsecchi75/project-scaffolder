# Milestone M{n} — {name}

> Planned by the architect on {YYYY-MM-DD}, approved by the user on {YYYY-MM-DD}. `/task` refuses work for this milestone without this file.

## Goal

{One sentence, from wiki/product/roadmap.md.}

## Activities

| # | Activity | Size | Agent | Design section | Parallel | Est. tokens | → VERIFY | Status |
|---|----------|------|-------|----------------|----------|-------------|----------|--------|
| 1 | {what} | {Trivial/Medium/Complex} | builder | {registry section or —} | {yes/no} | {~Nk} | {command or observation that can fail} | todo |

> **Parallel = yes** only with no dependency on another activity and no git-ignored input (`secrets/`, `.env`) for its VERIFY: `/task --parallel` can then build it in its own worktree.
> **Status:** `todo` · `in-progress` · `done — <evidence>` · `moved to M{n+1}`.

## Assumptions and unknowns

| Assumption | Source | Confidence | Tag |
|---|---|---|---|

## Out of scope

- {explicitly not in this milestone}

## Execution choices

- {Complex activities: the option the user chose, logged as a decision}
