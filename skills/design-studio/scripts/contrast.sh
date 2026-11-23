#!/usr/bin/env bash
# WCAG 2.x contrast ratios, computed, never estimated. Read-only: it changes no file.
#
#   bash contrast.sh FG BG [NEEDS]                  one pair
#   bash contrast.sh [--tokens FILE]... < pairs     one pair per line: FG BG [NEEDS] [label...]
#   bash contrast.sh --self-test
#
# FG, BG: #RGB, #RGBA, #RRGGBB, #RRGGBBAA, rgb()/rgba() without spaces, or a token
# name (--color-text, color-text or var(--color-text)) declared as `--name: value;`
# in a --tokens file: the system's CSS or an artboard page. The first declaration
# of a name wins and var() chains are followed; give another theme's pairs as hex.
# A translucent FG is composited over BG; a translucent BG is an error (give the
# opaque color underneath). NEEDS defaults to 4.5 (text, AA); 3 for large text and
# non-text contrast (WCAG 1.4.11), 7 for AAA. Lines starting with "# " are skipped.
#
# Output: a Markdown table (the critic's "Measured contrast" section) and one
# summary line. Ratios are truncated to two decimals, so 4.499 prints 4.49 and fails.
# Exit 0 every pair passes, 1 a pair fails, 2 bad input.

set -u
ME="${BASH_SOURCE[0]}"

usage() {
  sed -n '2,18p' "$ME" | sed 's/^# \{0,1\}//'
  exit 2
}

if [ "${1:-}" = "--self-test" ]; then
  # Expected ratios: reference values for WCAG 2.x relative luminance.
  expected="21.00 4.47 4.54 1.00 4.00 6.11 17.07"
  got=$(printf '%s\n' \
    '#000 #fff 4.5 black' \
    '#777777 #FFFFFF 4.5 grey 77' \
    '#767676 #ffffff 4.5 grey 76' \
    '#2357D9 #2357D9 3 same' \
    '#00000080 #ffffff 3 alpha' \
    'accent surface 4.5 token' \
    'text var(--surface) 4.5 chained' |
    bash "$ME" --tokens <(printf ':root{\n  --accent: #2357D9;\n  --surface: var(--white);\n  --white:#FFF; --text: rgb(26,28,31);\n}\n') |
    awk -F'|' 'NR>2 && NF>6 { r=$5; sub(/:1 *$/,"",r); gsub(/^ +/,"",r); printf "%s ", r }')
  got="${got% }"
  if [ "$got" = "$expected" ]; then echo "contrast self-test: ok (7 pairs)"; exit 0; fi
  echo "contrast self-test: FAILED"; echo "  expected: $expected"; echo "  got:      $got"; exit 1
fi

tokfiles=()
pos=()
while [ $# -gt 0 ]; do
  case "$1" in
    --tokens) [ $# -ge 2 ] || usage; [ -r "$2" ] || { echo "contrast: cannot read $2"; exit 2; }; tokfiles+=("$2"); shift 2 ;;
    -h|--help) usage ;;
    *) pos+=("$1"); shift ;;
  esac
done

if [ ${#pos[@]} -gt 0 ]; then
  [ ${#pos[@]} -le 3 ] || usage
  input=$(printf '%s ' "${pos[@]}")
elif [ -t 0 ]; then
  usage
else
  input=$(cat)
fi

printf '%s\n' "$input" | awk -v ntok="${#tokfiles[@]}" '
function hexval(s,   i, c, v) {
  v = 0; s = tolower(s)
  for (i = 1; i <= length(s); i++) {
    c = index("0123456789abcdef", substr(s, i, 1)); if (c == 0) return -1
    v = v * 16 + c - 1
  }
  return v
}
# Resolve a spec to C["r"], C["g"], C["b"] (0-255), C["a"] (0-1). Returns 0 and sets ERR on failure.
function color(spec, C,   s, name, depth, h, n, i, parts, x) {
  s = spec; depth = 0
  while (1) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    if (s ~ /^var\(/) { s = substr(s, 5); sub(/\)$/, "", s); sub(/,.*/, "", s); continue }
    if (s ~ /^#/ || tolower(s) ~ /^rgba?\(/) break
    name = s; if (name !~ /^--/) name = "--" name
    if (!(name in TOK)) { ERR = "unknown token " spec; return 0 }
    if (++depth > 8) { ERR = "token loop at " name; return 0 }
    s = TOK[name]
  }
  if (s ~ /^#/) {
    h = substr(s, 2); n = length(h)
    if (n == 3 || n == 4) { x = ""; for (i = 1; i <= n; i++) x = x substr(h, i, 1) substr(h, i, 1); h = x; n *= 2 }
    if ((n != 6 && n != 8) || hexval(h) < 0) { ERR = "not a hex color: " s; return 0 }
    C["r"] = hexval(substr(h, 1, 2)); C["g"] = hexval(substr(h, 3, 2)); C["b"] = hexval(substr(h, 5, 2))
    C["a"] = (n == 8) ? hexval(substr(h, 7, 2)) / 255 : 1
  } else {
    x = s; sub(/^[^(]*\(/, "", x); sub(/\).*$/, "", x); gsub(/[,\/ \t]+/, " ", x)
    n = split(x, parts, " ")
    if (n < 3) { ERR = "not an rgb() color: " s; return 0 }
    for (i = 1; i <= n; i++) if (parts[i] !~ /^[0-9.]+%?$/) { ERR = "unsupported value in " s; return 0 }
    for (i = 1; i <= 3; i++) parts[i] = (parts[i] ~ /%$/) ? parts[i] * 2.55 : parts[i] + 0
    C["r"] = parts[1]; C["g"] = parts[2]; C["b"] = parts[3]
    C["a"] = (n >= 4) ? ((parts[4] ~ /%$/) ? parts[4] / 100 : parts[4] + 0) : 1
  }
  C["hex"] = sprintf("#%02X%02X%02X", int(C["r"] + 0.5), int(C["g"] + 0.5), int(C["b"] + 0.5))
  return 1
}
function lin(c) { c = c / 255; return (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
function lum(r, g, b) { return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
function shown(spec, hex) { return (spec ~ /^#/) ? toupper(spec) : spec " " hex }

# Token files come first on the command line; the pairs arrive on stdin ("-").
FILENAME != "-" {
  line = $0
  while (match(line, /--[A-Za-z0-9_-]+[ \t]*:[^;}]+/)) {
    decl = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
    name = decl; sub(/[ \t]*:.*/, "", name)
    val = decl; sub(/^[^:]*:[ \t]*/, "", val); sub(/[ \t]*!important[ \t]*$/, "", val); sub(/[ \t]+$/, "", val)
    if (!(name in TOK)) TOK[name] = val
  }
  next
}
/^[ \t]*(#([ \t]|$)|$)/ { next }
{
  if (!head++) { print "| Pair | Foreground | Background | Ratio | Needs | Result |"; print "|---|---|---|---|---|---|" }
  fg = $1; bg = $2; needs = 4.5; first = 3
  if ($3 ~ /^[0-9]+(\.[0-9]+)?$/) { needs = $3 + 0; first = 4 }
  label = ""; for (i = first; i <= NF; i++) label = label (label == "" ? "" : " ") $i
  if (label == "") label = fg " on " bg
  rows++
  if (NF < 2) { printf "| %s | %s | - | - | - | error: needs FG and BG |\n", label, fg; errs++; next }
  ERR = ""
  if (!color(fg, F) || !color(bg, B)) { printf "| %s | %s | %s | - | %s:1 | error: %s |\n", label, fg, bg, needs, ERR; errs++; next }
  if (B["a"] < 1) { printf "| %s | %s | %s | - | %s:1 | error: background is translucent |\n", label, fg, bg, needs; errs++; next }
  a = F["a"]
  r = a * F["r"] + (1 - a) * B["r"]; g = a * F["g"] + (1 - a) * B["g"]; b = a * F["b"] + (1 - a) * B["b"]
  l1 = lum(r, g, b); l2 = lum(B["r"], B["g"], B["b"])
  ratio = (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05)
  shownratio = int(ratio * 100 + 1e-9) / 100
  fgtxt = shown(fg, F["hex"]); if (a < 1) fgtxt = fgtxt sprintf(" at %d%% = %s", int(a * 100 + 0.5), sprintf("#%02X%02X%02X", int(r + 0.5), int(g + 0.5), int(b + 0.5)))
  pass = (ratio >= needs)
  if (!pass) fails++
  printf "| %s | %s | %s | %.2f:1 | %s:1 | %s |\n", label, fgtxt, shown(bg, B["hex"]), shownratio, needs, pass ? "pass" : "FAIL"
}
END {
  if (!rows) { print "contrast: no pairs given (see --help)"; exit 2 }
  printf "\n%d pairs: %d pass, %d fail, %d error\n", rows, rows - fails - errs, fails + 0, errs + 0
  exit (errs ? 2 : (fails ? 1 : 0))
}
' ${tokfiles[@]+"${tokfiles[@]}"} -
