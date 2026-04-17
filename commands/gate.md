---
name: gate
description: Run the release-gate skill (6 stages including the Simplicity Check). Fail-fast on the first red stage.
---

# /gate

Run the pre-release verification gate. Read-only (reports, does not fix).

## Usage

```
/gate
```

## Steps

1. Locate the `[name]-release-gate` skill in `skills/`.
2. Execute each stage sequentially:
   - **Stage 1:** Build verification
   - **Stage 2:** Test suite
   - **Stage 3:** Lint / static analysis
   - **Stage 4:** Dependency audit
   - **Stage 5:** Manual checklist (user-facing concerns)
   - **Stage 6:** Simplicity Check (Karpathy — scope creep, over-engineering, dead code, speculative features)
3. On the first FAIL: stop, report which stage failed and why.
4. On all PASS: report green light for release.

## Output format

```
## Release Gate — YYYY-MM-DD HH:MM
- Stage 1 (Build):     ✅ PASS
- Stage 2 (Tests):     ✅ PASS
- Stage 3 (Lint):      ❌ FAIL — 3 warnings in lib/ui/
- Stage 4 (Deps):      ⏭ SKIPPED (previous stage failed)
- Stage 5 (Manual):    ⏭ SKIPPED
- Stage 6 (Simplicity):⏭ SKIPPED
**Verdict:** NOT READY — fix Stage 3 and re-run
```

## Rules

- Stages are ordered cheapest → most expensive.
- Fail-fast: never run stage N if stage N-1 failed.
- Do not auto-fix issues — `/gate` only reports.
- If the release-gate skill is missing: stop and suggest `/scaffold` to generate it.
