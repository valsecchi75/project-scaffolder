---
name: wiki-gc
description: Deep wiki cleanup — archive stale content, enforce line caps, regenerate index. Never destroys history.
---

# /wiki-gc — Wiki Garbage Collection

Deep pass over the project wiki. Nothing is ever deleted: content moves to `wiki/_archive/YYYY-MM/` with a stub link left behind.

## Steps

1. Scan every `wiki/**/*.md` and collect candidates:
   - pages with `last-verified` older than 30 days
   - sections marked `~~superseded~~` or `[DEPRECATED]`
   - detail sections of phases already completed (roadmap says done)
2. Present the plan: file → what moves to archive → what stays. **Wait for confirmation.**
3. For each approved item:
   - append the content to `wiki/_archive/YYYY-MM/{original-name}.md` (create dirs as needed)
   - leave a one-line stub in the original: `> Archived {date}: see wiki/_archive/YYYY-MM/{file}#{section}`
4. Enforce line caps: `handoff.md` ≤ 80, `priorities.md` ≤ 100, `CLAUDE.md` ≤ 120. Excess content → archive with stub.
5. `wiki/log.md` and `wiki/product/decisions.md` are **append-only: never archived, never trimmed** (only `~~superseded~~` markers allowed).
6. Regenerate `wiki/index.md` (including an "Archive" section).
7. Update `last-verified` on every touched page.
8. Report: N pages scanned, M archived, caps enforced, index updated.
