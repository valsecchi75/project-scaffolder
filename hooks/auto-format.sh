#!/usr/bin/env bash
# PostToolUse auto-format (project-scaffolder v3).
# Formats the edited file with the stack formatter when available. Never blocks: always exits 0.

INPUT=$(cat)

# Only in projects this plugin manages: a plugin-level hook must not reformat
# files in unrelated repositories that merely have the plugin enabled.
[ -d "${CLAUDE_PROJECT_DIR:-$PWD}/.scaffolder" ] || exit 0

FILE=$(printf '%s' "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
[ -z "$FILE" ] && exit 0
FILE=$(printf '%s' "$FILE" | sed 's#\\\\#/#g; s#\([^/]\)//*#\1/#g')   # JSON-escaped Windows paths -> forward slashes (collapse stray multi-slashes, keep a leading UNC // prefix intact)
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
