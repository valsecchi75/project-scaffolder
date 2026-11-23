---
description: Run every test, lint, type check, build and dependency audit of the project (or one sweep check across all files) and report raw results. Read-only.
argument-hint: "[--tests | --static | --audit | --sweep <check>]"
model: sonnet
---

Dispatch the `project-scaffolder:sweeper` agent, without a model override, with the commands from `wiki/tech-stack.md` that match the scope below (default: all of them, in the order build, tests, lint, type check, audit). For `--sweep <check>`, give it that one check to apply across the project.

Append the results to `logs/pipeline/<today>.md` (pipeline-logger format) and report the table in chat. Do not fix anything.

Scope: $ARGUMENTS
