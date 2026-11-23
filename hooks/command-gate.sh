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
# On top of the phase, the gate facts, judged by the same script as
# /phase-status (phase-status.sh --facts), so the two never disagree:
#   /2-foundation from brainstorm     the brief says status: approved
#                                     (a v3 project to --upgrade has no phase
#                                      file, so it passes above)
#   /3-design, /4-build from foundation  "phase | Foundation complete" logged
#   /4-build from foundation/design   the design phase closed (registry clean
#                                     and "phase | Design complete"), or the
#                                     brief says has_interface: no
#
# Going back is always allowed. No .scaffolder/phase file, an unknown phase
# word or a command of another plugin: pass through silently. Fails open (no
# onFailure): a missing script means no fact gate, never a blocked command.

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
  project-scaffolder:2-foundation) NEED=1; NEEDNAME=brainstorm ;;
  project-scaffolder:3-design|project-scaffolder:4-build) NEED=2; NEEDNAME=foundation ;;
  project-scaffolder:5-release|project-scaffolder:task|project-scaffolder:milestone-plan|project-scaffolder:milestone-close|project-scaffolder:fix-bug|project-scaffolder:improve)
    NEED=4; NEEDNAME=build ;;
  *) exit 0 ;;
esac

# Fixed strings only (no quotes or backslashes), so the JSON stays valid.
block() { printf '{"decision":"block","reason":"project-scaffolder: %s /phase-status shows what is open."}\n' "$1"; exit 0; }

[ "$N" -ge "$NEED" ] || block "$(printf '/%s needs phase %s (%s) or later. This project is in phase %s of 5 (%s): finish its exit gate, then run %s.' \
  "${CMD#project-scaffolder:}" "$NEED" "$NEEDNAME" "$N" "$PHASE" "$NEXT")"

# Gate facts (phase-status.sh --facts): only for the step forward they guard.
# The values are the script's fixed words; tr keeps the reason JSON-safe anyway.
fact() { printf '%s\n' "$FACTS" | sed -n "s/^$1=//p" | head -n 1 | tr -cd 'a-z'; }
case "$CMD:$N" in
  project-scaffolder:2-foundation:1|project-scaffolder:3-design:2|project-scaffolder:4-build:2|project-scaffolder:4-build:3) ;;
  *) exit 0 ;;
esac
FACTS=$(bash "$(dirname "$0")/../skills/phase-flow/scripts/phase-status.sh" --facts "$PS_PROJECT" 2>/dev/null)
[ -n "$FACTS" ] || exit 0

case "$CMD:$N" in
  project-scaffolder:2-foundation:1)
    [ "$(fact brief)" = approved ] || block "/2-foundation needs an approved brief, and docs/brief/BRIEF.md is $(fact brief) (its status must read approved). Finish /1-brainstorm: the brief is approved only when you say so." ;;
  *:2)
    [ "$(fact foundation)" = complete ] || block "/${CMD#project-scaffolder:} needs the foundation closed: the line phase | Foundation complete in wiki/log.md, written when you confirm the structure check. Finish /2-foundation first." ;;
esac
case "$CMD" in
  project-scaffolder:4-build)
    [ "$(fact design)" = complete ] || [ "$(fact interface)" = no ] \
      || block "/4-build needs the design phase closed (every section approved in wiki/design/registry.md and the line phase | Design complete in wiki/log.md), or a brief with has_interface: no. Run /3-design until you close the phase." ;;
esac
exit 0
