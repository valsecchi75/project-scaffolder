# Canonical paths of a phase-managed project

Read this when you need the location of a file that the current phase skill does not name. After phase 2 the project's own `CLAUDE.md` ("Where things live") is the first place to look.

```
.scaffolder/phase                 current phase
.scaffolder/compact-snapshot.md   facts flushed before each compaction (git-ignored)
docs/brief/BRIEF.md               approved brief (phase 1)
raw/                              immutable sources: original brief, references, research
raw/parking-lot.md                solutions the user volunteered in phase 1, for later phases
raw/research/<slug>/              cited research rounds and digest.md (untrusted sources)
CLAUDE.md                         project hub and wiki schema
wiki/                             the second brain (see the wiki-keeper skill)
wiki/handoff.md                   session state, the continuation point
wiki/todo.md                      notebook of unplanned items (/todo, backlog skill)
wiki/agents.md                    agent roster and model routing for this project
wiki/skills-map.md                connections between project skills
wiki/design/registry.md           design system and sections, Artifact links or local pages
.claude/skills/<prefix>-<name>/   project skills (native location: they auto-load)
.claude/skills/project-overview/  code map, from the project skeleton on
.claude/skills/verify/            the checks Claude runs before each commit (phase 4)
.claude/rules/<area>.md           folder conventions, loaded by paths:
.claude/settings.json             shared: enables the plugin for the repository
secrets/                          local hand-over files with keys, git-ignored
.env.example                      variable names only, never values
design/system/, design/<section>/ design files (Local mode: design/<section>/index.html)
docs/plans/MILESTONE-<n>.md       milestone plan
docs/plans/tasks/<task-id>.md     task plans
docs/release/v<version>.md        release reports; v<version>-rounds.md, the rounds journal
guardrails/errors-to-avoid.md     lessons that must not repeat
logs/pipeline/, logs/errors/      audit trail (pipeline-logger skill)
logs/improve/<run>/journal.md     improvement loop journal
daily-log/                        one file per working day
```
