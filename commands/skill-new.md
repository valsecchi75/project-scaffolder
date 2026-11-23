---
description: Create a project skill in .claude/skills/ for a domain or stack no skill covers yet, linked in the skills map.
argument-hint: "<domain or stack, e.g. payments or nextjs-patterns>"
---

Create a project skill for: $ARGUMENTS

1. Find the project prefix from the existing skills in `.claude/skills/`. Refuse if a skill already covers the area, and name it.
2. Read `wiki/architecture.md`, `wiki/tech-stack.md`, `wiki/skills-map.md` and the wiki pages about the area.
3. Write `.claude/skills/<prefix>-<name>/SKILL.md` from the `project-scaffolder:foundation` skill's `templates/project-skill.md`: a description starting "Use when" with concrete triggers, the core rule, rules with reasons, real patterns in the project's stack or real worked examples of the business rules, anti-patterns, a verification checklist a verifier can run. Maturity `seed`.
4. Create `.claude/skills/<prefix>-<name>/.history/`.
5. Add the skill and its connections to `wiki/skills-map.md`; with no detectable connection, mark it as an orphan.
6. Show the skill to the user for review before the first task uses it.
