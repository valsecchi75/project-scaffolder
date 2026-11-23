#!/usr/bin/env bash
# SessionStart bootstrap (project-scaffolder v4).
# In a phase-gated project it tells the session where it is in the sequence,
# what is allowed, and which command comes next (additionalContext, for
# Claude), and shows the user a one-line banner with the phase, the next
# command and the session model the flow is designed for (systemMessage:
# shown to the user, costs no model tokens; this hook must stay synchronous).
# In any other project it prints nothing, so the plugin stays silent outside
# the projects it manages.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh"

STATE="$PS_PROJECT/.scaffolder/phase"

# $1 = context text, $2 = banner; \n sequences are already JSON newlines.
# Both are fixed strings or sanitised values: no quotes or backslashes.
emit() {
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$2" "$1"
  exit 0
}

if [ ! -f "$STATE" ]; then
  # A project scaffolded by v3 has the hub and the wiki but no phase state.
  if [ -f "$PS_PROJECT/CLAUDE.md" ] && [ -f "$PS_PROJECT/wiki/handoff.md" ] \
     && grep -q 'Task Pipeline' "$PS_PROJECT/CLAUDE.md" 2>/dev/null; then
    emit "[project-scaffolder] This project was scaffolded by v3 and has no phase state. Tell the user once that /2-foundation --upgrade migrates it to the v4 phase flow (phase state, secrets/, raw/, native skill location). Until then work as the project CLAUDE.md says." \
         "project-scaffolder | v3 project without phase state | next: /2-foundation --upgrade"
  fi
  exit 0
fi

PHASE=$(head -n 1 "$STATE" | tr -cd 'a-z')

case "$PHASE" in
  brainstorm)
    N=1; SHOW="/2-foundation once the brief is approved"
    NOW="Phase 1 of 5: BRAINSTORM. Questions only, one topic at a time. No code, no scaffolding, no design, no dependency installs. The only files written are docs/brief/BRIEF.md and raw/."
    GATE="Exit gate: the user explicitly approves docs/brief/BRIEF.md."
    NEXT="Next command after the gate: /2-foundation." ;;
  foundation)
    N=2; SHOW="/3-design (or /4-build without an interface) once the structure check passes"
    NOW="Phase 2 of 5: FOUNDATION. Build the second brain and the agent setup: CLAUDE.md, raw/, wiki/, project skills, agent roster, secrets/, guardrails. No application code and no design files."
    GATE="Exit gate: the structure check passes and the user confirms."
    NEXT="Next command after the gate: /3-design (or /4-build when the project has no user interface)." ;;
  design)
    N=3; SHOW="/4-build once every section is approved"
    NOW="Phase 3 of 5: DESIGN. Design system first, then one artboard page per section or feature, then slop audit and accessibility check. No application code."
    GATE="Exit gate: every section in scope is approved by the user and recorded in wiki/design/registry.md with its Artifact link or local page path."
    NEXT="Next command after the gate: /4-build." ;;
  build)
    N=4; SHOW="/task for each task, /5-release once the release milestones are closed"
    NOW="Phase 4 of 5: BUILD. Platform decision, then milestone plan, then tasks through /task. Every task ends with verification and a bug hunt before it counts as done."
    GATE="Exit gate: the milestones in the release scope are closed with evidence."
    NEXT="Next command after the gate: /5-release." ;;
  release)
    N=5; SHOW="/5-release resumes the release; then /milestone-plan for the next milestone"
    NOW="Phase 5 of 5: RELEASE. A green build and test run, the verification rounds the user chooses, fixes, the release gate, then version, changelog and tag. Never push or publish without the user saying so."
    GATE="Exit gate: no open confirmed finding, gate green, user approves the release."
    NEXT="After the release the phase returns to build: /milestone-plan plans the next milestone." ;;
  *)
    exit 0 ;;
esac

# Session model, for the banner only (additionalContext stays identical across
# sessions so the prompt cache holds). The field can be missing, e.g. after
# /clear; the value is reduced to model-id characters before it enters JSON.
MODEL=$(ps_field "$INPUT" model | sed 's#[^][A-Za-z0-9._:@/-]##g' | cut -c1-80)
case "$MODEL" in
  "")                        MOD="designed for a Fable session" ;;
  *[Ff][Aa][Bb][Ll][Ee]*)    MOD="session on Fable, as designed" ;;
  *)                         MOD="designed for Fable, this session runs $MODEL: /model fable" ;;
esac

# Right after a compaction, point the new context at what pre-compact.sh
# flushed to disk (fixed text: only the source decides whether it appears).
AFTER=""
if [ "$(ps_field "$INPUT" source)" = compact ] && [ -f "$PS_PROJECT/.scaffolder/compact-snapshot.md" ]; then
  AFTER="\n\nA compaction just ran. Before the next edit or dispatch, read .scaffolder/compact-snapshot.md, wiki/handoff.md and the current plan; trust them over the summary."
fi

emit "[project-scaffolder] This project follows a strict phase sequence: 1 brainstorm, 2 foundation, 3 design, 4 build, 5 release. One phase at a time; a phase is left only through its exit gate.\n\n$NOW\n$GATE\n$NEXT\n\nModel routing is binding: Fable plans and verifies, Opus implements, Sonnet runs redundant checks and mass tests, Haiku is not used. Dispatch the plugin agents by their scoped names (project-scaffolder:<agent>) instead of generic subagents, and never override their model.\n\nSecrets: secrets/ may be read to use keys locally. Its contents are never committed, published, or copied into chat, wiki, logs, docs, code or Artifacts.\n\nCLAUDE.md is already loaded; before other work read wiki/handoff.md and wiki/index.md when they exist. In this project the phase flow (project-scaffolder:phase-flow) replaces generic brainstorming and planning skills from other plugins for the same work.$AFTER" \
     "project-scaffolder | phase $N/5 $PHASE | next: $SHOW | $MOD"
