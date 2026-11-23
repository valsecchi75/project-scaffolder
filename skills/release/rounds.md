# Verification rounds (step 3 of the release skill)

Read this when `/5-release` reaches step 3. The rounds run `workflows/release-rounds.js` (`/project-scaffolder:release-rounds`). Each round hunts the whole project through five lenses (security, reliability, accessibility, performance, regression) with one `project-scaffolder:bug-hunter` each, then `project-scaffolder:sweeper` (Sonnet) tries to refute every new finding. A finding counts only if the re-check could not refute it; a CRITICAL finding must also survive a second refuter who looks for a guard that makes it unreachable. The security lens changes effort every round (high, xhigh, medium), because a repeated scan at another effort finds different things.

## 1. Ask, before anything runs

A workflow cannot ask the user anything mid-run, so every choice is made here, in the main conversation, with AskUserQuestion. Auto mode skips clarifying questions: do not start the rounds until the user has answered.

- header `Rounds`; question: "How many verification rounds before v<version>? They run as the release-rounds workflow. Each round: 5 hunters on Fable plus Sonnet re-checks. It stops early after two rounds in a row with nothing new confirmed."
- options, each with its estimate in the description:
  - `1 round`: about 1M tokens. A single pass, no early stop.
  - `5 rounds`: at most about 5M tokens; most projects stop dry after 2 or 3.
  - `10 rounds`: at most about 10M tokens.
  - `100 rounds`: a ceiling of about 100M tokens. Say plainly that this can use up the weekly allowance on a subscription.
- **The recommendation follows the project's size**, from the inventory's count (step 1): a small project, at most about 30 source files and 3,000 lines, gets `1 round (Recommended)`; five hunters read all of it in one pass, and a second round mostly re-reads the same code. Larger projects get `5 rounds (Recommended)`. Say the count and the reason in the question ("18 files, 1,800 lines: one round reads all of it"). A first release with authentication, payments or personal data keeps `5 rounds` whatever its size.

The estimate is an order of magnitude (5 Fable hunters at 100-200k tokens each, up to 12 Sonnet re-checks at 20-40k). The `/workflows` view shows the real usage per agent: after the first run, write the observed total in the journal and quote it, not the estimate, before any relaunch. Drop the accessibility lens when the project has no user interface (`wiki/tech-stack.md`). Choosing an option is the user's opt-in to running the workflow. When the journal already exists (a resumed release), its cap and lenses hold: do not ask again.

## 2. Journal

Create `docs/release/v<version>-rounds.md` before the first run. It is the loop's memory: a new session resumes from it alone.

```
# Rounds v<version> — cap <N> — lenses <list>
## Runs
- run 1: runId <id>, startRound 1, rounds 1-3, status needs-fix, about <tokens>
## Rounds
- round 1/<N> | found 7 | new 7 | confirmed 2 | refuted 4 | unverified 1 | dry 0
## Seen (one line each, passed back as args.seen)
- src/cart.ts:88 — total ignores the discount on the second item
## Fixed since the last run (passed as args.fixed, then cleared)
- src/cart.ts:88 — KE-012, commit abc123
```

Write the run line (runId, startRound) as soon as the launch returns its runId, and complete it when the run ends. A launch result with `error` set failed the script's syntax check and never ran: write no run line, say so, and use the fallback below. After every run, append its rounds, confirmed findings, unverified findings and the returned `seen` list. Never paste full agent reports into the journal or the chat.

**A run that ends without a result** (stopped, agents failed at a usage limit, session closed) changes nothing in the journal. In the same session, relaunch it with the same script and args and its runId as `resumeFromRunId`: completed agents return their saved results instead of running again. In a new session there is nothing to resume: launch a new run with the args from the journal's last completed run.

## 3. Run and react

Launch `/project-scaffolder:release-rounds` with `args` as a JSON object: `{version, rounds: N, startRound, dryStreak, sinceRef: "<last tag>", lenses, seen, fixed}`, taken from the journal (first run: `startRound` 1, the rest empty). Then act on the returned `status`:

| status | Meaning | Next |
|---|---|---|
| `needs-fix` | a round confirmed CRITICAL or HIGH findings (`blocking`) | fix each one with `/task --release-fix "<where> — <summary>"`, one at a time, in this session; record it under Fixed; relaunch with `startRound: nextStartRound`, `dryStreak: 0` and those fixes |
| `dry` | two rounds in a row confirmed nothing new, with every lens run and every new finding re-checked to a verdict | done: go to step 4 |
| `cap` | the chosen number of rounds ran without going dry | done: say the loop was not dry; the user may ask for more rounds |
| `agent-cap` | this run neared the runtime's 1000-agent limit | relaunch with `startRound: nextStartRound`; the cap N still holds |
| `budget` | a token target the user set for the turn (`+500k`) is nearly spent | stop and report what is left |
| `not-run` | no lens could run the code, or no re-check of a round could run | stop: fix the environment (install, build) before any fix or release |

A re-check that died or answered `ran: false` neither refutes nor confirms: the finding is unverified, stays out of Seen so a later round can re-check it, and its round is not dry. MEDIUM and LOW findings (`deferred`) and unverified ones never stop the loop; they go to the user in step 4. Every round's line from the journal is shown to the user as one line, never more.

## Without workflows

Workflows are off on Pro until the user enables Dynamic workflows in `/config`, and can be disabled with `disableWorkflows` or `CLAUDE_CODE_DISABLE_WORKFLOWS`. When the workflow is not available or the launch is refused, run the same loop from this session with the same caps, journal and stop rules: per round, dispatch one `project-scaffolder:bug-hunter` per lens (they start in the background: wait for every completion notification), deduplicate against Seen, dispatch `project-scaffolder:sweeper` with the refutation job for each new finding that is not LOW (at most 12 per round; a CRITICAL one gets a second sweeper that looks for a guard making it unreachable), apply the same verdict rules, and append the round to the journal. Every report lands in this context (about 40 lines each, the `Report` section of each agent): pass the sweeper only the finding lines (where, claim, repro), and copy only the journal line per round, never the reports.

The fallback keeps every round in this conversation instead of a fresh context per round, so it runs at most 5 rounds per session. After the fifth, when the loop is neither dry nor at its cap, stop with the journal up to date, show the rounds used against the cap, and ask the user to open a new conversation and type `/5-release`: it resumes from the report and this journal (the skill's Gate in, step 0).
