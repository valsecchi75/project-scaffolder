---
name: wiki-keeper
description: Use when /wiki-ingest or /wiki-lint runs, when the user adds a document, link or research to the project, when a question about the project should be answered from its wiki, or when wiki pages are stale, contradictory or over their size budgets.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/wiki-report.sh" *)
---

# Wiki Keeper — the second brain

The project's memory follows the LLM-wiki pattern: immutable sources in `raw/`, a wiki the agents write and keep coherent, and a schema in `CLAUDE.md`. The user curates sources and asks questions; the agents do the bookkeeping. Four operations.

## Ingest (`/wiki-ingest <file, path or link>`)

1. **Store the source.** Copy it into `raw/` (a link: save the readable content to `raw/<slug>.md` with the URL and the date on top). Never edit a file in `raw/` afterwards. A source that contains keys or credentials does not go into `raw/`: tell the user to put it in `secrets/`.
2. **Read and discuss.** Summarise the takeaways in a few lines and ask the user what matters most to them, before writing.
3. **Write the source page:** `wiki/sources/<slug>.md` with what it says, what it changes for the project, and quotes with their location in the raw file.
4. **Update the pages it touches.** A single source often touches several pages (overview, architecture, a domain skill, a decision, the glossary). For each: add the new information with a citation to the source page; when it contradicts what the page says, mark the old claim `~~superseded~~` with the pointer, never delete it; when it affects a decision, propose a new `DEC-NNN` instead of editing the old one.
5. **Index and log.** Add one line for the source page to `wiki/index.md` (see Conventions); append `## [date] ingest | <title>` to `wiki/log.md` with the list of pages touched.

## Query

When the user asks something about the project:

1. Read `wiki/index.md` first, then the pages it points to. Go to `raw/` only for the detail a page cites.
2. Answer with citations to the pages (and raw files) used.
3. If the answer required real synthesis and is not in the wiki, offer to file it as a page. A good answer filed back is worth more than the same answer repeated next month.
4. If the wiki could not answer, say so, and say which source would.

Projects with more than about a hundred pages can add a local search tool; the index stays the entry point.

## Lint (`/wiki-lint`)

A health check. Report first, change nothing until the user approves the plan.

**Start with the script.** From the project root run `bash "${CLAUDE_SKILL_DIR}/scripts/wiki-report.sh"` (add `--all` for every page). It reads nothing into context but its own short output: estimated tokens per page against the budget for its type, the five largest pages, index lines over 200 characters, pages missing from the index (the orphans), index entries without a page, relative links that do not resolve (`page:line -> target`), `@` imports in `CLAUDE.md` outside backticks, and unparsable `wiki/log.md` headers. Open only the pages it flags and the ones the judgment checks below need. Without Git Bash, make these checks by hand from `wiki/index.md` and the line counts, and say so.

| Page type | Budget (lines / ~tokens) |
|---|---|
| `CLAUDE.md` (hub) | 120 / 3,000 |
| `wiki/index.md` | 200 / 6,250, one line per page |
| `wiki/handoff.md` · `wiki/priorities.md` | 80 / 2,000 · 100 / 2,500 |
| `wiki/sources/<slug>.md` | 120 / 1,500 |
| `wiki/todo.md` (notebook) | no cap: lines are never deleted, read only through its script (backlog skill) |
| Any other page (topic) | 200 / 2,000 |
| `wiki/log.md` · `wiki/product/decisions.md` | Append-only: no budget, never trimmed |

| Check | How |
|---|---|
| Contradictions | Claims on different pages that cannot both be true |
| Superseded but unmarked | Claims a later decision or source has replaced |
| Missing pages | Concepts mentioned on three or more pages without a page of their own |
| Size, index, orphans, links, imports, log | The script's findings: fix each at the `page:line` it gives |
| Duplicates | Two pages on the same concept: propose merging into one |
| Uncited claims | `[FACT]` without a source |
| Stale | `last-verified` older than 30 days on a page whose subject changed since (git log) |
| Drift from the code | Architecture, tech-stack and skills pages that describe what the code no longer does |
| Secrets | Anything resembling a key value outside `secrets/` |

The mechanical checks need no agent and no page reads. Contradictions, duplicates and drift need judgment: do them yourself.

Output: the script's totals line, then one table of findings with page, check, evidence and proposed fix, then the plan. Every page over budget gets one proposed fix: **split** it into smaller focused pages (one concept each, each with its own index line), **archive** the part that is no longer current, or **merge** it with its duplicate. Nothing is split, merged or archived without the user's approval of that line of the plan. After approval, apply it, rerun the script to show the new totals, update `last-verified` on every page touched and log `## [date] lint | <n> fixes, ~<before> → ~<after> tokens`.

## Archive

Nothing in the wiki is deleted. Content that is no longer current (a closed milestone's details, superseded sections, overflow beyond a budget) moves to `wiki/_archive/YYYY-MM/<page>.md`, and a one-line stub stays in its place: `> Archived YYYY-MM-DD: see wiki/_archive/YYYY-MM/<page>.md#<section>`. `wiki/log.md` and `wiki/product/decisions.md` are never archived or trimmed. The index gets an "Archive" section.

## Conventions

- First line after the title: `> last-verified: YYYY-MM-DD`.
- One concept per page; many small pages beat a few large ones. Relative links between pages; citations to sources.
- The index is bounded: one line per page, `- [Title](path.md) — summary of at most 150 characters`, at most 200 lines; past that, group a folder's pages under `wiki/<dir>/index.md` and keep one line for it. On-demand pages sit under a "Not yet created" heading. Detail lives in the pages, never in the index.
- Tags: `[FACT]`, `[DECISION]`, `[HYPOTHESIS]`, `[DEPRECATED]`.
- Log lines start with `## [YYYY-MM-DD] <op> | <title>` so `grep "^## \[" wiki/log.md | tail` gives the recent history.
