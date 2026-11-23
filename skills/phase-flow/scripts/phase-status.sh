#!/usr/bin/env bash
# Phase facts for /phase-status. Read-only: it never changes a file.
# Reads .scaffolder/phase and the exit artifacts up to the current phase, and
# prints a few fixed-format lines (phase, artifacts, gate, next) so the report
# comes from the files, not from guesses. Always exits 0.
#
#   bash phase-status.sh [project-dir]
#
# Without project-dir it starts in the current directory and walks up to the
# nearest .scaffolder/phase (stopping at the git root), so a session whose
# shell moved into a subfolder still reports the right project.
#
# Sources: docs/brief/BRIEF.md frontmatter (status, approved, has_interface),
# wiki/log.md lines "phase | Foundation complete", "phase | Design complete",
# "milestone | M<n> closed", wiki/design/registry.md tables,
# docs/plans/MILESTONE-<n>.md, docs/release/v<version>.md "> Status:", git tags,
# and this skill's capabilities.md (the row of the current phase).

set -u
CAP="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)/capabilities.md"
cd "${1:-.}" 2>/dev/null || { echo "phase-status: cannot enter ${1:-.}"; exit 0; }
if [ $# -eq 0 ]; then
  d=$PWD
  while [ ! -f "$d/.scaffolder/phase" ] && [ ! -e "$d/.git" ] && [ "$(dirname "$d")" != "$d" ]; do
    d=$(dirname "$d")
  done
  [ -f "$d/.scaffolder/phase" ] && cd "$d"
fi

if [ ! -f .scaffolder/phase ]; then
  echo "phase: none (no .scaffolder/phase: not phase-managed)"
  echo "next: /1-brainstorm"
  exit 0
fi

PHASE=$(head -n 1 .scaffolder/phase | tr -cd 'a-z')
case "$PHASE" in
  brainstorm) N=1 ;; foundation) N=2 ;; design) N=3 ;; build) N=4 ;; release) N=5 ;;
  *) echo "phase: unknown word '$PHASE' in .scaffolder/phase"; echo "next: fix the file (brainstorm|foundation|design|build|release)"; exit 0 ;;
esac
echo "phase: $N of 5 · $PHASE"

# Frontmatter value of key $1 in the brief (first match, CR and spaces stripped).
fm() { sed -n "s/^$1:[[:space:]]*//p" docs/brief/BRIEF.md 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//'; }
logged() { [ -f wiki/log.md ] && grep -qF "$1" wiki/log.md; }

GATE=""; NEXT=""
gate() { GATE="${GATE:+$GATE; }$1"; }

# 1 brief
if [ -f docs/brief/BRIEF.md ]; then
  BS=$(fm status); BA=$(fm approved); UI=$(fm has_interface)
  case "$UI" in \{*) UI="" ;; esac   # a draft still shows the template placeholder
  case "$BA" in \{*) BA="" ;; esac
  echo "brief: ${BS:-no status}${BA:+ ($BA)} · interface: ${UI:-unknown}"
else
  BS=""; UI=""
  echo "brief: missing (docs/brief/BRIEF.md)"
fi
if [ "$N" -eq 1 ]; then
  if [ "$BS" = approved ]; then NEXT="/clear brainstorm, then /2-foundation"
  else gate "brief not approved: it needs your explicit approval"; NEXT="/1-brainstorm (resumes the draft)"; fi
fi

# 2 foundation
if [ "$N" -ge 2 ]; then
  if logged "phase | Foundation complete"; then echo "foundation: complete"
  else echo "foundation: not confirmed (no 'phase | Foundation complete' in wiki/log.md)"; fi
  if [ "$N" -eq 2 ]; then
    if logged "phase | Foundation complete"; then
      if [ "$UI" = no ]; then NEXT="/4-build (no interface)"; else NEXT=/3-design; fi
    else gate "structure check and your confirmation pending"; NEXT=/2-foundation; fi
  fi
fi

# 3 design (registry: "## Design system" and "## Sections" tables)
FIRST_OPEN=""
if [ "$N" -ge 3 ] && [ "$UI" != no ]; then
  if [ -f wiki/design/registry.md ]; then
    REG=$(tr -d '\r' < wiki/design/registry.md | awk -F'|' '
      /^## /      { sec = $0; next }
      $0 !~ /^\|/ { next }
      { for (i = 2; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i) }
      $2 == "#" || $2 == "Name" || $2 ~ /^[-: ]+$/ || $2 ~ /^\{/ || $3 ~ /^\{/ { next }
      sec ~ /^## Design system/ { sys = ($6 != "" && $6 !~ /^\{/) ? "approved" : "not approved" }
      sec ~ /^## Sections/ { n++; if ($5 ~ /^approved/) ok++; else open = open (open ? ", " : "") $3 " (" $5 ")" }
      END { printf "%s|%d|%d|%s\n", (sys ? sys : "missing"), n, ok, open }')
    SYS=${REG%%|*}; R=${REG#*|}; NS=${R%%|*}; R=${R#*|}; OK=${R%%|*}; OPEN=${R#*|}
    FIRST_OPEN=${OPEN%% (*}
    echo "design system: $SYS"
    echo "sections: $NS listed · $OK approved${OPEN:+ · open: $OPEN}"
  else
    SYS=missing; NS=0; OK=0; OPEN=""
    echo "design: no wiki/design/registry.md yet"
  fi
  if [ "$N" -eq 3 ]; then
    [ "$SYS" = approved ] || gate "design system $SYS"
    [ "$NS" -gt 0 ] || gate "no sections registered"
    [ -n "$OPEN" ] && gate "sections not approved: $OPEN"
    if [ -z "$GATE" ] && logged "phase | Design complete"; then NEXT=/4-build
    elif [ -z "$GATE" ]; then gate "design phase not closed yet"; NEXT=/3-design
    else NEXT="/3-design${FIRST_OPEN:+ (continues with $FIRST_OPEN)}"; fi
  fi
elif [ "$N" -ge 3 ]; then
  echo "design: skipped (has_interface: no)"
fi

# 4 build (milestones: planned = plan files, closed = log lines)
if [ "$N" -ge 4 ]; then
  PLANNED=$(ls docs/plans/MILESTONE-*.md 2>/dev/null | sed 's#.*/MILESTONE-##; s#\.md$##' | sort -n | tr '\n' ' ')
  CLOSED=""; OPENM=""; PLAN=""
  for m in $PLANNED; do PLAN="$PLAN M$m"
    if logged "milestone | M$m closed"; then CLOSED="$CLOSED M$m"; else OPENM="$OPENM M$m"; fi
  done
  echo "milestones: planned${PLAN:- none} · closed${CLOSED:- none} · open${OPENM:- none}" | sed 's/  */ /g'
  if [ "$N" -eq 4 ]; then
    if [ -n "$OPENM" ]; then
      set -- $OPENM; NEXT="/task (on $1; /milestone-close when its tasks are done)"
      gate "open milestone(s):$OPENM"
    elif [ -z "$PLANNED" ]; then NEXT=/milestone-plan; gate "no milestone planned yet"
    else NEXT="/5-release if the closed milestones cover the release scope, else /milestone-plan"; fi
  fi
fi

# 5 release (latest report and its tag)
if [ "$N" -eq 5 ]; then
  # Reports only: v<version>-rounds.md beside them is the rounds journal.
  REP=$(ls docs/release/v*.md 2>/dev/null | grep -v -- '-rounds\.md$' | sed 's#.*/##; s#\.md$##' | sort -V | tail -n 1)
  if [ -n "$REP" ]; then
    RS=$(sed -n 's/^> Status:[[:space:]]*//p' "docs/release/$REP.md" | head -n 1 | tr -d '\r')
    TAG=absent
    if command -v git >/dev/null 2>&1 && [ -n "$(git tag -l "$REP" 2>/dev/null)" ]; then TAG=present; fi
    echo "release: $REP report ${RS:-no status} · tag $REP $TAG"
    if [ "$TAG" = present ]; then NEXT="/milestone-plan (next milestone)"
    else gate "report ${RS:-without status}, tag $REP not created yet"; NEXT="/5-release (resume)"; fi
  else
    echo "release: no report yet (docs/release/)"; gate "release not started"; NEXT=/5-release
  fi
fi

echo "gate: ${GATE:-open}"
echo "next: $NEXT"

# What the user can run now: the capabilities card rows up to the current phase
# (commands are cumulative), and the current row's "not yet".
if [ -f "$CAP" ]; then
  tr -d '\r' < "$CAP" | awk -F'|' -v n="$N" '
    function t(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    { k = t($2) }
    k ~ /^[1-5] / {
      m = substr(k, 1, 1) + 0
      if (m < n + 0) prev = prev (prev == "" ? "" : "; ") t($3)
      else if (m == n + 0) { cur = t($3); nt = t($4) } }
    END { if (cur != "") { print "can run now: " cur
      if (prev != "") print "also from earlier phases: " prev
      print "not yet: " nt } }'
fi
exit 0
