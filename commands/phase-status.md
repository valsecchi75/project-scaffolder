---
description: Say which of the five phases the project is in, what is approved, what blocks the gate, what you can run now, and the single next command. Read-only.
context: fork
model: sonnet
background: false
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/skills/phase-flow/scripts/phase-status.sh *)
---

Phase facts, printed by the read-only phase-flow status script before this prompt was sent (they come from the project files):

!`bash ${CLAUDE_PLUGIN_ROOT}/skills/phase-flow/scripts/phase-status.sh`

Report them; change no file and open none unless a line below says so. Your final message is the report, at most eight lines:
1. The phase (`phase 3 of 5 · design`), what is approved, what is open, what blocks the gate (the `gate:` line).
2. One `You can run now:` line: at most six commands from `can run now:` and `also from earlier phases:`, most useful first. Add `Not yet:` only when the user is likely to reach for a blocked command.
3. The single next command: the `next:` line.

With `phase: none`, say the project is not phase-managed and suggest `/1-brainstorm`. If no `phase:` line appears above (shell execution is disabled), run `bash ${CLAUDE_PLUGIN_ROOT}/skills/phase-flow/scripts/phase-status.sh` with Bash; if that fails too, read `.scaffolder/phase` and the exit artifacts of the current and the previous phase, and say the report was built by hand.
