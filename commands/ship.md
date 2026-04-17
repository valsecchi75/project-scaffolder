---
name: ship
description: Full release pipeline — gate + version bump + changelog + tag. Executes only if /gate passes. Never pushes automatically.
---

# /ship

Full release pipeline. Only proceeds if `/gate` is green.

## Usage

```
/ship --patch    — bug fix release      (1.2.3 → 1.2.4)
/ship --minor    — new feature          (1.2.3 → 1.3.0)
/ship --major    — breaking change      (1.2.3 → 2.0.0)
```

## Steps

1. Run `/gate`. If FAIL → abort immediately.
2. Check working tree is clean. If dirty → abort, list uncommitted files.
3. Warn if on non-default branch.
4. Read current version from project metadata (`pubspec.yaml`, `package.json`, etc.).
5. Bump version per flag (semver).
6. Generate `CHANGELOG.md` entry from commits since the last tag, grouped by type:
   - `feat:` → Added
   - `fix:` → Fixed
   - `refactor:` → Changed
   - `docs:` → Docs
7. Update `wiki/log.md` with release entry.
8. Commit version bump + CHANGELOG.
9. Create annotated git tag `v<new-version>`.
10. Report: what shipped, version, files touched, next action (user decides when to push).

## Rules

- NEVER push automatically.
- NEVER skip `/gate` — release without gate is not a release.
- If uncommitted changes exist: abort, list them, ask the user to handle.
- If on non-default branch: warn prominently before proceeding.
- If the previous tag doesn't exist yet: generate a "first release" changelog entry.
