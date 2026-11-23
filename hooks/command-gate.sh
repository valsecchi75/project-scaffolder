#!/usr/bin/env bash
# UserPromptExpansion gate (project-scaffolder v4).
# Blocks a typed phase or build command that comes too early in the sequence,
# before its body loads and costs a turn. Runs only on the typed path. Most of
# these commands are user-only (disable-model-invocation), so typing is their
# only way in; /task and /fix-bug Claude can also start itself, and then
# phase-guard.sh still refuses the early writes.
#
#   /3-design, /4-build        need phase 2 (foundation) or later
#                              (4-build from foundation = project without an interface;
#                               3-design from build or release = --section reopen)
#   /5-release, /task, /milestone-plan, /milestone-close, /fix-bug, /improve
#                              need phase 4 (build) or later
#
# Going back is always allowed. No .scaffolder/phase file, an unknown phase
# word or a command of another plugin: pass through silently.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh"

STATE="$PS_PROJECT/.scaffolder/phase"
[ -f "$STATE" ] || exit 0

PHASE=$(head -n 1 "$STATE" | tr -cd 'a-z')
case "$PHASE" in
  brainstorm) N=1; NEXT=/2-foundation ;;
  foundation) N=2; NEXT='/3-design (or /4-build without an interface)' ;;
  design)     N=3; NEXT=/4-build ;;
  *) exit 0 ;;   # build, release (nothing is gated there) or unknown
esac

CMD=$(ps_field "$INPUT" command_name)
case "$CMD" in
  project-scaffolder:3-design|project-scaffolder:4-build) NEED=2; NEEDNAME=foundation ;;
  project-scaffolder:5-release|project-scaffolder:task|project-scaffolder:milestone-plan|project-scaffolder:milestone-close|project-scaffolder:fix-bug|project-scaffolder:improve)
    NEED=4; NEEDNAME=build ;;
  *) exit 0 ;;
esac

[ "$N" -ge "$NEED" ] && exit 0

# Fixed strings only (no quotes or backslashes), so the JSON stays valid.
printf '{"decision":"block","reason":"project-scaffolder: /%s needs phase %s (%s) or later. This project is in phase %s of 5 (%s): finish its exit gate, then run %s. /phase-status shows what is open."}\n' \
  "${CMD#project-scaffolder:}" "$NEED" "$NEEDNAME" "$N" "$PHASE" "$NEXT"
exit 0
