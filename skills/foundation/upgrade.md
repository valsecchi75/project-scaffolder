# Upgrading a v3 project (`/2-foundation --upgrade`)

A v3 project has `CLAUDE.md`, the wiki and `skills/` but no `.scaffolder/phase`. Show the plan below, wait for confirmation, then apply it. Templates are in this skill's `templates/` folder; "step N" means the step of that number under **Generate** in the foundation SKILL.md.

1. `.scaffolder/phase` ← `build` (the project is already in development). If there is no `docs/brief/BRIEF.md`, derive one from `wiki/overview.md` and the design spec, mark it `status: approved` with a note that it was reconstructed, and ask the user to confirm it.
2. Move `skills/<name>/` to `.claude/skills/<name>/` with `git mv`; move `skills/_synapse-map.md` to `wiki/skills-map.md`. Then write the code map, `.claude/skills/project-overview/SKILL.md`, from `templates/project-overview.md`: take the directories from `git ls-files | cut -d/ -f1-2 | sort -u`, open each entry point before naming it, and leave out what the tree does not show. Add it to `wiki/skills-map.md`.
3. Rename `docs/phases/PHASE-<n>-execution.md` to `docs/plans/MILESTONE-<n>.md` and add the `Agent` column (see the cortex skill's milestone template).
4. Create `raw/` (copy the original brief or design spec there), `wiki/agents.md`, `wiki/claude-code.md`, `secrets/` with the `.gitignore` lines, `.env.example` (step 5).
5. Hooks: v3 copied the guard scripts into `.claude/hooks/` and wired them in `.claude/settings.json`. The plugin now provides them, so they run twice. Show the user the hook entries and ask before removing them. Then apply step 5b to the same file.
6. Rebuild CLAUDE.md on the v4 template: its sections replace "Task Pipeline" and "Navigation"; keep Working Agreements and every project-specific fact; move procedures and long explanations into the wiki or a project skill, folder-specific conventions (wiki page format, design files) into `.claude/rules/` from `templates/rules/`, and replace any `@` import with a backticked path.
7. Interface projects: create `wiki/design/registry.md` and register existing designs as `approved (pre-v4)` with their location.
8. Run the **Verify** script and fix until it passes. Append `## [date] phase | Foundation complete (upgraded from v3)` to `wiki/log.md` (`/phase-status` reads that line), commit `chore: upgrade to project-scaffolder v4`, report.
