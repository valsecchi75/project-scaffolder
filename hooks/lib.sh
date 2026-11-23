#!/usr/bin/env bash
# Shared helpers for the project-scaffolder hooks. Sourced, never executed.
# No jq dependency: fields are pulled out of the hook JSON with grep/sed.
# Callers read stdin into INPUT before sourcing this file.

# Comparable form of a path: forward slashes, "/c/x" -> "c:/x", lowercase,
# no trailing slash. Accepts JSON-escaped Windows paths (C:\\Users\\x).
ps_norm() {
  printf '%s' "$1" \
    | sed -e 's#\\\\#/#g' -e 's#\\#/#g' -e 's#//*#/#g' -e 's#/$##' \
    | sed -E 's#^/([a-zA-Z])/#\1:/#' \
    | tr '[:upper:]' '[:lower:]'
}

# Same path, usable on the filesystem from bash (case preserved).
ps_fs() {
  printf '%s' "$1" | sed -e 's#\\\\#/#g' -e 's#\\#/#g'
}

# First string value of a JSON key. $1 = json, $2 = key.
ps_field() {
  printf '%s' "$1" \
    | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -n 1 \
    | sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//; s/"$//'
}

# Nearest directory at or above $1 that holds .scaffolder/phase: the project
# whose phase governs that path. Empty when there is none. Missing directories
# (a file about to be created) are simply walked past.
ps_root_of() {
  local d
  d=$(ps_fs "$1" | sed -e 's#//*#/#g' -e 's#/$##')
  while [ -n "$d" ]; do
    [ -f "$d/.scaffolder/phase" ] && { printf '%s' "$d"; return 0; }
    case "$d" in */*) d="${d%/*}" ;; *) return 1 ;; esac
  done
  [ -f "/.scaffolder/phase" ] && printf '/'
}

# Path relative to the project root (normalized). Empty when the path lies
# outside the project: files elsewhere are none of these hooks' business.
# A file in a worktree under .claude/worktrees/<name>/ that has no phase
# state of its own is judged as the same path in the main checkout.
ps_rel() {
  local f p r
  f=$(ps_norm "$1")
  p=$(ps_norm "$PS_PROJECT")
  case "$f" in
    "$p"/*) r="${f#"$p"/}" ;;
    /*|[a-z]:/*) return 0 ;;
    *) r="${f#./}" ;;
  esac
  case "$r" in
    .claude/worktrees/*/*) r="${r#.claude/worktrees/*/}" ;;
  esac
  printf '%s' "$r"
}

# ps_rel for many absolute paths at once, one per line on stdin: a fixed
# number of processes however many paths (each ps_rel call costs several,
# and on Windows each process costs tens of milliseconds).
ps_rel_lines() {
  local p
  p=$(ps_norm "$PS_PROJECT")
  ps_norm "$(cat)" | awk -v p="$p/" 'index($0, p) == 1 {
    r = substr($0, length(p) + 1); sub(/^\.claude\/worktrees\/[^\/]+\//, "", r); print r }'
}

# Project root. The hook input's cwd follows Claude into worktrees and
# subdirectories, while CLAUDE_PROJECT_DIR stays where the session started,
# so the nearest phase-managed directory above cwd wins; the variable is the
# fallback (no cwd field, or cwd outside any phase-managed project).
PS_CWD=$(ps_field "${INPUT:-}" cwd)
PS_PROJECT=""
[ -n "$PS_CWD" ] && PS_PROJECT=$(ps_root_of "$PS_CWD")
[ -n "$PS_PROJECT" ] || PS_PROJECT="${CLAUDE_PROJECT_DIR:-${PS_CWD:-$PWD}}"

# Reasons are fixed strings written in this repo: keep them free of double
# quotes and backslashes so the JSON stays valid without an escaper.
ps_deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

ps_ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}
