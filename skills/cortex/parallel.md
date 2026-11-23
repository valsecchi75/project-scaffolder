# Parallel activities (`/task --parallel <#,#>`)

Read this when two or more activities of the milestone plan are built at the same time. Only the build step runs in parallel, each builder in its own git worktree. Plans, questions, verification, bug hunt and close stay one activity at a time, as in Level 3.

## Pre-flight (any failure: run the activities one by one with `/task`, and say why)

- Two or three activities, each `todo`, `Parallel = yes`, size Trivial or Medium. A Complex activity always runs alone.
- Git repository with a clean tree: `git status --porcelain` prints nothing outside `.claude/worktrees/`. Worktrees start from a commit, so uncommitted work, new untracked files included (an earlier task left uncommitted under the git policy of Level 3 step 8.3), would be missing from them. Offer to commit it first.
- No activity needs git-ignored inputs (`secrets/`, `.env`, local data) to run its `VERIFY`: a worktree holds tracked files only.
- Only the user starts it, by typing the flag (`/4-build` may name it as an option, never run it). Say in one line that the tokens are the same as one by one, the wall time shorter, and the builders share the rate and usage limits.

## Steps

1. **Plans.** Launch one `project-scaffolder:architect` per activity together (they write separate plan files). After all reports arrive, compare the "Files to create or change" lists. Two plans that share a file: the later activity leaves the parallel set and runs after, with `/task`. Ask the open questions of every plan before any builder starts.
2. **Record the base:** `git rev-parse HEAD`.
3. **Build.** Launch one `project-scaffolder:builder` per activity together, each Agent call with `isolation: "worktree"`. Add to each brief: "You run in your own worktree. Before changing anything, report `git rev-parse HEAD` as your base. When every `VERIFY` step passes, commit on the worktree branch with the message `<task-id>: <activity>`. Report the worktree path, branch, base and commit."
4. **Check the base** of each report. Subagent worktrees branch from the repository's default branch unless the `worktree.baseRef` setting is `"head"` (with no remote they use the local `HEAD`). A base different from step 2 means the builder worked on other code: drop its result, run that activity again with `/task`, and suggest `"worktree": {"baseRef": "head"}` in `.claude/settings.json` (ask before writing it). Then remove each worktree with `git worktree remove --force <path>` (`git worktree unlock` first only if git says it is locked): its commit stays on its branch, and no copy of the project is left under `.claude/worktrees/` for the test runs of step 6 to pick up.
5. **Integrate one at a time**, in plan order: `git cherry-pick --no-commit <commit>`. It applies the change without committing on the user's branch, so the git policy of Level 3 step 8.3 still decides about commits. A conflict stops the integration: show the conflicted files and ask (header `Conflict`): "Run it again with /task" · "I step in". Never resolve a conflict silently.
6. **Verify each integrated activity** with steps 4 to 8 of Level 3 before integrating the next. The verifier gets the plan, the builder's report and `git diff <base> <commit>` as the diff. Correction rounds run in this checkout, without a worktree.
7. **Clean up** after the last activity: `git branch -D <branch>` for each worktree branch (the guard asks the user to approve each `-D`).

Log the parallel set, the bases and each integration with the pipeline-logger skill.
