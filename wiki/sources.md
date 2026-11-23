# Sources evaluated

> last-verified: 2026-11-23
> Stars and dates as read from the GitHub API on 2026-11-23. Verdict: `adopted` · `borrowed` (ideas, no text) · `dependency` · `watch` · `rejected`.

## Foundations

| Source | Verdict | What was taken | Notes |
|---|---|---|---|
| Karpathy, [llm-wiki.md](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) | borrowed | Raw / wiki / schema layers; ingest, query, lint; index read first; parsable log lines `## [date] op \| title` | The gist is deliberately abstract; the folder layout is the plugin's own |
| [obra/superpowers](https://github.com/obra/superpowers) 7.0.2 | borrowed | `<HARD-GATE>` blocks, rationalisation tables, one exit artifact per phase, explicit model per subagent, descriptions that state only when to use a skill, SessionStart bootstrap on `startup\|clear\|compact` | Its gates are text only; v7 brainstorming allows spikes and opt-outs, so phase 1 here is stricter and backed by a hook |

## Design

| Source | Verdict | Used for | Notes |
|---|---|---|---|
| [jakubkrehel/skills](https://github.com/jakubkrehel/skills) (`interfaces` 1.23.0, MIT) | dependency | `better-typography`, `better-colors`, `better-layout`, `better-accessibility`, `better-interface` | The maintainer's preferred accessibility guidance. Stack-agnostic. `upskill` and `afk` are manual-only |
| [ConardLi/garden-skills](https://github.com/ConardLi/garden-skills) (`web-design-skills`, MIT) | dependency | `web-design-engineer`: declare the design system before composing; artboard canvas | Install only `web-design-skills`; other plugins in that marketplace call image, voice and video APIs |
| [MengTo/Skills](https://github.com/MengTo/Skills) (MIT) | adopted | `no-ai-design-slop` (passive gate), `audit-ai-design-slop` (read-only audit, P0–P3, no numeric score) | Copied from `agent-skills/ui/` at commit `821d22a`. The audit skill reads `../no-ai-design-slop/ARTICLE.md`: keep the two folders side by side. Refresh by hand |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | watch | Motion review (`review-animations`) | Mostly motion; React and Framer Motion examples |
| [elayadesign/ai-design-skills](https://github.com/elayadesign/ai-design-skills) | rejected | — | Has no slop scanner ("SlopScan" is an external site for live pages). `landing-page-design` forces fonts and sections that contradict a design-system-first flow |
| [codeswithroh/tastemaker](https://github.com/codeswithroh/tastemaker) | rejected | — | Requires GSAP motion, conflicts with the other skills; calls external APIs and writes outside the repo. `check_contrast.py` (offline) is a possible future aid |

## Debugging and review

| Source | Verdict | Notes |
|---|---|---|
| [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) | borrowed | Offensive black-box toolkit; wrong tool for one's own code (see DEC-006). The proof gate and retraction discipline were adapted into `agents/bug-hunter.md` |
| [trailofbits/skills](https://github.com/trailofbits/skills) (CC-BY-SA-4.0) | watch | Defensive security review (`differential-review`, `fp-check`). Candidate optional dependency for `/5-release`; share-alike, so no copying |
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | watch | `code-review`, `security-guidance`, `pr-review-toolkit` |

## Trend scan (2026-11-23)

The `last30days` skill could not run: first-run setup not completed, Reddit blocked, no X or YouTube access. Fallback: GitHub search. To review next:

| Source | Why |
|---|---|
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Design vocabulary and anti-slop critique; possible alternative or complement to the MengTo audit |
| [mattpocock/skills](https://github.com/mattpocock/skills) | `grill-me` (interview-style questioning) for phase 1, `diagnosing-bugs` |
| [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | Its "compound" step feeds lessons back after each task, like Synapse |
| [google/elephant-goldfish-model](https://github.com/google/elephant-goldfish-model) | Fresh-context reviewer and spec-to-code drift report: an idea for `/wiki-lint` drift checks |
| [tobi/qmd](https://github.com/tobi/qmd) | Local markdown search, cited by Karpathy; optional when a wiki exceeds about a hundred pages |
