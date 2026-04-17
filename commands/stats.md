---
name: stats
description: Pipeline metrics from logs — task count, rejection rates, skill usage, iterations. Answers "is the plugin actually helping?".
---

# /stats

Pipeline analytics from `logs/`.

## Usage

```
/stats                — today (default)
/stats --today
/stats --week
/stats --month
/stats --all
```

## Steps

1. Scan `logs/pipeline/*.md` files within the requested timeframe.
2. Scan `logs/errors/*.md` files for failure counts.
3. Parse structured entries per the format in `skills/pipeline-logger/SKILL.md`.
4. Compute metrics.

## Output format

```
## Pipeline Stats — <timeframe>

### Volume
- Tasks executed: N
- Total duration: N hours
- On-demand skills generated: N

### Quality
- Pass rate (first iteration): X%
- Average iterations per task: Y
- Tasks that hit max iterations: N

### QA rejection reasons
- SCOPE: N
- SIMPLICITY: N
- SURGICAL: N
- DEAD CODE: N
- SUCCESS CRITERIA: N

### Persona-Lab
- Runs: N
- Blocking issues found: N
- Recurring frictions: [list]

### Top skills used
1. skill-name (N tasks)
2. ...
3. ...

### Errors logged
- Total: N
- Most common step: [step]
- Most common error type: [type]
```

## Rules

- Read-only.
- If no logs exist: report clearly ("no data yet — run `/task` to generate logs").
- Honest reporting — never smooth over bad numbers.
- Flag anomalies explicitly (e.g. "rejection rate above 50% this week — review skill quality").
