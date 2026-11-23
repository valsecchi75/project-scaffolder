#!/usr/bin/env bash
# Pipeline numbers from logs/pipeline/ and logs/errors/. Read-only: it never changes a file.
# Reads only header lines "## [HH:MM] <OP> <id> | <title>" and step lines
# "- <step> | <agent>/<model> | r<n> | <RESULT> | <detail>" (pipeline-logger format).
#
#   bash pipeline-stats.sh [project-dir] [--today|--week|--month|--all]
#
# --week = the last 7 days, --month = the last 30 days, both counting today.

set -u
DIR="."
RANGE=today
for a in "$@"; do
  case "$a" in
    --today) RANGE=today ;;
    --week)  RANGE=week ;;
    --month) RANGE=month ;;
    --all)   RANGE=all ;;
    -*) echo "pipeline-stats: unknown option $a (use --today, --week, --month or --all)"; exit 2 ;;
    *)  DIR="$a" ;;
  esac
done
cd "$DIR" 2>/dev/null || { echo "pipeline-stats: cannot enter $DIR"; exit 2; }
[ -d logs/pipeline ] || { echo "pipeline-stats: no logs/pipeline/ yet - nothing has been logged (run /task first)"; exit 0; }

ago() { date -d "-$1 days" +%F 2>/dev/null || date -v-"$1"d +%F; }
case "$RANGE" in
  today) FROM=$(date +%F) ;;
  week)  FROM=$(ago 6) ;;
  month) FROM=$(ago 29) ;;
  all)   FROM=0000-00-00 ;;
esac

# Day files on or after FROM, by the date at the start of the file name.
pick() {
  [ -d "$1" ] || return 0
  for f in "$1"/*.md; do
    [ -f "$f" ] || continue
    d=$(basename "$f"); d=${d:0:10}
    case "$d" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) continue ;; esac
    [[ "$d" < "$FROM" ]] || printf '%s\n' "$f"
  done
}
P=$(pick logs/pipeline)
E=$(pick logs/errors)
np=0; [ -n "$P" ] && np=$(printf '%s\n' "$P" | wc -l)
ne=0; [ -n "$E" ] && ne=$(printf '%s\n' "$E" | wc -l)
echo "range: $RANGE (from $FROM) - $np pipeline file(s), $ne error file(s)"
[ "$np" -eq 0 ] && { echo "nothing logged in this range"; exit 0; }

# shellcheck disable=SC2086
printf '%s\n' "$P" | tr '\n' '\0' | xargs -0 awk -v errfiles="$(printf '%s\n' "$E" | tr '\n' '\t')" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function bad(where) { nbad++; if (nbad <= 5) badref = badref (nbad > 1 ? ", " : "") where }
function top(arr,   out, k, best, bk, i) {
  out = ""
  for (i = 1; i <= 5; i++) {
    best = 0; bk = ""
    for (k in arr) if (arr[k] > best) { best = arr[k]; bk = k }
    if (bk == "") break
    out = out (i > 1 ? ", " : "") bk " " best; delete arr[bk]
  }
  return out == "" ? "none" : out
}
{ sub(/\r$/, "") }
/^## / {
  if ($0 ~ /^## \[[0-9][0-9]:[0-9][0-9]\] [A-Z][A-Z-]* [^|]*\| ./) {
    cur = $3; ops[cur]++
    if (cur == "TASK") { ntask++; vseen = 0 }
    if (cur == "GATE-SKIPPED") gates++
    if (cur == "MODEL-FALLBACK") fallbacks++
    where = FILENAME ":" FNR
  } else { cur = ""; where = FILENAME ":" FNR; bad(where) }
  next
}
/^- [a-z-]+ \|/ {
  n = split($0, f, "|")
  if (n < 5) { bad(FILENAME ":" FNR); next }
  step = trim(substr(f[1], 3)); rnd = trim(f[3]); res = trim(f[4])
  det = f[5]; for (i = 6; i <= n; i++) det = det "|" f[i]; det = trim(det)
  if (res !~ /^[A-Z][A-Z-]*$/) { bad(FILENAME ":" FNR); next }
  if (res == "FALLBACK" && cur != "MODEL-FALLBACK") fallbacks++
  if (step == "gate" && res == "SKIPPED" && cur != "GATE-SKIPPED") gates++
  if (step == "bughunt") {
    d2 = det; gsub(/unconfirmed/, "UNCONF", d2)
    if (match(d2, /confirmed [0-9]+/)) {
      c = substr(d2, RSTART + 10, RLENGTH - 10) + 0; bconf += c
      if (c > 0) { nbh++; if (nbh <= 8) bhref = bhref (nbh > 1 ? ", " : "") where }
    }
  }
  if (cur != "TASK") next
  if (step == "verify") {
    if (!vseen) { vseen = 1; vt++; if (res == "PASS" && rnd == "r1") vp1++ }
    if (res == "FAIL") vfail++
  }
  if (step == "outcome") {
    out[res]++; r = rnd; sub(/^r/, "", r)
    if (r ~ /^[0-9]+$/) { rsum += r; rn++ }
  }
  if (step == "persona" && res == "BLOCKED") pblock++
  if (step == "plan" && match(det, /skills [^;]+/)) {
    k = split(substr(det, RSTART + 7, RLENGTH - 7), sk, ",")
    for (i = 1; i <= k; i++) { s = trim(sk[i]); if (s != "" && s != "none" && s != "-") skill[s]++ }
  }
}
END {
  # Error files: "- agent | <name>/<model> | r<n> | <RESOLUTION> | ..."
  ne = split(errfiles, ef, "\t")
  for (j = 1; j <= ne; j++) {
    if (ef[j] == "") continue
    while ((getline line < ef[j]) > 0) {
      sub(/\r$/, "", line)
      if (line ~ /^## \[[0-9][0-9]:[0-9][0-9]\] ERROR /) nerr++
      if (line ~ /^- agent \|/) { m = split(line, g, "|"); if (m >= 5) { byagent[trim(g[2])]++; resol[trim(g[4])]++ } }
    }
    close(ef[j])
  }
  nk = 0; for (k in ops) keys[++nk] = k
  for (i = 2; i <= nk; i++) for (j = i; j > 1 && keys[j] < keys[j - 1]; j--) { t = keys[j]; keys[j] = keys[j - 1]; keys[j - 1] = t }
  ol = ""; for (i = 1; i <= nk; i++) ol = ol (i > 1 ? ", " : "") keys[i] " " ops[keys[i]]
  print "operations: " (ol == "" ? "none" : ol)
  pr = vt ? int(100 * vp1 / vt + 0.5) : 0
  printf "tasks: %d - verified %d - first-round PASS %d/%d (%d%%) - verifier FAIL lines %d\n", ntask, vt, vp1, vt, pr, vfail
  printf "outcomes: SUCCESS %d - FAILED %d - ESCALATED %d - average rounds %s\n", out["SUCCESS"], out["FAILED"], out["ESCALATED"], rn ? sprintf("%.1f", rsum / rn) : "-"
  printf "bug hunt: confirmed %d (%s per task) - blocks with confirmed findings: %s\n", bconf, ntask ? sprintf("%.1f", bconf / ntask) : "-", nbh ? bhref (nbh > 8 ? ", ..." : "") : "none"
  printf "persona: BLOCKED %d - gates skipped %d - model fallbacks %d\n", pblock, gates, fallbacks
  print "skills (most used): " top(skill)
  printf "errors: %d - by agent: %s - resolution: %s\n", nerr, top(byagent), top(resol)
  printf "format: %d unparsable line(s)%s\n", nbad, nbad ? " - " badref (nbad > 5 ? ", ..." : "") : ""
  if (vt >= 4 && pr < 50) print "flag: the verifier rejects over half the tasks in the first round - review the plans"
  if (out["ESCALATED"] > 0) print "flag: " out["ESCALATED"] " task(s) escalated to the user"
  if (gates > 0) print "flag: " gates " gate(s) skipped"
  if (fallbacks > 0) print "flag: " fallbacks " step(s) ran on a fallback model - repeat them on Fable"
  if (nbad > 0) print "flag: unparsable lines (older multi-section logs count here)"
}'
