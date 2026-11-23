---
name: release
description: Use when /5-release runs, or when the user wants to ship, publish, tag or prepare a version of a phase-managed project.
---

# Release — phase 5

Before a version leaves, the strongest available model hunts across the whole project, a second agent re-runs everything, and the release gate passes. Then version, changelog and tag. Nothing is pushed or published without the user saying so.

## Gate in

1. `.scaffolder/phase` is `build` and the closed milestones cover the release scope agreed with the user. Ask which milestones this release contains if it is not obvious.
2. The working tree is clean. Dirty → list the files and stop.
3. Write `release` to `.scaffolder/phase`. Determine the next version (semver) and create `docs/release/v<version>.md` from `templates/release-report.md`.

## Step 1 — Inventory

From the last tag (or the first commit): commits, changed files, milestones and design sections included, new dependencies, migrations, new environment variables (names only). Record them in the report.

## Step 2 — Mass run

Dispatch `project-scaffolder:sweeper` to run, from `wiki/tech-stack.md`: build, full test suite, lint, type check, dependency audit. Also a sweep for leftover debug output, skipped tests, TODO and FIXME added since the last tag, and hardcoded values where the project uses tokens or translations. Record the results.

## Step 3 — Whole-project debug with the strongest model

Run `/bug-hunt --all` (the bug-hunt skill): up to four `project-scaffolder:bug-hunter` agents in parallel on separate areas, then the sweeper's second opinion on every CRITICAL and HIGH finding.

The bug-hunter runs on Fable. Before this step, check `wiki/claude-code.md`: if a newer, more capable model has been released and is available, tell the user and ask whether to run the hunt with it instead (by updating the `model` of the bug-hunter agent in the plugin, not by overriding at dispatch).

Two built-in reviews are worth suggesting to the user at this point, because only they can start them: `/code-review` on the release diff, and `/security-review` when the release touches authentication, payments, uploads or personal data. Fold their findings into the report as additional input.

## Step 4 — Fix loop

Every confirmed CRITICAL and HIGH finding is fixed before release, through `/task --release-fix <finding>` (the cortex's full path: plan, build, verify, bug hunt on the fix). MEDIUM and LOW: the user decides, per finding, fix now or record in `wiki/priorities.md` for the next milestone. After the fixes, rerun step 2.

## Step 5 — Release gate

Run the project's `<prefix>-release-gate` skill. It reads this report for its debug-pass stage and the design registry for its design-conformance stage. A red stage stops the release: fix through the loop above and rerun the gate.

## Step 6 — Approval and versioning

Show the user the report: what ships, the gate output, the findings fixed and deferred. Ask for explicit approval. Then:

1. Bump the version in the project's manifest.
2. Add the `CHANGELOG.md` entry, grouped Added / Changed / Fixed / Security, written for the product's users.
3. Commit `release: v<version>` and create the annotated tag `v<version>`.
4. Log `## [date] release | v<version>` and mark the milestones as released in the roadmap.
5. Report the next actions that belong to the user: push, store submission, deploy. Do them only if the user asks.

## Gate out

Write `build` to `.scaffolder/phase` and suggest `/milestone-plan` for the next milestone. Lessons from the release go through the synapse skill and, for real errors, into `guardrails/errors-to-avoid.md`.
