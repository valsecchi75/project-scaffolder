---
name: {prefix}-release-gate
description: Use when /5-release runs the release gate for {project}, or when the user asks whether the project is ready to release.
metadata:
  maturity: seed
  tasks_completed: 0
  last_synapse_update: {YYYY-MM-DD}
  connections: []
---

# {Project} — Release Gate

Stages run in order, cheapest first. The first red stage stops the gate. The gate reports; it never fixes.

| # | Stage | Command or check | Passes when |
|---|---|---|---|
| 1 | Build | {from wiki/tech-stack.md} | Exit 0, no warnings promoted to errors |
| 2 | Tests | {full suite} | All pass; no test skipped without a reason in the test |
| 3 | Static checks | {lint, type check} | Clean |
| 4 | Dependencies | {audit command} | No known high or critical vulnerability without a recorded decision |
| 5 | Debug pass | `docs/release/v<version>.md` | No open CRITICAL or HIGH finding from the release bug hunt |
| 6 | Design conformance | `wiki/design/registry.md` | Every released section is approved; built screens match their artboards (interface projects) |
| 7 | Secrets | `git ls-files secrets` · secrets guard · build output scan (`/5-release` runs the release skill's `build-secrets.sh` on {build output folder from wiki/tech-stack.md}) | Nothing under `secrets/` tracked; no key value in the repository; no key value in what ships |
| 8 | Simplicity | diff since last release | No scope creep, speculative options, dead code or abstractions with a single use |
| 9 | Manual checklist | {store listing, legal pages, analytics, backups…} | Confirmed by the user |

Output:

```
## Release gate — v<version> — YYYY-MM-DD
1 Build ............ PASS
2 Tests ............ PASS  (412 passed)
3 Static checks .... FAIL  3 type errors in src/billing/
4–9 ................ SKIPPED
Verdict: NOT READY — fix stage 3 and rerun
```
