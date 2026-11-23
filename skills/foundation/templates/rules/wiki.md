---
paths:
  - "wiki/**"
---

# Wiki pages

- After the title: `> last-verified: YYYY-MM-DD`. Update it when you change the page.
- One concept per page; many small pages beat a few large ones. Relative links between pages; cite the `raw/` source or the page each claim comes from.
- Tag claims `[FACT]`, `[DECISION]`, `[HYPOTHESIS]`, `[DEPRECATED]`.
- A new fact that contradicts a page: mark the old claim `~~superseded~~` with a pointer to the new one and its source. Never overwrite or delete it.
- `wiki/index.md`: one line per page, `- [Title](path.md) — summary of at most 150 characters`, at most 200 lines; past that, a folder gets its own `wiki/<dir>/index.md` and one line in the root index. Pages not written yet sit under "Not yet created".
- `wiki/log.md` and `wiki/product/decisions.md` are append-only. Log lines: `## [YYYY-MM-DD] <op> | <title>`. A changed decision is a new `DEC-NNN` with alternatives and why, never an edit of the old one.
- No key values: name the variable from `.env.example`.
- `/wiki-lint` measures page sizes against their budgets and finds broken links and `@` imports.
