#!/usr/bin/env bash
# Session-end facts for a phase-managed project, in one read-only call.
# It never changes a file. Claude reads its output instead of opening every
# wiki page to check dates, caps and what changed.
#
#   bash session-close.sh [project-dir]
#       today's daily log, handoff and priorities against their caps, the
#       changed files grouped for the commit, touched wiki pages whose
#       last-verified is not today, and pages not verified for 30 days.

set -u
DIR="${1:-.}"
cd "$DIR" 2>/dev/null || { echo "session-close: cannot enter $DIR"; exit 2; }
[ -d wiki ] || { echo "session-close: no wiki/ in $(pwd) - run it from the project root"; exit 0; }

TODAY=$(date +%F)
# GNU date (Git Bash, Linux) first, then BSD date (macOS); empty = no stale check.
CUTOFF=$(date -d '30 days ago' +%F 2>/dev/null || date -v-30d +%F 2>/dev/null || echo "")

lv() { tr -d '\r' < "$1" | grep -m1 -oE 'last-verified: *[0-9]{4}-[0-9]{2}-[0-9]{2}' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; }

if [ -f "daily-log/$TODAY.md" ]; then
  echo "daily log: daily-log/$TODAY.md exists - append to it"
else
  echo "daily log: daily-log/$TODAY.md missing - create it"
fi

# Caps as in the wiki-keeper budgets (wiki-report.sh): lines and bytes.
for pair in "wiki/handoff.md 80 8000" "wiki/priorities.md 100 10000"; do
  set -- $pair
  if [ -f "$1" ]; then
    n=$(awk 'END { print NR }' "$1"); b=$(wc -c < "$1" | tr -d ' ')
    if [ "$n" -gt "$2" ] || [ "$b" -gt "$3" ]; then echo "$1: $n lines / $b bytes, OVER the cap of $2 / $3 - move finished items to the archive"
    else echo "$1: $n of $2 lines"; fi
  else
    echo "$1: missing - create it"
  fi
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ST=$(git status --porcelain=v1 --untracked-files=all 2>/dev/null)
  FILES=$(printf '%s\n' "$ST" | sed -n 's/^...//p' | sed 's/.* -> //; s/^"//; s/"$//')
  staged=$(printf '%s\n' "$ST" | grep -cE '^[MADRC]')
  mem=$(printf '%s\n' "$FILES" | grep -E '^(wiki/|daily-log/|guardrails/|docs/|raw/|CLAUDE\.md$|\.scaffolder/)')
  work=$(printf '%s\n' "$FILES" | grep -vE '^(wiki/|daily-log/|guardrails/|docs/|raw/|CLAUDE\.md$|\.scaffolder/)' | grep .)
  nm=$(printf '%s' "$mem" | grep -c .); nw=$(printf '%s' "$work" | grep -c .)
  echo "git: branch $(git symbolic-ref --short -q HEAD || echo detached); $nm wiki/docs file(s) and $nw other file(s) changed; $staged already staged"
  [ "$staged" -gt 0 ] && echo "  staged before this step: check with the user that they belong to this session's work"
  if [ "$nw" -gt 0 ]; then
    echo "  other files (first 15):"
    printf '%s\n' "$work" | head -n 15 | sed 's/^/    /'
  fi
  leak=$(printf '%s\n' "$FILES" | grep -E '(^|/)secrets/|(^|/)\.env($|\.)' | grep -v '\.env\.example$')
  [ -n "$leak" ] && printf '%s\n' "$leak" | sed 's/^/  NEVER COMMIT (key file visible to git): /'
else
  FILES=""
  echo "git: not a repository - --commit is not possible"
fi

# Touched pages must carry today's last-verified. The log is append-only.
touched=""
while IFS= read -r f; do
  case "$f" in wiki/_archive/*|wiki/log.md) continue ;; wiki/*.md) ;; *) continue ;; esac
  [ -f "$f" ] || continue
  d=$(lv "$f")
  [ "$d" = "$TODAY" ] || touched="$touched  $f (last-verified ${d:-missing})"$'\n'
done <<< "$FILES"
if [ -n "$touched" ]; then
  echo "touched wiki pages to set to last-verified: $TODAY"
  printf '%s' "$touched"
else
  echo "touched wiki pages: all carry today's last-verified"
fi

if [ -n "$CUTOFF" ]; then
  stale=$(find wiki -type f -name '*.md' -not -path 'wiki/_archive/*' -not -name log.md | sort |
    while IFS= read -r f; do d=$(lv "$f"); [ -n "$d" ] && [[ "$d" < "$CUTOFF" ]] && echo "$f ($d)"; done)
  c=$(printf '%s' "$stale" | grep -c .)
  if [ "$c" -gt 5 ]; then echo "stale: $c pages not verified since $CUTOFF - suggest /wiki-lint"
  else echo "stale: $c page(s) not verified since $CUTOFF"; fi
  [ "$c" -gt 0 ] && printf '%s\n' "$stale" | head -n 5 | sed 's/^/  /'
else
  echo "stale: check skipped (date cannot compute 30 days ago)"
fi
exit 0
