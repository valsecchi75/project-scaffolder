---
name: verify
description: Use when about to commit, or when asked to verify a change - runs this project's lint, type check, tests and build, then drives the app when the change shows at runtime. Reports PASS or FAIL per check.
---

# Verify — {project}

Written at the platform decision (phase 4) from the commands in `wiki/tech-stack.md`; change both in the same edit. Claude Code runs this skill before each commit, except for docs-only or tests-only changes.

## Checks

Run every row, in order, each to completion, from the repository root. A row whose command is `—` is reported as `n/a`. Before a commit, a verifier report from this session on the same diff that shows every row passing counts as this run: cite it instead of running the rows again.

| # | Check | Command | Pass when |
|---|---|---|---|
| 1 | Lint | `{lint command}` | exit 0 |
| 2 | Type check | `{type-check command, or — when the stack has none}` | exit 0 |
| 3 | Tests | `{test command}` | exit 0, and this change skips or deletes no test |
| 4 | Build | `{build command}` | exit 0 |

## Running app

When the change alters what a user sees or does: launch the app with `{launch command, or the recipe in .claude/skills/run-*/}`, exercise the changed behaviour, and report what you observed. When it cannot be launched here, say so: the runtime behaviour is then unverified, not passed.

## Report

One line per check: the command, its exit code, and the first failing item with file and line. `PASS` only when every row passed. On `FAIL`, do not commit: report the failing lines verbatim. Never print a secret value; keys load from `secrets/` or `.env` by variable name.
