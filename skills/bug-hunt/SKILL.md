---
name: bug-hunt
description: Use when /bug-hunt or /fix-bug runs, when the user reports a bug or a failing behaviour, or when the user asks to look for bugs in a diff, a module or a flow of a phase-managed project.
---

# Bug hunt and bug fixing

Two jobs, one discipline: nothing is called a bug until it is reproduced, and nothing is called fixed until the reproduction passes.

- **`/bug-hunt [scope]`** — proactive. Look for defects nobody has reported yet. Read-only.
- **`/fix-bug <symptom>`** — reactive. A known symptom: reproduce, find the root cause, fix it, prove it, record it.

The end-of-task bug hunt inside `/task` and the whole-project hunt inside `/5-release` use the same agents and the same proof rules.

## `/bug-hunt [scope]`

Scope: `--diff <range>` (default: the uncommitted changes, else the last commit), `--area <path or flow>`, or `--all`.

1. **Partition.** For `--all`, split the project into at most four areas along real boundaries (a module, a flow, an integration, the data layer), using `wiki/architecture.md`. List the classes already ruled out by earlier hunts from `logs/pipeline/` so they are not repeated.
2. **Hunt.** Dispatch one `project-scaffolder:bug-hunter` per area; several areas can run in parallel in one message. Each gets its area, the changes since the last release, the ruled-out classes and `wiki/debugging/known-errors.md`.
3. **Second opinion.** Send every CRITICAL and HIGH finding to `project-scaffolder:sweeper`, which follows the reproductions without the hunter's conclusions.
4. **Merge.** Deduplicate findings that share a root cause. Mark each one `confirmed` (reproduced twice, or a failing test), `unconfirmed` (the sweeper could not reproduce) or `lead`.
5. **Report** in chat: a table of confirmed findings by severity, the count of unconfirmed findings and leads, and the next step: `/fix-bug` for a single finding, `/task` for a group of related findings. Write the full report to `logs/pipeline/<today>.md`.

`/bug-hunt` never edits product code.

## `/fix-bug <symptom>`

This follows systematic debugging. Do not guess a fix before the cause is known.

1. **Reproduce.** Write the exact steps, input and environment that trigger the symptom, and trigger it. Can't reproduce → gather more (logs, versions, data) or ask the user; do not fix what you cannot trigger.
2. **Turn it into a test.** Write the smallest automated test that fails because of the bug, when the stack allows it. Run it and see it fail for the right reason.
3. **Isolate.** Narrow it down: bisect commits, inputs or code paths until you find the smallest case that fails.
4. **Hypotheses.** Two or three candidate causes, ranked. Check the top one with evidence (a log line, a value, a diff). A hypothesis you could not check is not the cause.
5. **Fix the cause, not the symptom.** The smallest change at the root. Dispatch `project-scaffolder:builder` with a short plan (cause, change, the failing test) for anything beyond a few lines; in the release phase use `/task --release-fix`.
6. **Prove it.** The failing test passes; the original reproduction no longer triggers; dispatch `project-scaffolder:verifier` on the diff.
7. **Look sideways.** Search the code for the same pattern elsewhere (same call, same assumption). Report each other occurrence; fix them only if the user agrees or they are in the same function.
8. **Record**, as one operation:
   - `wiki/debugging/known-errors.md` → `KE-NNN`: context, symptom, root cause, fix, test that guards it.
   - `guardrails/errors-to-avoid.md` → `ERR-NNN`: the pattern to avoid, the correct pattern, skills affected, `Ref: KE-NNN`.
   - Pass the lesson to the `synapse` skill for the connected project skills.
   - Log `## [date] error | KE-NNN <title>`.

After three hypotheses that each fail on evidence: stop, record `[INVESTIGATING]` in known-errors with what was ruled out, and ask the user for more context. Do not keep varying the fix.

## Proof rules (both jobs)

- Reproduced in this session, by a command or exact steps, or it is a lead.
- Severity follows user impact: CRITICAL (data loss, security hole, main flow broken), HIGH (common path wrong), MEDIUM (uncommon path wrong, or common path degraded), LOW (cosmetic or self-healing).
- Never probe systems the project does not own. Hunting is on the local code and the local or test environments.
- Never print a secret value, even when the bug is that a secret leaks. Say where, not what.
