#!/usr/bin/env bash
# Shared helpers for the project-scaffolder hooks. Sourced, never executed.
# No jq dependency: fields are pulled out of the hook JSON with grep/sed.

PS_PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"

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

# Path relative to the project root (normalized). Empty when the path lies
# outside the project: files elsewhere are none of these hooks' business.
ps_rel() {
  local f p
  f=$(ps_norm "$1")
  p=$(ps_norm "$PS_PROJECT")
  case "$f" in
    "$p"/*) printf '%s' "${f#"$p"/}" ;;
    /*|[a-z]:/*) printf '' ;;
    *) printf '%s' "${f#./}" ;;
  esac
}

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
