---
name: synapse
description: Use after a task completes to propagate learning across connected skills. Triggered by Cortex at the end of every successful task pipeline. Also triggers on "propagate learning", "update skills", "synapse", or when skills need cross-pollination after discovering shared patterns or errors.
---

# Synapse — The Nervous System

## Overview

Synapse makes skills learn from experience and communicate with each other. After every completed task, it updates the primary skill with new knowledge, propagates relevant insights to connected skills, and maintains the connection map that makes compound learning possible.

**Core principle:** Every error found once should never recur — because Synapse propagates it to every skill that could encounter it.

## When Called

Synapse is called by Cortex at Step 8 of the task pipeline. It receives a "learning packet" containing:
- Task description and outcome
- Errors encountered during implementation
- Patterns that worked well
- QA feedback (what was rejected and why)
- Persona-Lab feedback (UX frictions found)
- Decisions made during the task
- Primary skill used
- Files changed

## The Synapse Map

Maintained at `skills/_synapse-map.md`. This file tracks all skill relationships and propagation state.

### Map format

```markdown
# Synapse Map — Skill Connections

> Auto-generated and maintained by Synapse. Do not edit manually.
> Last updated: YYYY-MM-DD

## Connections

| Skill | Connected to | Connection type | Pending notes |
|-------|-------------|-----------------|---------------|

## Recent Propagations (last 20)

| Date | Origin | Learning | Propagated to |
|------|--------|----------|---------------|
```

### Map initialization

When a new project is scaffolded (Phase 0), the scaffolder creates the initial synapse map by analyzing all generated skills and finding shared concepts. See the project-scaffolder skill for the initialization logic.

## The Four Operations

### Operation 1: Update the primary skill (intelligent refactor)

**Merge safety protocol:**

1. **Backup before rewrite.** Copy the current skill to `skills/[name]/.history/SKILL-YYYY-MM-DD-N.md` before any modification. This provides rollback capability.

2. **Target canonical sections only.** Integrate new knowledge into ONLY these sections:
   - "Code Patterns" — add validated patterns
   - "Anti-Patterns" / "Common Mistakes" — add newly discovered mistakes
   - "Behavioral Rules" — reinforce or add rules
   - "Verification Checklist" — add new checks

3. **Protected content rule.** NEVER remove entries from "Anti-Patterns" or "Common Mistakes" during a refactor. These sections are append-only (entries may be reworded for clarity but never deleted).

4. **Post-refactor validation.** After rewriting, verify:
   - The refactored skill retains ALL anti-pattern entries from the backup
   - The frontmatter is valid (name, description, maturity, connections)
   - The skill is not shorter than 80% of the backup (guards against content loss)
   - If validation fails → restore from backup → fall back to append-only mode (add `[SYNAPSE]` note)

**Metadata updates (Operation 1 responsibility):**
- Increment `tasks_completed` in frontmatter
- Update `last_synapse_update` to today's date
- Recalculate `maturity`:
  - Seed: 0 tasks
  - Growing: 1-3 tasks
  - Mature: 4-9 tasks
  - Expert: 10+ tasks
- Update `connections` list if new connections were discovered

### Operation 2: Map connections and propagate

After updating the primary skill, evaluate: "Which other skills are impacted by this learning?"

**Propagation rules:**
- Propagate ONLY to skills with direct connections in the synapse map (no cascading)
- Propagation is a **contextual suggestion**, not a rewrite — adds a tagged note:

```
[SYNAPSE from qs-android-widget, 2026-04-16] Caution with DateFormat
and IT locale — always use DateFormat(..., 'it_IT'). See errors-to-avoid.md.
```

- **Propagation counter:** Each connection tracks `pending_notes`. When a skill accumulates 5+ pending `[SYNAPSE]` notes, perform a full refactor of that skill (same merge safety protocol as Operation 1). Reset counter to 0 after refactor.

**Connection detection heuristic (for new skills):**
- Shared code patterns (same libraries, same data models)
- Shared domain concepts (dates, currency, user-facing text)
- Shared infrastructure (file I/O, notifications, database)
- Explicit references (one skill mentions another's domain)

**Updating the synapse map:**
After propagation, update `skills/_synapse-map.md`:
- Add/update connections for newly discovered relationships
- Increment `pending_notes` counter for each propagated skill
- Add entry to "Recent Propagations" table

### Operation 3: Update global guardrails

If the learning includes an error or anti-pattern:
1. Add to `guardrails/errors-to-avoid.md` with:
   - Error ID (ERR-NNN, auto-incremented)
   - Context: what was being done
   - Error: what went wrong
   - Fix: how to avoid it
   - Skills affected: list of skill names
2. Cross-reference the guardrail entry in the updated skill's anti-pattern section

### Operation 4: Synapse map hygiene

Triggered at end of each session (called by the session-end checklist):
- Remove connections referencing deleted skills
- Trim "Recent Propagations" to last 20 entries
- Archive older entries to `skills/_synapse-history.md`
- Flag orphaned skills (connected to nothing) for user review
- Report: "Synapse map: N skills, M connections, K propagations this session"

## Propagation Example

```
Task: "Implement Android home screen widget"
Specialist discovers: DateFormat crashes with IT locale on some Android versions

SYNAPSE executes:

1. BACKUP: skills/qs-android-widget/.history/SKILL-2026-04-16-1.md

2. UPDATE qs-android-widget:
   - Add to "Common Mistakes":
     | DateFormat IT locale crash | Use DateFormat('dd/MM/yyyy', 'it_IT')
       with explicit locale, not platform default |
   - Add code pattern: safe DateFormat initialization
   - Increment tasks_completed: 0 → 1
   - Update maturity: seed → growing

3. VALIDATE: anti-patterns retained? ✅ | frontmatter valid? ✅ | length >= 80%? ✅

4. CHECK connections in synapse map:
   qs-android-widget ↔ qs-flutter-patterns (Widget lifecycle)
   qs-android-widget ↔ qs-subscription-domain (Date logic) — DATE MATCH!

5. PROPAGATE to qs-subscription-domain:
   [SYNAPSE from qs-android-widget, 2026-04-16] DateFormat with IT locale
   can crash. Always pass explicit locale: DateFormat('dd/MM/yyyy', 'it_IT')
   → Increment pending_notes for this connection

6. PROPAGATE to qs-flutter-patterns:
   [SYNAPSE from qs-android-widget, 2026-04-16] DateFormat locale safety —
   always use explicit locale, never rely on platform default.
   → Increment pending_notes for this connection

7. UPDATE guardrails/errors-to-avoid.md:
   ## ERR-XXX: DateFormat IT locale crash
   - Context: Android widget date display
   - Error: DateFormat without explicit locale crashes on some devices
   - Fix: Always pass 'it_IT' as second parameter
   - Skills affected: qs-android-widget, qs-subscription-domain, qs-flutter-patterns

8. UPDATE skills/_synapse-map.md with new propagation entries
```

## Logging

After each operation, log to `logs/pipeline/YYYY-MM-DD.md` under the SYNAPSE section of the current task:

- **Operation 1 (Update skill):** Log skill name, maturity change, patterns added, anti-patterns added
- **Operation 2 (Propagate):** Log each propagation: origin skill → target skill + what was propagated
- **Operation 3 (Guardrails):** Log ERR-NNN created, skills affected
- **Operation 4 (Hygiene):** Log summary: N skills, M connections, K propagations

On validation failure (backup restore): log to both pipeline/ and `logs/errors/YYYY-MM-DD-errors.md` with full context (what failed, what was restored).

See `skills/pipeline-logger/SKILL.md` for complete log format.

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Delete anti-pattern entries during refactor | Anti-patterns are append-only (reword, never delete) |
| Propagate to skills without direct connection | Only direct connections in synapse map |
| Skip the backup before rewriting | Always create .history/ backup first |
| Cascade propagation (A→B→C) | One hop only — B updates are B's responsibility next cycle |
| Refactor a skill without validation | Always check: entries retained, length >= 80%, frontmatter valid |
| Skip logging after propagation | Always log every propagation for audit trail |
