# What you can run now, per phase

The phase-status script prints the current phase's row; read the whole card when the user asks what they can do. Keep the first column `<n> <phase>`: the script finds the row by it. Commands are cumulative: what a phase adds stays available later. `/phase-status` and `/setup-check` work in every phase and change nothing.

| Phase | Adds | Not yet (the `command-gate` hook blocks the typed command, `phase-guard` the writes) |
|---|---|---|
| 1 brainstorm | `/1-brainstorm` (keep answering; it resumes the draft brief), `/research <topic>` (cited sources in `raw/research/`, findings come back as questions) | `/3-design`, `/4-build` and the build commands (`/task`, `/milestone-plan`, `/milestone-close`, `/fix-bug`, `/improve`, `/5-release`); every write outside `docs/brief/` and `raw/`; `/2-foundation` until the brief is approved (its skill refuses) |
| 2 foundation | `/2-foundation`, `/session-start`, `/session-end`, `/decision`, `/todo`, `/wiki-ingest`, `/wiki-lint`, `/log-error`, `/skill-map`, `/skill-new` | `/task`, `/milestone-plan`, `/milestone-close`, `/fix-bug`, `/improve`, `/5-release`; application and design files |
| 3 design | `/3-design`, `/3-design --section <name>`, `/research <topic>` for design patterns | `/task`, `/milestone-plan`, `/milestone-close`, `/fix-bug`, `/improve`, `/5-release`; application code |
| 4 build | `/4-build` (`--status`), `/milestone-plan`, `/task`, `/milestone-close`, `/fix-bug`, `/bug-hunt`, `/test-sweep`, `/pipeline-stats`, `/improve` (between milestones), `/3-design --section <name>`, `/5-release` | nothing is blocked; the gates are your approvals |
| 5 release | `/5-release` (resume), `/task --release-fix <finding>`, `/bug-hunt`, `/test-sweep`; after the tag, `/milestone-plan` for the next milestone | `/improve` (its skill declines: the release gate comes first) |

After the brief is approved: `/clear brainstorm`, then `/2-foundation` (phase 2 starts from the files, not the interview). A project without a user interface goes from phase 2 straight to `/4-build`. Going back is always allowed: editing the brief, or `/3-design --section <name>` from build or release.
