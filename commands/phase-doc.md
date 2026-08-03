---
name: phase-doc
description: Generate the Execution Doc for the current phase — activities, model routing, token budgets, VERIFY criteria
---

# /phase-doc — Phase Execution Document

Generate `docs/phases/PHASE-{N}-execution.md` for the current phase. This document is the hard gate: the Cortex refuses `/task` without it.

## Steps

1. Determine the current phase N from CLAUDE.md ("Current phase") and `wiki/product/roadmap.md`.
2. If `docs/phases/PHASE-{N}-execution.md` already exists → ask: "Update the existing doc or abort?" Never overwrite silently.
3. Read `wiki/priorities.md`, `wiki/product/roadmap.md`, and the design spec in `docs/superpowers/specs/`.
4. Draft the Activities table using `templates/execution-doc.md` (from the plugin root). For every activity:
   - a `→ VERIFY:` criterion (concrete evidence, not "it works")
   - a model assignment following the Model Routing Policy
   - a Parallel flag (yes only if zero dependency on other activities)
   - a token estimate (~Nk)
5. Fill Assumptions & Unknowns from the phase brief (tag `[HYPOTHESIS]` anything not explicitly stated).
6. Present the draft table for confirmation (skip confirmation in Autonomous mode).
7. Create `docs/phases/` if missing, write the document.
8. Log the operation to `logs/pipeline/YYYY-MM-DD.md`.

## Flags

- `--update` — regenerate the doc for the current phase keeping completed activities marked.
