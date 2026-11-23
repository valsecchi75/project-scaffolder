#!/usr/bin/env bash
# Release gate, stage 7: does what ships contain a value from secrets/?
# Read-only. A key read at build time (a bundler's env prefix, a config
# inlined into the bundle) ends up in the files users download, where no
# guard looks. This scan reads secrets/ the way the secrets guard does
# (hooks/secrets-lib.sh, ps_secret_map), so both recognise the same values.
#
#   bash build-secrets.sh <path>...
#
# <path>: the build output folders or files (wiki/tech-stack.md), or, without
# a build step, the folders that ship; relative to the project root, which is
# found from the current directory (nearest .scaffolder/phase, else the git
# root). In a worktree without secrets/, the main checkout's folder is used.
# A secrets/ folder is never scanned as output, and no path may lie in one.
#
# Prints the files that hold a value with the secret's label (file and
# variable name), never the value. Last line: the verdict.
# Exit 0 clean (or no keys expected), 1 a value found, 2 not checked.
# No by-hand fallback: checking by hand would put the values in the
# transcript. Without Git Bash the guards refuse every shell call anyway.

set -u
LIB="$(cd "$(dirname "$0")/../../../hooks" 2>/dev/null && pwd)/secrets-lib.sh"
notrun() { echo "build-secrets: NOT CHECKED: $1"; exit 2; }
[ $# -gt 0 ] || notrun "name the build output (for example dist/ or build/)"
[ -f "$LIB" ] || notrun "cannot find hooks/secrets-lib.sh beside this plugin"

# Project root: the nearest .scaffolder/phase above here, else the git root.
d=$PWD
while [ ! -f "$d/.scaffolder/phase" ] && [ "$(dirname "$d")" != "$d" ]; do d=$(dirname "$d"); done
if [ -f "$d/.scaffolder/phase" ]; then cd "$d"
else r=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$r" || notrun "not inside a project (no .scaffolder/phase, no git root)"; fi
. "$LIB"

# The paths first: nothing built means nothing checked, whatever secrets/ holds.
ROOT=$PWD
PATHS=()
for p in "$@"; do
  [ -e "$p" ] || { echo "missing: $p (not built yet?)"; continue; }
  abs="$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")"
  case "$abs/" in
    "$ROOT"/./|"$ROOT"/../*) notrun "$p: name the build output folder inside the project" ;;
    "$ROOT"/*) ;;
    *) notrun "$p lies outside the project ($ROOT)" ;;
  esac
  case "/${abs#"$ROOT"/}/" in
    */secrets/*) notrun "$p is inside a secrets/ folder: name the build output, never the keys" ;;
  esac
  PATHS+=("$p")
done
[ "${#PATHS[@]}" -gt 0 ] || notrun "none of the paths exists: build first, then rerun"

SECRETS="$PWD/secrets"
if [ ! -d "$SECRETS" ]; then
  main=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  [ -n "$main" ] && [ -d "$(dirname "$main")/secrets" ] && SECRETS="$(dirname "$main")/secrets"
fi
if [ ! -d "$SECRETS" ]; then
  if [ -f .env.example ] && grep -qE '^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' .env.example; then
    notrun ".env.example names keys but there is no secrets/ folder here or in the main checkout"
  fi
  echo "build-secrets: no secrets/ folder and no key in .env.example: nothing to check"; exit 0
fi

# Every key file must be read in full, or the verdict is "not checked": a file
# the scan cannot open, a large one, or one in UTF-16 (PowerShell 5.1 writes
# it) would otherwise count as "no value".
BAD=""
while IFS= read -r f; do
  rel=${f#"$SECRETS"/}
  if [ -s "$f" ] && [ "$(head -c 1 -- "$f" 2>/dev/null | wc -c)" -eq 0 ]; then BAD="$BAD $rel(unreadable)"
  elif [ -n "$(find "$f" -size +255k 2>/dev/null)" ]; then BAD="$BAD $rel(256KiB+)"
  elif [ "$(head -c 4096 -- "$f" | tr -d '\000' | wc -c)" -ne "$(head -c 4096 -- "$f" | wc -c)" ]; then BAD="$BAD $rel(UTF-16/binary)"
  fi
done < <(find "$SECRETS" -type f ! -iname 'README.md' 2>/dev/null)
[ -z "$BAD" ] || notrun "cannot read these key files as text:$BAD. Save them as UTF-8 under 256 KiB, or run this in your own terminal (a sandbox may block reads)"

MAP=$(ps_secret_map)
VALUES=$(printf '%s\n' "$MAP" | cut -f1 | grep -v '^$')
[ -n "$VALUES" ] || { echo "build-secrets: secrets/ holds no value recognised as a key: nothing to check"; exit 0; }
NV=$(printf '%s\n' "$VALUES" | wc -l | tr -d ' ')
NF=$(find "${PATHS[@]}" -path '*/secrets' -prune -o -type f -print 2>/dev/null | wc -l | tr -d ' ')

# -a: bundles, source maps and binaries are all searched as text.
HITS=$(grep -rlaF --exclude-dir=secrets -f <(printf '%s\n' "$VALUES") -- "${PATHS[@]}" 2>/dev/null)
if [ -z "$HITS" ]; then
  echo "build-secrets: clean ($NV values from secrets/ looked for in $NF files)"
  exit 0
fi
N=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  N=$((N + 1))
  hit=$(grep -oaF -f <(printf '%s\n' "$VALUES") -- "$f" 2>/dev/null | head -n 1)
  label=$(printf '%s\n' "$MAP" | awk -F '\t' -v h="$hit" '$1 == h { print $2; exit }' | tr -cd 'A-Za-z0-9 ._:/-')
  echo "leak: $f (${label:-a value from secrets/})"
done <<< "$HITS"
echo "build-secrets: $N file(s) hold a value from secrets/: RED. The key must not ship: move the call behind a server or proxy, rotate the key, rebuild, rerun"
exit 1
