#!/usr/bin/env bash
# PostToolUse auto-format (project-scaffolder v4).
# Formats the edited file with the stack formatter when available.
# Never blocks: always exits 0 (no onFailure in hooks.json).
#
# Only in projects this plugin manages, found like the other hooks find them
# (lib.sh: the nearest .scaffolder/phase above the input's cwd, then
# CLAUDE_PROJECT_DIR), and only for files inside that project: a plugin-level
# hook must not reformat files in unrelated repositories.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh" 2>/dev/null || exit 0

[ -f "$PS_PROJECT/.scaffolder/phase" ] || exit 0

FILE=$(ps_field "$INPUT" file_path)
[ -n "$FILE" ] || exit 0
[ -n "$(ps_rel "$FILE")" ] || exit 0          # outside the project
FILE=$(ps_fs "$FILE" | sed 's#\([^/]\)//*#\1/#g')   # forward slashes; a leading UNC // stays
case "$FILE" in /*|[A-Za-z]:/*) ;; *) FILE="$PS_PROJECT/$FILE" ;; esac
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.html|*.json)
    command -v prettier >/dev/null 2>&1 && prettier --write "$FILE" >/dev/null 2>&1 ;;
  *.dart)
    command -v dart >/dev/null 2>&1 && dart format "$FILE" >/dev/null 2>&1 ;;
  *.py)
    command -v black >/dev/null 2>&1 && black -q "$FILE" >/dev/null 2>&1 ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE" >/dev/null 2>&1 ;;
esac
# .md intentionally excluded: reflowing the wiki would fight the line-cap rules.
exit 0
