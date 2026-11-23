# Design registry

> last-verified: {YYYY-MM-DD}
> Every interface the product ships is designed here first. Build ports the approved artboards one to one; a section that is not `approved` cannot be built.

Statuses: `todo` · `in-progress` · `in-review` · `approved` · `changed` (approved before, reopened) · `approved (pre-v4)` (registered during an upgrade).

Artboard home: {Artifact | Local} — in Local mode the Artifact column holds the page path, `design/<slug>/index.html`.

Browser check: {on | off} — on when the session has browser tools (Claude in Chrome or a browser MCP server); the critic then renders each page.

References: {Research `raw/research/<slug>/digest.md` | Existing `raw/references.md` | Skipped} — follow: {patterns the user picked} · avoid: {patterns the user picked}

## Design system

| Name | Artifact | Local files | Critic | Approved on | Notes |
|---|---|---|---|---|---|
| {name} | {claude.ai artifact link or `design/system/index.html`} | `design/system/` | {Approve, round n} | {YYYY-MM-DD} | {reused / extended / created} |

## Sections

| # | Section or feature | Release | Status | Artifact | Local files | Critic | Approved on | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | {Onboarding} | M1 | todo | | `design/onboarding/` | | | {direction, states that matter, build tasks that implement it} |

## History

- {YYYY-MM-DD} — {section}: {what changed}, previous Artifact {link} or local copy `index.{YYYY-MM-DD}.html`.
