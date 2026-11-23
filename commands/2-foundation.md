---
description: Phase 2 of 5. From the approved brief, build the second brain (raw sources, wiki, CLAUDE.md schema), the project skills, the agent roster, the secrets/ folder and the shared project settings. --upgrade migrates a v3 project.
argument-hint: "[--upgrade]"
disable-model-invocation: true
---

Load the `project-scaffolder:phase-flow` skill, then the `project-scaffolder:foundation` skill, and follow it exactly.

Refuse to start if `docs/brief/BRIEF.md` is not approved, unless the argument is `--upgrade`. No application code and no design files in this phase. End with the structure check and the user's confirmation; the next command is `/3-design`, or `/4-build` for projects without an interface.

Designed for a Fable session. The command does not switch models; on another model, say so in one line before starting and suggest `/model fable`.

Arguments: $ARGUMENTS
