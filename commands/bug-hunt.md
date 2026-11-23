---
description: Look for real defects nobody has reported yet, in a diff, an area or the whole project. Every finding is reproduced and re-checked by a second agent. Read-only.
argument-hint: "[--diff <range> | --area <path or flow> | --all]"
model: fable
---

Load the `project-scaffolder:bug-hunt` skill and run the **`/bug-hunt`** procedure with this scope: $ARGUMENTS

No scope given: the uncommitted changes, or the last commit when the tree is clean. Never edit product code here.
