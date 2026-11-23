---
description: Run one piece of build work through the pipeline - plan (architect), build (builder), verify (verifier), bug hunt (bug-hunter, sweeper), persona test when the interface changes.
argument-hint: "<what to do> [--unplanned] [--release-fix] [--skip-persona] [--parallel <#,#>]"
---

Load the `project-scaffolder:phase-flow` skill (unless this session already has it), then the `project-scaffolder:cortex` skill, and run **Level 3 — A task** for the work below.

Gates first: the current milestone has an approved plan (unless `--unplanned`), and interface work has an approved design section. Dispatch the plugin agents by name and do not override their model. `--skip-persona` skips the persona test and is logged. `--release-fix` is for confirmed findings during `/5-release`. `--parallel 2,3` builds those `Parallel = yes` activities of the plan at once, each in its own git worktree (the cortex's `parallel.md`).

The task: $ARGUMENTS
