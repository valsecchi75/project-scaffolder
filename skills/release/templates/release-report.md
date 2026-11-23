# Release v{version} — {YYYY-MM-DD}

> Status: {in progress | approved | released}

## Contents

- **Milestones:** {M1, M2}
- **Design sections:** {from the registry}
- **Since:** {previous tag or first commit} — {n} commits, {n} files
- **New dependencies:** {name@version — reason}
- **Migrations:** {none | description and rollback}
- **New environment variables:** {names only}

## Mass run (sweeper)

| Command | Exit | Passed | Failed | Skipped | Time |
|---|---|---|---|---|---|

Sweep: {hits or "clean"}

## Verification rounds (bug-hunter {model}, re-checks sweeper)

- **Rounds:** {run}/{cap chosen by the user} — ended {dry | cap | stopped: reason} — journal `docs/release/v{version}-rounds.md`
- **Lenses:** {security, reliability, accessibility, performance, regression}
- **Usage:** {observed tokens from /workflows, or "fallback without workflows"}

### Confirmed findings

| # | Severity | Class | Where | Status | Fixed by |
|---|---|---|---|---|---|

### Deferred (user decision)

- {finding} → {priorities item}

### External reviews

- `/code-review`: {not run | summary}
- `/security-review`: {not run | summary}

## Release gate

```
{gate output}
```

## Approval

- Approved by the user on {YYYY-MM-DD}
- Tag: `v{version}` — pushed: {no | yes, by the user}
