---
description: Look for real defects nobody has reported yet, in a diff, an area or the whole project. Every finding is reproduced; a second agent tries to refute the critical and high ones. Read-only.
argument-hint: "[--diff <range> | --area <path or flow> | --all]"
---

Load the `project-scaffolder:debugging` skill and run the **`/bug-hunt`** procedure with this scope: $ARGUMENTS

No scope given: the uncommitted changes, or the last commit when the tree is clean. Never edit product code here. The hunters run on their own model (Fable); this command does not switch the session model.
