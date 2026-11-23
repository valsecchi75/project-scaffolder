---
description: Phase 1 of 5. Start a project from an idea or a brief by asking questions only, one topic at a time, until the brief is approved.
argument-hint: "[your idea, brief or path to a brief]"
disable-model-invocation: true
---

Load the `project-scaffolder:phase-flow` skill, then the `project-scaffolder:brainstorm` skill, and follow it exactly.

Questions only, asked through AskUserQuestion, one topic at a time. Nothing is written except `.scaffolder/phase`, `raw/` and `docs/brief/BRIEF.md`; running `/1-brainstorm` again resumes the draft brief at its first open topic. The phase ends when the user explicitly approves the brief, which must stand on its own: phase 2 reads the files, not this chat. The next step is `/clear brainstorm` (the user types it), then `/2-foundation`.

Designed for a Fable session. The command does not switch models; on another model, say so in one line before the first question and suggest `/model fable`.

The user's input: $ARGUMENTS
