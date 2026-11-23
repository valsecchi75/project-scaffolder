#!/usr/bin/env bash
# Report on a project's notebook, wiki/todo.md. Read-only: it never changes a file.
#
#   bash todo-report.sh [project-dir] [--all] [--next]
#
# Item lines (one per item, never deleted):
#   - [ ] T-007 | P1 | debug | 2026-11-23 | <text> | from: <source>
#   - [>] ... | from: <source> | -> M2 a3          planned in a milestone
#   - [x] ... | from: <source> | -> done 2026-11-30: <evidence>
#   - [-] ... | from: <source> | -> dropped: <reason>
#
# Default output: counts, open items by priority then age, flags, next free id.
# --all also lists planned, done and dropped items. --next prints only the next id.

set -u
DIR="."
ALL=0
NEXT=0
for a in "$@"; do
  case "$a" in
    --all) ALL=1 ;;
    --next) NEXT=1 ;;
    *) DIR="$a" ;;
  esac
done
cd "$DIR" 2>/dev/null || { echo "todo-report: cannot enter $DIR"; exit 2; }
F="wiki/todo.md"
[ -f "$F" ] || { echo "todo-report: no $F yet - the first /todo add creates it"; echo "next id: T-001"; exit 0; }

TODAY=$(date +%Y-%m-%d)
tr -d '\r' < "$F" | awk -v today="$TODAY" -v all="$ALL" -v nextonly="$NEXT" '
function days(d,   y, m, dd, a) {          # days from civil date, no mktime needed
  if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return -1
  y = substr(d, 1, 4) + 0; m = substr(d, 6, 2) + 0; dd = substr(d, 9, 2) + 0
  if (m <= 2) { y--; m += 12 }
  a = int(y / 100)
  return int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + dd + 2 - a + int(a / 4)
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
BEGIN { t = days(today); maxid = 0 }
/^[-*] \[.\] / {
  line = $0
  st = substr(line, 4, 1)
  rest = substr(line, 7)
  n = split(rest, f, / \| /)
  id = trim(f[1]); pr = trim(f[2]); ty = trim(f[3]); dt = trim(f[4]); tx = trim(f[5])
  if (n < 6 || id !~ /^T-[0-9]+$/ || pr !~ /^P[123]$/ || days(dt) < 0 || index("x>- ", st) == 0) {
    bad[++nb] = NR; next
  }
  num = substr(id, 3) + 0; if (num > maxid) maxid = num
  if (seen[id]++) dup[++nd] = id
  total++
  if (st == " ") {
    open++; byp[pr]++; byt[ty]++
    age = t - days(dt)
    key = substr(pr, 2) sprintf("%06d", 999999 - age) sprintf("%06d", num)
    row[key] = sprintf("%-6s %s %-9s %4dd  %s", id, pr, ty, age, tx)
    keys[++nk] = key
    if (pr == "P1" && age > 14) oldp1++
    if (age > 90) stale++
  } else if (st == ">") { planned++; other[++no] = sprintf("planned %-6s %s", id, f[n]) }
  else if (st == "x") { done++; other[++no] = sprintf("done    %-6s %s", id, tx) }
  else { dropped++; other[++no] = sprintf("dropped %-6s %s", id, tx) }
}
END {
  nid = sprintf("T-%03d", maxid + 1)
  if (nextonly) { print "next id: " nid; exit }
  printf "todo: %d open (P1 %d, P2 %d, P3 %d) - planned %d - done %d - dropped %d\n", open, byp["P1"], byp["P2"], byp["P3"], planned, done, dropped
  s = ""; for (k in byt) s = s (s == "" ? "" : ", ") k " " byt[k]
  if (s != "") print "by type: " s
  if (nk > 0) {
    print "== open, P1 first, oldest first =="
    # insertion sort: the list is small and awk has no portable sort
    for (i = 2; i <= nk; i++) { v = keys[i]; j = i - 1; while (j > 0 && keys[j] > v) { keys[j + 1] = keys[j]; j-- } keys[j + 1] = v }
    for (i = 1; i <= nk; i++) print row[keys[i]]
  }
  if (all && no > 0) { print "== closed =="; for (i = 1; i <= no; i++) print other[i] }
  if (oldp1 > 0) print "flag: " oldp1 " P1 item(s) open for more than 14 days - plan them or lower them"
  if (stale > 0) print "flag: " stale " item(s) open for more than 90 days - keep, lower or drop"
  for (i = 1; i <= nd; i++) print "flag: duplicate id " dup[i]
  for (i = 1; i <= nb; i++) print "flag: wiki/todo.md:" bad[i] " unparsable item line"
  print "next id: " nid
}'
