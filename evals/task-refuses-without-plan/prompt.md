---
description: /task in phase 4 while the current milestone has no approved plan. The cortex gate refuses and points to /milestone-plan.
tags: [gate, phase-4, scaffold]
expected_outcome: No code and no plan are written; the reply names /milestone-plan.
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Agent, TodoWrite, Write, Edit]
---

/project-scaffolder:task Add a CSV export function for the task list in src/export.js.
