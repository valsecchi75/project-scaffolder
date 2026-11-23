---
name: release
description: Use when /5-release runs, or when the user wants to ship, publish, tag or prepare a version of a phase-managed project.
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/build-secrets.sh" *)
---

# Release — phase 5

Before a version leaves, the strongest available model hunts across the whole project, a second agent re-runs everything, and the release gate passes. Then version, changelog and tag. Nothing is pushed or published without the user saying so.

## Gate in

0. **Resume.** `.scaffolder/phase` is already `release` and a `docs/release/v<version>.md` says `Status: in progress`: read it and its rounds journal, say in one line which step comes next (the first one with nothing recorded in the report; step 3 continues from the journal), and continue there. Skip 1-3 below: the tree legitimately holds the report, the journal and the release fixes.
1. `.scaffolder/phase` is `build` and the closed milestones cover the release scope agreed with the user. Ask which milestones this release contains if it is not obvious.
2. The working tree is clean. Dirty → list the files and stop.
3. Write `release` to `.scaffolder/phase`. Determine the next version (semver) and create `docs/release/v<version>.md` from `templates/release-report.md`.

## Step 1 — Inventory

From the last tag (or the first commit): commits, changed files, milestones and design sections included, new dependencies, migrations, new environment variables (names only). Also the size of the shipped code: tracked source files and their lines (`git ls-files`, leaving out `docs/`, `wiki/`, `raw/`, `logs/`, `design/`, lockfiles and generated files). Record them in the report; step 3 sizes the rounds from that count.

## Step 2 — Mass run

Dispatch `project-scaffolder:sweeper` to run, from `wiki/tech-stack.md`: build, full test suite, lint, type check, dependency audit. Also a sweep for leftover debug output, skipped tests, TODO and FIXME added since the last tag, and hardcoded values where the project uses tokens or translations. Record the results.

**Gate for the rounds.** Every round pays for five hunters that must run the code, so the rounds start only on a green build and test suite. The build fails, the suite cannot start, or a test fails (except one the sweeper's solo rerun marks as flaky; list it in the report): stop before step 3, fix each failure with `/task --release-fix` as a confirmed HIGH finding, and rerun this step. Lint, type check, audit and sweep hits do not block the rounds; they wait for step 4 unless a round confirms them.

## Step 3 — Verification rounds

Read `rounds.md` in this skill folder and follow it: ask the user (AskUserQuestion) for 1, 5, 10 or 100 rounds with the cost estimate, keep the journal `docs/release/v<version>-rounds.md`, run the `project-scaffolder:release-rounds` workflow (or its documented fallback), and fix every confirmed CRITICAL and HIGH finding between rounds with `/task --release-fix`. The loop ends dry, at the chosen cap, or on a hard stop; record the outcome in the report.

The bug-hunter runs on Fable, its agent `model`. If `wiki/claude-code.md` records a newer, more capable model, tell the user in one line: agent models change in a plugin update by its maintainer, never by editing the installed plugin or by overriding the model at dispatch.

Two built-in reviews add an independent pass: `/code-review <last tag>..HEAD`, and `/security-review` when the release touches authentication, payments, uploads or personal data. They cost model usage, so offer them first (AskUserQuestion, header `Reviews`); on a yes, start them yourself through the Skill tool (Claude can start both; `/code-review` runs as a background subagent, so wait for its findings). Fold their findings into the report as additional input: a CRITICAL or HIGH one counts as confirmed only after the sweeper's refutation job fails to refute it, as in the rounds.

## Step 4 — Fix loop

CRITICAL and HIGH findings were fixed inside the rounds, through `/task --release-fix <finding>` (the cortex's full path: plan, build, verify, bug hunt on the fix). Now the deferred MEDIUM and LOW findings and the unverified ones: the user decides, per finding, fix now (same command) or record in the notebook `wiki/todo.md` (backlog skill, `from: release v<version>`) for the next milestone. After the fixes, rerun step 2.

## Step 5 — Release gate

Run the project's `<prefix>-release-gate` skill. It reads this report for its debug-pass stage and the design registry for its design-conformance stage. A red stage stops the release: fix through the loop above and rerun the gate.

Its Secrets stage includes the scan of what ships, after the build of step 2: run `bash "${CLAUDE_SKILL_DIR}/scripts/build-secrets.sh" <build output>` from the project root, with the build output folders from `wiki/tech-stack.md` (no build step: the folders that ship). It looks for every value in `secrets/` the way the secrets guard does and prints only file paths and variable names, never a value; show its lines as they are. A `leak:` line is a CRITICAL finding: a key in a bundle is readable by every user. Fix it through `/task --release-fix` (the key moves behind a proxy or server, as the architect's rule says), tell the user to rotate the key, rebuild and rerun the scan. Exit 2 (no Git Bash, nothing built, or `secrets/` unreadable in a sandbox): the scan did not run, and the stage stays red until it does; the user can run the same command in their own terminal, since it prints no value.

## Step 6 — Approval and versioning

Show the user the report: what ships, the gate output, the findings fixed and deferred. Ask for explicit approval. Then:

1. Bump the version in the project's manifest.
2. Add the `CHANGELOG.md` entry, grouped Added / Changed / Fixed / Security, written for the product's users.
3. Commit `release: v<version>` and create the annotated tag `v<version>`.
4. Log `## [date] release | v<version>` and mark the milestones as released in the roadmap.
5. Report the next actions that belong to the user: push, store submission, deploy. Do them only if the user asks.

## Gate out

Write `build` to `.scaffolder/phase` and suggest `/milestone-plan` for the next milestone. Lessons from the release go through the synapse skill and, for real errors, into `guardrails/errors-to-avoid.md`.
