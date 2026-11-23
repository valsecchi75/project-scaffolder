# Todo — plugin notebook

> The plugin's own notebook, in the format it generates for projects (skill `backlog`). One line per item, never deleted. Report: `bash skills/backlog/scripts/todo-report.sh .`

Format: `- [ ] T-NNN | P1|P2|P3 | feedback|idea|debug|debt|question|doc | YYYY-MM-DD | <one actionable sentence> | from: <source>`

## Items

- [ ] T-001 | P1 | debug | 2026-11-23 | Command gate checks gate facts: /2-foundation only with an approved brief, /4-build only with design complete or no interface (phase-status.sh already computes both) | from: review Fable blind judge
- [ ] T-002 | P1 | debt | 2026-11-23 | Scale loop recommendations to project size: 1 release round for small projects, say in the question that /improve always checkpoints at iteration 5 | from: review Fable blind judge
- [ ] T-003 | P1 | idea | 2026-11-23 | Release gate greps the build output for every secrets/ value; architect rule: a client-only app needing a key gets a proxy or a keyless service | from: review Fable blind judge
- [ ] T-004 | P2 | debt | 2026-11-23 | Trim the phase commands back under ~4.5k tokens: dispatch rules only in phase-flow, platform decision and verify-skill text in a file read on the first /4-build | from: review Fable blind judge
- [ ] T-005 | P2 | idea | 2026-11-23 | Offer Block reads of secrets/ as the default in phase 2, with keys loaded in the shell | from: review Fable blind judge
- [ ] T-006 | P2 | idea | 2026-11-23 | Code Mode: /setup-check recommends it for terminal sessions; test the guards with composed commands | from: session
- [ ] T-007 | P3 | debt | 2026-11-23 | auto-format.sh takes the project from the hook input cwd like the other hooks; drop or wire the unused deny-dangerous.ps1 | from: review Fable release review
