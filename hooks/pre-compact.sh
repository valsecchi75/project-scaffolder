#!/usr/bin/env bash
# PreCompact hook (project-scaffolder v4).
# Before the conversation is summarised, flushes the facts a summary tends to
# blur into .scaffolder/compact-snapshot.md (phase, plan, handoff freshness,
# uncommitted files, all read from disk) and prints the same lines plus what
# to keep: Claude Code uses this stdout as instructions for the summary.
# SessionStart on "compact" then points the new context at the snapshot.
# Never blocks compaction: always exits 0. Silent outside phase-gated projects.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh"

ROOT=$(ps_fs "$PS_PROJECT")
STATE="$ROOT/.scaffolder/phase"
[ -f "$STATE" ] || exit 0

PHASE=$(head -n 1 "$STATE" | tr -cd 'a-z')
case "$PHASE" in
  brainstorm) N=1; NEXT=/2-foundation; PLAN=docs/brief/BRIEF.md ;;
  foundation) N=2; NEXT='/3-design (or /4-build without an interface)'; PLAN="" ;;
  design)     N=3; NEXT=/4-build; PLAN=wiki/design/registry.md ;;
  build)      N=4; NEXT=/5-release; PLAN=$(cd "$ROOT" && ls docs/plans/MILESTONE-*.md 2>/dev/null | sort -V | tail -n 1) ;;
  release)    N=5; NEXT='/milestone-plan for the next milestone (the release skill sets the phase back to build)'
              # the release report; v<version>-rounds.md beside it is the rounds journal
              PLAN=$(cd "$ROOT" && ls docs/release/v*.md 2>/dev/null | grep -v -- '-rounds\.md$' | sort -V | tail -n 1) ;;
  *) exit 0 ;;
esac
[ -n "$PLAN" ] && [ -f "$ROOT/$PLAN" ] || PLAN="none for this phase"

TRIGGER=$(ps_field "$INPUT" trigger | tr -cd 'a-z')
NOW=$(date -u +%s)

if [ -f "$ROOT/wiki/handoff.md" ]; then
  T=$(date -r "$ROOT/wiki/handoff.md" +%s 2>/dev/null)
  if [ -n "$T" ]; then HANDOFF="last written $(( (NOW - T) / 60 )) min before this compaction"
  else HANDOFF="present (age unknown)"; fi
else
  HANDOFF="missing: write it before the next edit"
fi

if CHANGES=$(git --no-optional-locks -C "$ROOT" status --short 2>/dev/null); then
  K=$(printf '%s' "$CHANGES" | grep -c .)
  if [ "$K" -eq 0 ]; then GIT="- Uncommitted changes: none"
  else GIT="- Uncommitted changes ($K, first 20):
$(printf '%s\n' "$CHANGES" | head -n 20 | cut -c1-160 | sed 's/^/    /')"; fi
else
  GIT="- Uncommitted changes: not a git repository"
fi

SNAP="# Compaction snapshot (project-scaffolder)
Written by the PreCompact hook at $(date -u +%Y-%m-%dT%H:%MZ) (${TRIGGER:-unknown} compaction). Read from disk: trust it over the summary.

- Phase: $N of 5, $PHASE. Next command after its exit gate: $NEXT
- Plan: $PLAN
- wiki/handoff.md: $HANDOFF
$GIT"

# The flush. A failed write must not block compaction; the stdout still goes out.
# The snapshot changes at every compaction, so keep it out of git.
{ printf '%s\n' "$SNAP" > "$ROOT/.scaffolder/compact-snapshot.md.tmp" \
    && mv -f "$ROOT/.scaffolder/compact-snapshot.md.tmp" "$ROOT/.scaffolder/compact-snapshot.md"; } 2>/dev/null
[ -e "$ROOT/.scaffolder/.gitignore" ] || printf 'compact-snapshot.md\n' > "$ROOT/.scaffolder/.gitignore" 2>/dev/null

printf '%s\n\n%s\n' "$SNAP" "Compaction instructions from project-scaffolder: copy the snapshot lines above into the summary word for word. Also keep the active /task id and its step, every DEC-NNN decided in this conversation, the last verifier verdict, open findings and unresolved bugs, instructions the user gave only in chat, and the exact next step. End the summary with: first action after compaction is to read .scaffolder/compact-snapshot.md, wiki/handoff.md and the plan, and to bring wiki/handoff.md up to date if it is older than the work in this conversation."
exit 0
