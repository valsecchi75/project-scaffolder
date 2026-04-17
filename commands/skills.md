---
name: skills
description: Show the skill map — maturity, connections, pending propagations, orphans. Read-only.
---

# /skills

Visualize the current state of the skill ecosystem.

## Usage

```
/skills                     — summary table
/skills --status            — full detail including pending propagations
/skills --skill <name>      — zoom on one skill
```

## Steps

1. Scan `skills/*/SKILL.md` and read each frontmatter block.
2. Read `skills/_synapse-map.md` for connections and propagation state.
3. Produce report.

## Output format (default)

```
## Skill Map — YYYY-MM-DD

| Skill | Maturity | Tasks | Connections | Pending |
|-------|----------|-------|-------------|---------|
| flutter-patterns | mature | 5 | 3 | 0 |
| subscription-domain | growing | 2 | 4 | 2 ⚠️ |
| release-gate | seed | 0 | 1 | 0 |
| ...

**Orphans:** [skills with zero connections]
**Due for refactor:** [skills with pending_notes >= 5]
**Recent propagations:** last 5 from synapse map
```

## Output format (--status)

Same table plus per-skill detail:
- Last Synapse update date
- Full connection list with type
- Pending `[SYNAPSE]` notes (count + origins)
- `.history/` entries (count of backups)

## Rules

- Read-only — never modifies skills or the map.
- If `_synapse-map.md` is missing: suggest `/scaffold` verification or Synapse map initialization.
- Flag inconsistencies: skill exists on disk but not in the map, or vice versa.
