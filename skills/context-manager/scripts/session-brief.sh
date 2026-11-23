#!/usr/bin/env bash
# Session-start facts for a phase-managed project, in one read-only call.
# It never changes a file. Claude reads its output instead of opening each file.
#
#   bash session-brief.sh [project-dir]
#       phase, Claude Code version check, current plan path, the handoff,
#       a compaction snapshot newer than the handoff, open priorities and
#       guardrail ids.
#   bash session-brief.sh --changelog [--from FILE] [project-dir]
#       only the changelog bullets newer than the version recorded in
#       wiki/claude-code.md that touch this kind of project. Without --from it
#       downloads the raw CHANGELOG.md from GitHub with curl.

set -u
MODE=brief
DIR="."
FROM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --changelog) MODE=changelog ;;
    --from) shift; FROM="${1:-}" ;;
    *) DIR="$1" ;;
  esac
  shift
done
cd "$DIR" 2>/dev/null || { echo "session-brief: cannot enter $DIR"; exit 2; }

SEMVER='[0-9]+\.[0-9]+\.[0-9]+'
INSTALLED=$(claude --version 2>/dev/null | grep -oE "$SEMVER" | head -n 1)
RECORDED=""
if [ -f wiki/claude-code.md ]; then
  RECORDED=$(grep -iE '^Last checked version:' wiki/claude-code.md | grep -oE "$SEMVER" | head -n 1)
  [ -n "$RECORDED" ] || RECORDED=$(grep -iE 'version' wiki/claude-code.md | grep -oE "$SEMVER" | head -n 1)
  [ -n "$RECORDED" ] || RECORDED=$(grep -oE "$SEMVER" wiki/claude-code.md | head -n 1)
fi

# Prints 1 when $1 > $2, 0 when equal, -1 when lower (numeric per part).
vcmp() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".");
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) { print 1; exit }
                               if (x[i] + 0 < y[i] + 0) { print -1; exit } }
    print 0 }'
}

if [ "$MODE" = changelog ]; then
  if [ -z "$INSTALLED$RECORDED" ]; then
    echo "changelog: no installed and no recorded version - nothing to compare"; exit 0
  fi
  if [ -n "$FROM" ]; then
    SRC=$(cat "$FROM" 2>/dev/null) || { echo "changelog: cannot read $FROM"; exit 2; }
  else
    SRC=$(curl -fsSL --max-time 20 https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md 2>/dev/null) \
      || { echo "changelog: download failed - say so in one line and continue"; exit 0; }
  fi
  # Sections run newest first; a header is "## 2.1.330" (GitHub) or "**2.1.330**" (docs site).
  printf '%s\n' "$SRC" | awk -v from="$RECORDED" -v to="$INSTALLED" '
    function cmp(a, b,   x, y, i) { split(a, x, "."); split(b, y, ".")
      for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) return 1; if (x[i] + 0 < y[i] + 0) return -1 }
      return 0 }
    BEGIN { kw = "hook|skill|agent|plugin|model|fable|opus|sonnet|artifact|compact|memory|claude\\.md|workflow|deprecat|remov|mods? "
            shown = 0; omitted = 0; fixes = 0; sections = 0; cap = 60 }
    /^(#+ *v?|\*\*)[0-9]+\.[0-9]+\.[0-9]+(\*\*)?[ \t]*$/ {
      match($0, /[0-9]+\.[0-9]+\.[0-9]+/); v = substr($0, RSTART, RLENGTH)
      if (from != "" && cmp(v, from) <= 0) exit
      inside = (to == "" || cmp(v, to) <= 0) && (from != "" || v == to)
      if (inside) { sections++; if (shown < cap) print "## " v }
      next }
    inside && /^[ \t]*[*-] / {
      if ($0 ~ /^[ \t]*[*-] (\\?\[[^]]*\] )?([A-Z][A-Za-z -]*: )?(Fixed|Improved) /) { fixes++; next }
      if (tolower($0) ~ kw) { if (shown < cap) { print substr($0, 1, 220); shown++ } else omitted++ }
      else omitted++ }
    END { printf "changelog: %d version(s) after %s up to %s; %d relevant line(s) shown, %d other and %d fix line(s) skipped\n",
                 sections, (from == "" ? "none recorded" : from), (to == "" ? "latest" : to), shown, omitted, fixes }'
  exit 0
fi

PHASE=""
[ -f .scaffolder/phase ] && PHASE=$(head -n 1 .scaffolder/phase | tr -cd 'a-z')
echo "phase: ${PHASE:-none (.scaffolder/phase missing)}"

if [ -z "$INSTALLED" ]; then
  echo "claude-code: installed version unknown (claude --version failed); recorded ${RECORDED:-none}"
elif [ -z "$RECORDED" ]; then
  echo "claude-code: $INSTALLED installed, none recorded in wiki/claude-code.md - record it"
else
  case $(vcmp "$INSTALLED" "$RECORDED") in
    0)  echo "claude-code: unchanged $INSTALLED" ;;
    1)  echo "claude-code: CHANGED $RECORDED -> $INSTALLED - run this script with --changelog" ;;
    *)  echo "claude-code: $INSTALLED installed is older than recorded $RECORDED" ;;
  esac
fi

case "$PHASE" in
  design) PLAN=wiki/design/registry.md ;;
  build) PLAN=$(ls docs/plans/MILESTONE-*.md 2>/dev/null | sort -V | tail -n 1) ;;
  release) PLAN=$(ls docs/release/v*.md 2>/dev/null | grep -v -- '-rounds\.md$' | sort -V | tail -n 1) ;;
  brainstorm) PLAN=docs/brief/BRIEF.md ;;
  *) PLAN="" ;;
esac
if [ -n "$PLAN" ] && [ -f "$PLAN" ]; then echo "plan: $PLAN"; else echo "plan: none for this phase"; fi

if [ -f wiki/handoff.md ]; then
  n=$(wc -l < wiki/handoff.md | tr -d ' ')
  echo "== wiki/handoff.md ($n lines) =="
  head -n 80 wiki/handoff.md
  [ "$n" -gt 80 ] && echo "... cut at 80 lines: the handoff is over its cap"
else
  echo "== wiki/handoff.md missing =="
fi

# The PreCompact hook writes this snapshot from disk. Newer than the handoff
# means the last session compacted after its last handoff and may have ended
# without /session-end: the handoff can be behind the work.
SNAP=.scaffolder/compact-snapshot.md
if [ -f "$SNAP" ] && { [ ! -f wiki/handoff.md ] || [ "$SNAP" -nt wiki/handoff.md ]; }; then
  echo "== $SNAP is newer than the handoff: the handoff may be behind =="
  grep -E '^- |^    ' "$SNAP" | cut -c1-160 | head -n 25
fi

if [ -f wiki/priorities.md ]; then
  open=$(grep -E '^[[:space:]]*[-*] \[ \]' wiki/priorities.md)
  [ -n "$open" ] || open=$(grep -E 'VERIFY' wiki/priorities.md | grep -vE '\[[xX]\]')
  c=$(printf '%s' "$open" | grep -c .)
  echo "== wiki/priorities.md: $c open item(s), first 10 =="
  [ "$c" -gt 0 ] && printf '%s\n' "$open" | head -n 10
fi

if [ -f wiki/todo.md ]; then
  p1=$(grep -cE '^[-*] \[ \] T-[0-9]+ \| P1 \|' wiki/todo.md)
  all=$(grep -cE '^[-*] \[ \] T-[0-9]+ \|' wiki/todo.md)
  echo "todo: $all open in wiki/todo.md, P1 $p1 (/todo for the list)"
fi

if [ -f guardrails/errors-to-avoid.md ]; then
  ids=$(grep -E 'ERR-[0-9]+' guardrails/errors-to-avoid.md | grep -vE 'ERR-NNN')
  c=$(printf '%s' "$ids" | grep -c .)
  echo "== guardrails/errors-to-avoid.md: $c entr(y/ies); open only those that match the next items =="
  [ "$c" -gt 0 ] && printf '%s\n' "$ids" | cut -c1-160 | head -n 15
fi
exit 0
