# Todo — plugin notebook

> The plugin's own notebook, in the format it generates for projects (skill `backlog`). One line per item, never deleted. Report: `bash skills/backlog/scripts/todo-report.sh .`

Format: `- [ ] T-NNN | P1|P2|P3 | feedback|idea|debug|debt|question|doc | YYYY-MM-DD | <one actionable sentence> | from: <source>`

## Items

- [x] T-001 | P1 | debug | 2026-11-23 | Command gate checks gate facts: /2-foundation only with an approved brief, /4-build only with design complete or no interface (phase-status.sh already computes both) | from: review Fable blind judge | -> done 2026-11-23: command-gate.sh reads phase-status.sh --facts; gate cases in tests/test-hooks.sh, including agreement with the report (DEC-022)
- [x] T-002 | P1 | debt | 2026-11-23 | Scale loop recommendations to project size: 1 release round for small projects, say in the question that /improve always checkpoints at iteration 5 | from: review Fable blind judge | -> done 2026-11-23: rounds.md recommends 1 round up to ~30 files and 3,000 lines (release inventory counts them); improve-loop Approval options name the iteration-5 checkpoint
- [x] T-003 | P1 | idea | 2026-11-23 | Release gate greps the build output for every secrets/ value; architect rule: a client-only app needing a key gets a proxy or a keyless service | from: review Fable blind judge | -> done 2026-11-23: hooks/secrets-lib.sh shared by the guard and skills/release/scripts/build-secrets.sh (11 script cases, 1 fail-closed case); architect rule; release-gate stage 7 (DEC-023)
- [x] T-004 | P2 | debt | 2026-11-23 | Trim the phase commands back under ~4.5k tokens: dispatch rules only in phase-flow, platform decision and verify-skill text in a file read on the first /4-build | from: review Fable blind judge | -> done 2026-11-23: phase commands measured at commit, see wiki/log.md v4.1.1 (DEC-025)
- [x] T-005 | P2 | idea | 2026-11-23 | Offer Block reads of secrets/ as the default in phase 2, with keys loaded in the shell | from: review Fable blind judge | -> done 2026-11-23: foundation step 5b.3 offers Block reads (Recommended) with shell loading; phase-flow Secrets rule (DEC-024)
- [x] T-006 | P2 | idea | 2026-11-23 | Code Mode: /setup-check recommends it for terminal sessions; test the guards with composed commands | from: session | -> done 2026-11-23: setup-check item 10 (TIP); 12 composed-command cases for deny-dangerous and secrets-guard
- [x] T-007 | P3 | debt | 2026-11-23 | auto-format.sh takes the project from the hook input cwd like the other hooks; drop or wire the unused deny-dangerous.ps1 | from: review Fable release review | -> done 2026-11-23: auto-format.sh on lib.sh (4 cwd cases); deny-dangerous.ps1 removed
- [x] T-008 | P2 | debug | 2026-11-23 | Test build-secrets.sh in a git worktree without secrets/ (main checkout fallback), and find out whether Claude Code's sandbox shows a Read-denied file as empty (the scan treats size 0 as no value) | from: review Fable v4.1.1 | -> done 2026-11-23: worktree, emptied and removed key file cases in tests/test-hooks.sh; .env.example names cross-checked; sandbox behaviour from the docs, release verdict from the user terminal when sandboxed (DEC-026)
