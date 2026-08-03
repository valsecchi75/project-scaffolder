#!/usr/bin/env bash
# PreToolUse guard (project-scaffolder v3).
# Reads the hook event JSON on stdin. If the Bash/PowerShell command matches a
# dangerous pattern, asks for explicit user confirmation. Always exits 0.

INPUT=$(cat)

# Only guard shell tools — other tools pass through untouched.
printf '%s' "$INPUT" | grep -qE '"tool_name"[[:space:]]*:[[:space:]]*"(Bash|PowerShell)"' || exit 0

SCRIPT_DIR=$(dirname "$0")
PATTERNS="$SCRIPT_DIR/dangerous-patterns.txt"
CS_PATTERNS="$SCRIPT_DIR/dangerous-patterns-case-sensitive.txt"

HIT=""

# Match against the raw JSON: the command string is embedded in it.
# -i: case-insensitive, to stay symmetric with the .ps1 variant (-match is
# case-insensitive by default in PowerShell).
if [ -f "$PATTERNS" ] && printf '%s' "$INPUT" | grep -qiE -f <(grep -v '^#' "$PATTERNS"); then
  HIT=1
fi

# Case-SENSITIVE patterns (no -i on purpose): e.g. "git branch -D"
# (force-delete, destructive) must not fire on the safe, everyday
# "git branch -d" (delete-if-merged) that a case-insensitive match would
# also catch. See hooks/dangerous-patterns-case-sensitive.txt.
if [ -z "$HIT" ] && [ -f "$CS_PATTERNS" ] && printf '%s' "$INPUT" | grep -qE -f <(grep -v '^#' "$CS_PATTERNS"); then
  HIT=1
fi

if [ -n "$HIT" ]; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Guardrail project-scaffolder: comando potenzialmente distruttivo (cancellazione ricorsiva, reset/clean/force-push, DROP). Approva solo se intenzionale."}}
EOF
fi
exit 0
