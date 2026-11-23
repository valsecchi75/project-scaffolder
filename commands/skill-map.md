---
description: Project skills report - maturity, tasks, connections, pending synapse notes, orphans. Read-only.
argument-hint: "[--status | --skill <name>]"
disable-model-invocation: true
context: fork
model: sonnet
background: false
---

Read the frontmatter of every `.claude/skills/*/SKILL.md` and `wiki/skills-map.md`, and report:

```
| Skill | Maturity | Tasks | Connections | Pending notes |
```

Then: orphans (no connections), skills due for a refactor (five or more pending notes), the last five propagations, and any mismatch between the skills on disk and the map. With `--status`, add per skill the last synapse date, the connection types and the number of `.history/` backups. With `--skill <name>`, report that skill only.

Change no file. Return only the report. Arguments: $ARGUMENTS
