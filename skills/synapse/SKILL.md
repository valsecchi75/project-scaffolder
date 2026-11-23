---
name: synapse
description: Use when a task, a bug fix or a release in a phase-managed project ends with a lesson worth keeping, or when the user asks to propagate learning or update the project skills.
---

# Synapse — lessons into the project skills

After a task, a bug fix or a release, Synapse writes what was learned into the project skill that was used, passes a short note to the skills directly connected to it, and keeps `wiki/skills-map.md` current. A mistake found once should not happen again in any skill that could meet it.

## Hard rules

1. **Back up before editing a skill's sections** (the primary update, a refactor): copy it to `.claude/skills/<name>/.history/SKILL-YYYY-MM-DD-N.md` first. A one-line propagated note needs no backup.
2. **Never delete** an entry from `## Anti-patterns` or `## Common mistakes`. Reword it if needed, but keep it.
3. **One hop only.** Propagate to skills directly connected in the map, never onward (A→B, not A→B→C).
4. **One ERR per error.** `/log-error` and `/fix-bug` (the debugging skill) already write the `ERR-NNN`. Reuse their id. Create one only when the packet has an error and no id.
5. **Full refactors need the user's yes.** Small additions do not.

## Input: the learning packet

From the cortex at task close, from `/fix-bug` and `/log-error` when an error is recorded, and from the release skill. The packet holds the task and its outcome, the primary skill, the files changed, the errors met (with `KE-NNN`/`ERR-NNN` when they exist), the patterns that worked, the verifier, bug-hunt and persona findings, and the decisions. A packet with nothing new ends here: log `no lesson`.

## 1. Update the primary skill

Add the lesson to the sections of `templates/project-skill.md` in the foundation skill: a validated pattern goes in `## Patterns`, a rule in `## Rules`, a mistake in `## Anti-patterns` (with its `ERR-NNN` in the Ref column) or `## Common mistakes`, and a new check in `## Verification checklist`. Do not create new sections.

In the frontmatter `metadata:` map, add 1 to `tasks_completed`, set `last_synapse_update`, add any new `connections` and set `maturity`: seed (0 tasks), growing (1-3), mature (4-9) or expert (10+).

## 2. Propagate one hop

For each skill connected to the primary one in the map that the lesson really concerns (shared data, domain concept, library or infrastructure), append one tagged row to its `## Common mistakes` table. Do not rewrite anything else.

```
| [SYNAPSE from <origin-skill>, YYYY-MM-DD] <the lesson in one line> | See ERR-NNN |
```

Add 1 to that skill's pending notes in the map. Once a skill has 5 or more pending notes, list it as **due for refactor** in the task report (`/skill-map` also lists them, read-only). When the user agrees, take the backup, fold the notes into the right sections, and run the validation below. On a pass, reset its pending notes to 0.

**Validation after any rewrite:** every anti-pattern and common-mistake entry from the backup is still there, the frontmatter parses with `name`, `description` and `metadata`, and the skill is at least 80% of the backup's length. If any check fails, restore the backup, keep the notes as tagged lines, and log an error entry.

## 3. Guardrail

The error already has an `ERR-NNN` (from `/log-error` or `/fix-bug`): cite it only, and still run 1 and 2 for the lesson. The packet has an error with no `ERR-NNN`: append one to `guardrails/errors-to-avoid.md` in the same format the other writers use: the pattern to avoid, the correct pattern, the skills affected, and `Ref: KE-NNN` when there is one. Then cite it in the primary skill's anti-patterns.

## 4. Map hygiene (from `/session-end`)

Remove skills that no longer exist on disk and add the ones that are missing. Keep only the last 20 propagations: move older rows to `wiki/_archive/YYYY-MM/skills-map.md`, as in the wiki-keeper skill. Flag orphans (skills with no connections) for the user. Report `Skills map: N skills, M connections, K propagations this session`.

## The map: `wiki/skills-map.md`

The foundation skill creates it in phase 2 and `/skill-new` adds the stack skills in phase 4. One line per row, so it stays small:

```markdown
# Skills map
> last-verified: YYYY-MM-DD

## Skills
| Skill | Pending notes |

## Connections
| Skill | Skill | Shared concept |

## Recent propagations (last 20)
| Date | Origin | Lesson (one line) | Propagated to |
```

## Log

Add one `- synapse | ...` step line to the task block, in the pipeline-logger skill's format. When validation fails, also add an error entry. Read `example.md` in this folder when you need a full worked run.
