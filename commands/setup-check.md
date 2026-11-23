---
description: Check that everything project-scaffolder relies on is installed and working - companion design plugins, the bundled anti-slop skills, bash for the hooks, the agents, and the phase state and secrets setup of the current project. Read-only.
model: sonnet
---

Check and report one line per item, `OK` / `MISSING` / `WARN`, with the exact fix for anything not OK.

**Machine**

1. `bash --version` works (the hooks run in bash; on Windows that is Git Bash).
2. `claude --version`: report it.
3. Companion plugins, enabled: `interfaces@interfaces` (typography, color, layout, accessibility, interface review) and `web-design-skills@garden-skills` (design system and artboards). Check with `claude plugin list`. Missing → give the commands:
   ```
   claude plugin marketplace add jakubkrehel/skills
   claude plugin install interfaces@interfaces
   claude plugin marketplace add ConardLi/garden-skills
   claude plugin install web-design-skills@garden-skills
   ```
4. Bundled skills present: `project-scaffolder:no-ai-design-slop`, `project-scaffolder:audit-ai-design-slop`.
5. Duplicates: the same skills loaded from elsewhere (loose skills in `~/.claude/skills/`, synced plugins). Report them as `WARN` with their paths and say that removing them is the user's choice. Do not remove anything.
6. The eight plugin agents are available: architect, builder, designer, verifier, bug-hunter, design-critic, sweeper, persona-tester.

**Current project** (skip when there is no `.scaffolder/` folder)

7. `.scaffolder/phase` holds a valid phase word.
8. `secrets/` exists, `git check-ignore -q secrets/probe` succeeds, `git ls-files secrets` is empty.
9. `.env.example` lists names without values.
10. Project skills live in `.claude/skills/` (a top-level `skills/` folder means the project needs `/2-foundation --upgrade`).
11. No hook entries in `.claude/settings.json` that duplicate the plugin's guard or format hooks.

Change no file.
