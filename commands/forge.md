---
name: forge
description: Generate a vertical skill on-demand for a specific domain. Wrapper around Cortex Step 3 for when a skill will be needed before a /task is ready.
---

# /forge

Proactively create a new vertical skill.

## Usage

```
/forge <domain>
```

## Examples

```
/forge notification-scheduling
/forge ocr-processing
/forge payment-webhook
```

## Steps

1. Detect the project prefix (from existing skill names, e.g. `qs-`).
2. Refuse if a skill already covers this domain — suggest `/task --skill <existing>` instead.
3. Read context:
   - `wiki/architecture.md`
   - `wiki/tech-stack.md`
   - `skills/_synapse-map.md`
4. Analyze the domain name — identify likely patterns, shared libraries, and natural connections.
5. Generate the new skill at `skills/<prefix>-<domain>/SKILL.md`:
   - Frontmatter (`name`, `description`, `maturity: seed`, `tasks_completed: 0`, `last_synapse_update: today`, `connections: []`)
   - Overview (from domain + project context)
   - 2-3 starter code patterns from the tech stack
   - Behavioral Rules (Karpathy template)
   - Verification checklist
   - Empty "Common Mistakes" table (Synapse will populate)
6. Create `skills/<prefix>-<domain>/.history/`.
7. Update `skills/_synapse-map.md` with detected connections and `pending_notes: 0`.
8. Ask the user to review before finalizing.

## Rules

- Skill name must follow the project's existing prefix.
- New skills always start at `maturity: seed`.
- Never skip synapse map update.
- If no connections are detectable: flag the skill as an orphan in the map for future review.
