#!/usr/bin/env bash
# Token and hygiene report for a project wiki. Read-only: it never changes a file.
# Measures every page against the budget for its type, checks that the index is
# bounded and covers every page, that relative links resolve, that CLAUDE.md has
# no @ imports, and that wiki/log.md headers are parsable.
#
#   bash wiki-report.sh [project-dir] [--all]
#
# Default output: totals, pages over budget, the five largest pages, index,
# link, import and log findings. --all lists every page. Tokens are estimated as bytes / 4.

set -u
DIR="."
ALL=0
for a in "$@"; do
  case "$a" in
    --all) ALL=1 ;;
    *) DIR="$a" ;;
  esac
done
cd "$DIR" 2>/dev/null || { echo "wiki-report: cannot enter $DIR"; exit 2; }
[ -d wiki ] || { echo "wiki-report: no wiki/ in $(pwd) - run it from the project root"; exit 0; }

# Budget per page type: "type max-lines max-bytes". 0 = no cap (append-only pages).
budget() {
  case "$1" in
    CLAUDE.md)                 echo "hub 120 12000" ;;
    wiki/index.md)             echo "index 200 25000" ;;
    wiki/handoff.md)           echo "handoff 80 8000" ;;
    wiki/priorities.md)        echo "priorities 100 10000" ;;
    wiki/log.md)               echo "log 0 0" ;;
    wiki/todo.md)              echo "todo 0 0" ;;
    wiki/product/decisions.md) echo "decisions 0 0" ;;
    wiki/sources/*)            echo "source 120 6000" ;;
    *)                         echo "topic 200 8000" ;;
  esac
}

findings=0
pages=0
total=0
rows=""
over=""
archived=0

files="$( { [ -f CLAUDE.md ] && echo CLAUDE.md; find wiki -type f -name '*.md' | sort; } )"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in wiki/_archive/*) archived=$((archived + 1)); continue ;; esac
  lines=$(awk 'END { print NR }' "$f")
  bytes=$(wc -c < "$f" | tr -d ' ')
  tok=$((bytes / 4))
  set -- $(budget "$f")
  type=$1 maxl=$2 maxb=$3
  pages=$((pages + 1))
  total=$((total + tok))
  if [ "$maxl" -eq 0 ]; then
    cap="append-only"; status="ok"
  else
    cap="${maxl}l/~$((maxb / 4))t"; status="ok"
    if [ "$lines" -gt "$maxl" ] || [ "$bytes" -gt "$maxb" ]; then
      status="OVER"; findings=$((findings + 1))
    fi
  fi
  row="$tok|$f|$type|$lines|$cap|$status"
  rows="$rows$row"$'\n'
  [ "$status" = "OVER" ] && over="$over$row"$'\n'
done <<< "$files"

fmt() { awk -F'|' 'NF { printf "  %-6s %-42s %-10s %5s lines  ~%5s tok  budget %s\n", $6, $2, $3, $4, $1, $5 }'; }

echo "wiki report: $pages pages, ~$total tokens in total (bytes/4, rough); $archived archived pages not counted"
if [ "$ALL" -eq 1 ]; then
  echo "pages:"
  printf '%s' "$rows" | sort -t'|' -k2 | fmt
else
  if [ -n "$over" ]; then
    echo "over budget:"
    printf '%s' "$over" | sort -t'|' -k1,1nr | fmt
  else
    echo "over budget: none"
  fi
  echo "largest:"
  printf '%s' "$rows" | sort -t'|' -k1,1nr | head -5 | fmt
fi

# Index: bounded (one line per page) and complete in both directions.
if [ -f wiki/index.md ]; then
  long=$(awk 'length($0) > 200 { n++ } END { print n + 0 }' wiki/index.md)
  if [ "$long" -gt 0 ]; then
    echo "index: $long lines over 200 characters (one line per page: link and a summary of at most 150 characters)"
    findings=$((findings + 1))
  fi
  # A page counts as indexed when wiki/index.md or a sub-index (wiki/<dir>/index.md) links it.
  while IFS= read -r f; do
    case "$f" in ""|CLAUDE.md|wiki/_archive/*) continue ;; esac
    rel="${f#wiki/}" base="${f##*/}"
    [ "$f" = wiki/index.md ] && continue
    sub="$(dirname "$f")/index.md"
    if ! grep -qF -e "]($rel" -e "](./$rel" wiki/index.md &&
       ! { [ "$sub" != "$f" ] && [ -f "$sub" ] && grep -qF -e "]($base" -e "](./$base" "$sub"; }; then
      echo "index: missing entry for $f"
      findings=$((findings + 1))
    fi
  done <<< "$files"
  # Entries under a "Not yet created" heading are on-demand pages: they may not exist yet.
  dead=$(tr -d '\r' < wiki/index.md |
    awk '/^#/ { skip = (tolower($0) ~ /not yet created/) } !skip' |
    grep -oE '\]\([^)#: ]+\.md' | sed 's/^](//; s#^\./##' | sort -u |
    while IFS= read -r link; do [ -f "wiki/$link" ] || echo "$link"; done)
  if [ -n "$dead" ]; then
    printf '%s\n' "$dead" | sed 's/^/index: entry points to a missing page: /'
    findings=$((findings + $(printf '%s\n' "$dead" | awk 'END { print NR }')))
  fi
else
  echo "index: wiki/index.md is missing"
  findings=$((findings + 1))
fi

# Links: every relative link in CLAUDE.md and the wiki pages must resolve from the
# page's own folder. Fenced blocks and code spans are skipped; URLs, anchors and
# absolute paths are not checked. The index is checked above, so it is skipped here.
links() {
  tr -d '\r' < "$1" | awk '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    { gsub(/`[^`]*`/, ""); s = $0
      while (match(s, /\]\([^)]*\)/)) {
        t = substr(s, RSTART + 2, RLENGTH - 3); s = substr(s, RSTART + RLENGTH)
        if (t ~ /^</) { sub(/^</, "", t); sub(/>.*$/, "", t) } else sub(/ .*$/, "", t)
        sub(/#.*$/, "", t); gsub(/%20/, " ", t)
        if (t == "" || t ~ /^[A-Za-z][A-Za-z0-9+.-]*:/ || t ~ /^\//) continue
        print NR "\t" t
      } }'
}
broken=$(while IFS= read -r f; do
  case "$f" in ""|wiki/index.md|wiki/_archive/*) continue ;; esac
  d=$(dirname "$f")
  links "$f" | while IFS=$'\t' read -r n t; do [ -e "$d/$t" ] || echo "$f:$n -> $t"; done
done <<< "$files")
if [ -n "$broken" ]; then
  nb=$(printf '%s\n' "$broken" | awk 'END { print NR }')
  echo "links: $nb broken (page:line -> target)"
  printf '%s\n' "$broken" | head -20 | sed 's/^/  /'
  [ "$nb" -gt 20 ] && echo "  ... and $((nb - 20)) more"
  findings=$((findings + nb))
fi

# Imports: an @path in CLAUDE.md outside backticks loads the whole file into every
# session. Write the path in backticks instead (code spans and fences are not parsed).
if [ -f CLAUDE.md ]; then
  imp=$(tr -d '\r' < CLAUDE.md | awk '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    { gsub(/`[^`]*`/, ""); if (match(" " $0, /[ \t]@[A-Za-z0-9_~.\/-]/)) printf "%s%d", (n++ ? "," : ""), NR }
    END { if (n) printf " (%d)", n }')
  if [ -n "$imp" ]; then
    echo "imports: CLAUDE.md lines $imp use an @ import, which loads the whole file every session - put the path in backticks"
    findings=$((findings + 1))
  fi
fi

# Log: every "## " header must be "## [YYYY-MM-DD] <op> | <title>".
if [ -f wiki/log.md ]; then
  bad=$(tr -d '\r' < wiki/log.md | awk '/^## / && $0 !~ /^## \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\] [a-z-]+ \| ./ { printf "%s%d", (n++ ? "," : ""), NR } END { if (n) printf " (%d)", n }')
  if [ -n "$bad" ]; then
    echo "log: unparsable headers at lines $bad - expected '## [YYYY-MM-DD] <op> | <title>'"
    findings=$((findings + 1))
  fi
fi

echo "findings: $findings"
