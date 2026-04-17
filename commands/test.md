---
name: test
description: Run project tests with consistent reporting. Writes result summary to the pipeline log.
---

# /test

Run tests declared in `wiki/tech-stack.md`.

## Usage

```
/test                  — smart default (changed files)
/test --changed        — only tests related to changed files
/test --all            — full suite
/test --coverage       — include coverage report
/test --file <path>    — specific test file
```

## Steps

1. Read `wiki/tech-stack.md` to identify the test runner (`flutter test`, `jest`, `pytest`, etc.).
2. Resolve scope from flags.
3. Execute the test command.
4. Parse the result: pass/fail counts, failing tests with line references.
5. If `--coverage`: parse coverage percentage per file and compute delta vs. last run if recorded.
6. Append a summary to `logs/pipeline/YYYY-MM-DD.md`.

## Output format

```
## Test — <scope>
- **Runner:** [tool]
- **Result:** ✅ N passed / ❌ M failed / ⏭ K skipped
- **Duration:** Ns
- **Failures:**
  - test/path.dart:23 — expected X got Y
- **Coverage:** NN% (delta vs last run: +/-X%)
```

## Rules

- Never modify source code inside this command — that is `/task`'s job.
- If no tests exist yet: report clearly and suggest creating one.
- Fail fast on infrastructure errors (missing dependencies, compile errors).
- Honest reporting: don't smooth over flaky tests; flag them explicitly.
