#!/usr/bin/env bash
# Release gate, stage 7: does what ships contain a value from secrets/?
# Read-only. A key read at build time (a bundler's env prefix, a config
# inlined into the bundle) ends up in the files users download, where no
# guard looks. This scan reads secrets/ the way the secrets guard does
# (hooks/secrets-lib.sh, ps_secret_map), so both recognise the same values.
#
#   bash build-secrets.sh [--project <dir>] <path>...
#
# <path>: the build output folders or files (wiki/tech-stack.md), or, without
# a build step, the folders that ship. Relative paths are taken from the
# project directory (default: the current one).
#
# Prints the files that hold a value with the secret's label (file and
# variable name), never the value. Last line: the verdict.
# Exit 0 clean (or nothing to check), 1 a value found, 2 cannot run.

set -u
LIB="$(cd "$(dirname "$0")/../../../hooks" 2>/dev/null && pwd)/secrets-lib.sh"
PROJECT=.
if [ "${1:-}" = --project ]; then PROJECT=${2:-.}; shift 2 2>/dev/null || shift; fi
[ $# -gt 0 ] || { echo "build-secrets: name the build output (for example dist/ or build/)"; exit 2; }
cd "$PROJECT" 2>/dev/null || { echo "build-secrets: cannot enter $PROJECT"; exit 2; }
[ -f "$LIB" ] || { echo "build-secrets: cannot find hooks/secrets-lib.sh beside this plugin"; exit 2; }
. "$LIB"

SECRETS="$PWD/secrets"
[ -d "$SECRETS" ] || { echo "build-secrets: no secrets/ folder: nothing to check"; exit 0; }
MAP=$(ps_secret_map)
VALUES=$(printf '%s\n' "$MAP" | cut -f1 | grep -v '^$')
if [ -z "$VALUES" ]; then
  # Key files this process cannot open (a sandbox applying a Read deny rule)
  # would otherwise pass as "nothing to check": that is not a clean result.
  UNREAD=0
  while IFS= read -r f; do head -c 1 -- "$f" >/dev/null 2>&1 || UNREAD=$((UNREAD + 1)); done \
    < <(find "$SECRETS" -type f ! -iname 'README.md' 2>/dev/null)
  if [ "$UNREAD" -gt 0 ]; then
    echo "build-secrets: cannot read $UNREAD file(s) in secrets/ (a sandbox or deny rule?): not checked. Run this command in your own terminal"
    exit 2
  fi
  echo "build-secrets: secrets/ holds no recognisable value: nothing to check"; exit 0
fi
NV=$(printf '%s\n' "$VALUES" | wc -l | tr -d ' ')

PATHS=()
for p in "$@"; do
  if [ -e "$p" ]; then PATHS+=("$p"); else echo "missing: $p (not built yet?)"; fi
done
[ "${#PATHS[@]}" -gt 0 ] || { echo "build-secrets: none of the paths exists: build first, then rerun"; exit 2; }
NF=$(find "${PATHS[@]}" -type f 2>/dev/null | wc -l | tr -d ' ')

# -a: bundles, source maps and binaries are all searched as text.
HITS=$(grep -rlaF -f <(printf '%s\n' "$VALUES") -- "${PATHS[@]}" 2>/dev/null)
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
