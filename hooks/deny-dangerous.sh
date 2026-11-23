#!/usr/bin/env bash
# PreToolUse guard for destructive shell commands (project-scaffolder v4).
# Reads the hook event JSON on stdin. If the Bash/PowerShell command matches a
# dangerous pattern, asks for explicit user confirmation. Exits 0, except when
# its pattern files are missing (see the fail-closed note below).

INPUT=$(cat)

# Only guard shell tools — other tools pass through untouched.
printf '%s' "$INPUT" | grep -qE '"tool_name"[[:space:]]*:[[:space:]]*"(Bash|PowerShell)"' || exit 0

SCRIPT_DIR=$(dirname "$0")
PATTERNS="$SCRIPT_DIR/dangerous-patterns.txt"
CS_PATTERNS="$SCRIPT_DIR/dangerous-patterns-case-sensitive.txt"

# Fail closed: hooks.json sets onFailure "block", so a guard that lost its
# rules exits 1 and the shell call is refused instead of passing unchecked.
[ -f "$PATTERNS" ] && [ -f "$CS_PATTERNS" ] || exit 1

HIT=""

# Match against the raw JSON: the command string is embedded in it.
# -i: case-insensitive, so "RM -RF" or "Git Push --Force" still match
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
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"project-scaffolder guard: possibly destructive command (recursive delete, reset, clean, force push, DROP). Approve only if you meant it."}}
EOF
fi
exit 0
