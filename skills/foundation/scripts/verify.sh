#!/usr/bin/env bash
# Structure check for a phase-2 project (also after /2-foundation --upgrade).
# Read-only: it never changes a file. One line per check, OK / SKIP / problem;
# the last line counts the problems and the exit code is 1 when there are any.
#
#   bash verify.sh [project-dir]

set -u
DIR="${1:-.}"
cd "$DIR" 2>/dev/null || { echo "verify: cannot enter $DIR"; exit 2; }
BAD=0
ok()  { echo "OK       $*"; }
bad() { echo "$1 $2"; BAD=$((BAD + 1)); }

# Prose of a markdown file: fenced blocks and inline code removed.
prose() { tr -d '\r' < "$1" | awk '/^ *(`{3}|~{3})/ { f = !f; print ""; next } { print (f ? "" : $0) }' | sed 's/`[^`]*`//g'; }
lines() { tr -d '\r' < "$1" | awk 'END { print NR }'; }

for f in CLAUDE.md raw/README.md docs/brief/BRIEF.md wiki/index.md wiki/log.md wiki/overview.md \
  wiki/handoff.md wiki/priorities.md wiki/agents.md wiki/product/roadmap.md \
  wiki/product/decisions.md wiki/architecture.md wiki/tech-stack.md \
  wiki/debugging/known-errors.md wiki/claude-code.md wiki/skills-map.md \
  guardrails/errors-to-avoid.md secrets/README.md .env.example .gitignore \
  .claude/settings.json .claude/rules/wiki.md; do
  [ -f "$f" ] && ok "$f" || bad "MISSING " "$f"
done

# Hub: size, compaction section, no @ imports, no template placeholders left.
if [ -f CLAUDE.md ]; then
  n=$(lines CLAUDE.md)
  [ "$n" -le 120 ] && ok "CLAUDE.md $n lines" || bad "FAIL    " "CLAUDE.md $n lines (cap 120)"
  grep -q '^## Compact instructions' CLAUDE.md && ok "compact instructions" || bad "MISSING " "## Compact instructions in CLAUDE.md"
  imp=$(prose CLAUDE.md | grep -nE '(^|[[:space:]])@[A-Za-z0-9_.~/-]+')
  [ -z "$imp" ] && ok "no @ imports" || while IFS= read -r l; do bad "FAIL    " "@ import: $l"; done <<< "$imp"
  ph=$(prose CLAUDE.md | grep -nE '\{[^}]*\}')
  [ -z "$ph" ] && ok "no template placeholders" || while IFS= read -r l; do bad "FAIL    " "placeholder left: $l"; done <<< "$ph"
fi
if [ -f wiki/index.md ]; then
  n=$(lines wiki/index.md)
  [ "$n" -le 200 ] && ok "wiki/index.md $n lines" || bad "FAIL    " "wiki/index.md $n lines (cap 200: add a sub-index)"
fi

# Path-scoped rules: design.md is required once the project has a design registry.
for f in .claude/rules/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -1 "$f" | tr -d '\r')" = "---" ] && grep -q '^paths:' "$f" && ok "$f path-scoped" || bad "FAIL    " "$f has no paths: frontmatter"
done
[ -f wiki/design/registry.md ] && [ ! -f .claude/rules/design.md ] && bad "MISSING " ".claude/rules/design.md (the project has an interface)"

# Shared settings: valid JSON and the plugin enabled for the repository.
if [ -f .claude/settings.json ]; then
  if command -v jq >/dev/null 2>&1; then
    jq empty .claude/settings.json 2>/dev/null && ok "settings.json is valid JSON" || bad "FAIL    " ".claude/settings.json is not valid JSON"
  elif command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(".claude/settings.json","utf8"))' 2>/dev/null \
      && ok "settings.json is valid JSON" || bad "FAIL    " ".claude/settings.json is not valid JSON"
  else
    echo "SKIP     settings.json syntax (no jq or node): check it by eye"
  fi
  grep -q '"project-scaffolder@' .claude/settings.json && ok "plugin enabled for the repo" || bad "FAIL    " "enabledPlugins entry for project-scaffolder missing"
fi

# Project skills: descriptions say when to use them, frontmatter filled in.
for f in .claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  fm=$(tr -d '\r' < "$f" | awk 'NR == 1 && $0 == "---" { on = 1; next } on && $0 == "---" { exit } on')
  echo "$fm" | grep -q '^description: Use when' || { bad "BAD DESC" "$f"; continue; }
  echo "$fm" | grep -qE '(^|[^$])\{' && { bad "FAIL    " "$f frontmatter keeps a {placeholder}"; continue; }
  ok "$f"
done

# The code map exists from the project skeleton on (phase 4, or after --upgrade).
f=.claude/skills/project-overview/SKILL.md
if [ -f .scaffolder/phase ] && tr -d '\r' < .scaffolder/phase | grep -qxE 'build|release'; then
  if [ -f "$f" ]; then
    n=$(lines "$f"); [ "$n" -le 80 ] && ok "$f $n lines" || bad "FAIL    " "$f $n lines (cap 80)"
  else
    bad "MISSING " "$f"
  fi
fi

# Secrets stay out of git.
if git rev-parse --git-dir >/dev/null 2>&1; then
  for p in secrets/probe .env; do
    git check-ignore -q "$p" && ok "$p ignored" || bad "FAIL    " "$p is not git-ignored"
  done
else
  bad "FAIL    " "not a git repository (run git init)"
fi

[ -f wiki/log.md ] && echo "OK       log entries: $(grep -c '^## \[' wiki/log.md)"
[ "$BAD" -eq 0 ] && echo "verify: all checks passed" || echo "verify: $BAD problem(s)"
[ "$BAD" -eq 0 ]
