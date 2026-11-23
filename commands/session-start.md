---
description: Open a working session - read where the project stands, check whether Claude Code changed since the last check, and give a short briefing with the next command. Changes nothing else.
argument-hint: "[focus from the last handoff]"
disable-model-invocation: true
---

Load the `project-scaffolder:context-manager` skill and run **Session start**.

Focus from the previous session (empty when none was given): $ARGUMENTS

The only file you may update is `wiki/claude-code.md`, and only to record a changed or missing Claude Code version.
