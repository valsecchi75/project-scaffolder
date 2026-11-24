# Upgrading a v3 project (`/2-foundation --upgrade`)

A v3 project has `CLAUDE.md`, the wiki and `skills/` but no `.scaffolder/phase`. If `.scaffolder/phase` exists, stop: the project already follows the phase flow, and `--upgrade` would skip its gates; run `/phase-status` instead. Templates are in this skill's `templates/` folder; "step N" means the step of that number under **Generate** in the foundation SKILL.md.

**Before anything changes.** Run `git status`: with uncommitted work, list the files and ask (AskUserQuestion, header `Dirty tree`) whether to commit them first or stop; the migration is one commit of its own, so it can be reverted. Read `wiki/handoff.md` and the current Execution Doc and say in three lines what is in progress (phase, open activities, a task left half done). Then show the plan below and wait for confirmation.

1. `.scaffolder/phase` ← `build` (the project is already in development). If there is no `docs/brief/BRIEF.md`, derive one from `wiki/overview.md` and the design spec, mark it `status: approved` with a note that it was reconstructed, and ask the user to confirm it.
2. Move `skills/<name>/` to `.claude/skills/<name>/` with `git mv`; move `skills/_synapse-map.md` to `wiki/skills-map.md`. Then write the code map, `.claude/skills/project-overview/SKILL.md`, from `templates/project-overview.md`: take the directories from `git ls-files | cut -d/ -f1-2 | sort -u`, open each entry point before naming it, and leave out what the tree does not show. Add it to `wiki/skills-map.md`.
3. Rename `docs/phases/PHASE-<n>-execution.md` to `docs/plans/MILESTONE-<n>.md` and add the `Agent` column (see the cortex skill's milestone template). An activity left half done stays open in its plan, with the point reached in its notes.
4. Create `raw/` (copy the original brief or design spec there), `wiki/agents.md`, `wiki/claude-code.md`, `wiki/todo.md` (the backlog skill's `templates/todo.md`, with one line per loose item found in the handoff and the priorities that no plan covers), `secrets/` with the `.gitignore` lines, `.env.example` (step 5).
5. Hooks: v3 copied the guard scripts into `.claude/hooks/` and wired them in `.claude/settings.json`. The plugin now provides them, so they run twice. Show the user the hook entries and ask before removing them. Then apply step 5b to the same file, its key-reads question included.
6. Rebuild CLAUDE.md on the v4 template: its sections replace "Task Pipeline" and "Navigation"; keep Working Agreements and every project-specific fact; move procedures and long explanations into the wiki or a project skill, folder-specific conventions (wiki page format, design files) into `.claude/rules/` from `templates/rules/`, and replace any `@` import with a backticked path.
7. Interface projects: create `wiki/design/registry.md` and register existing designs as `approved (pre-v4)` with their location.
8. Rewrite `wiki/handoff.md` so the next session starts from v4, not from this chat: what was in progress (from the check above) as the next step with its `VERIFY`, and a block **Since the v4 upgrade** with the command map below and the three things that changed how work runs: every piece of build work goes through `/task` against an approved milestone plan; a missing design stops the task and opens `/3-design --section <name>`; keys load from `secrets/` in the shell and never enter the conversation.
9. Run the **Verify** script and fix until it passes. Append `## [date] phase | Foundation complete (upgraded from v3)` to `wiki/log.md` (`/phase-status` reads that line), commit `chore: upgrade to project-scaffolder v4`.
10. Report in at most twelve lines: what moved, what was created, the hooks removed, the key-reads choice, the command map, and the next command: `/4-build`, which writes the project's `verify` skill when it is missing and then shows the current milestone. Suggest `/setup-check` once.

## Command map (v3 → v4)

| v3 | v4 |
|---|---|
| `/scaffold` | `/1-brainstorm`, then `/2-foundation` |
| `/kickoff` · `/wrap` | `/session-start` · `/session-end` |
| `/phase-doc` · `/phase-shift` | `/milestone-plan` · `/milestone-close` |
| `/plan` · `/implement` · `/task` | `/task` (plan, build, verify, bug hunt, persona test in one run) |
| `/review` | inside `/task` (verifier); Claude Code's `/code-review` for a diff |
| `/debug` · `/error` | `/fix-bug` (also `/bug-hunt` to look for bugs) · `/log-error` |
| `/test` | `/test-sweep` |
| `/gate` · `/ship` | `/5-release` (the project's release-gate skill runs inside it); `/ship` is now Claude Code's own pull-request command |
| `/decide` | `/decision` |
| `/forge` · `/skills` | `/skill-new` · `/skill-map` |
| `/stats` | `/pipeline-stats` |
| `/wiki-gc` | `/wiki-lint` (and `/wiki-ingest` for new sources) |
| — | new: `/phase-status`, `/todo`, `/3-design`, `/4-build`, `/improve`, `/research`, `/setup-check` |
