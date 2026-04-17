---
name: review
description: Disciplined code review on a diff, using Karpathy checklist (SCOPE, SIMPLICITY, SURGICAL, DEAD CODE). Read-only — never modifies files.
---

# /review

Code review on the current diff. Never modifies files.

## Usage

```
/review                     — staged changes (default)
/review --staged            — explicit staged
/review --branch            — all commits on current branch vs main
/review --pr <number>       — GitHub pull request
/review --files <glob>      — specific files
```

## Steps

1. Determine diff scope from flags.
2. Run the QA subset from Cortex Step 5:

### Checks

- **SCOPE:** does the change implement ONLY what was requested?
- **SIMPLICITY:** could this be done with significantly less code?
- **SURGICAL:** were only necessary lines changed? Any formatting or adjacent refactors?
- **DEAD CODE:** unused imports, functions, or variables introduced?
- **TESTS:** is new code covered? Do existing tests still apply?
- **ANTI-PATTERNS:** does any change match an entry in `guardrails/errors-to-avoid.md`?

## Output format

```
## Review — <scope>
**Verdict:** PASS | FAIL

### Findings
- [BLOCKER|WARN|INFO] [check] — description
  - File: path/file.ext:lineN
  - Suggestion: [fix]

### Summary
- Blockers: N
- Warnings: N
- Suggestions: N
```

## Rules

- NEVER modify the code being reviewed.
- Be specific: cite `file:line`, not vague prose.
- Distinguish BLOCKERS from style preferences.
- If there's no diff to review: say so and stop.
