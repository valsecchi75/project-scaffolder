#!/usr/bin/env bash
# SessionStart bootstrap (project-scaffolder v4).
# In a phase-gated project it tells the session where it is in the sequence,
# what is allowed, and which command comes next. In any other project it
# prints nothing, so the plugin stays silent outside the projects it manages.

. "$(dirname "$0")/lib.sh"

STATE="$PS_PROJECT/.scaffolder/phase"

emit() {  # $1 = context text; \n sequences are already JSON newlines
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$1"
  exit 0
}

if [ ! -f "$STATE" ]; then
  # A project scaffolded by v3 has the hub and the wiki but no phase state.
  if [ -f "$PS_PROJECT/CLAUDE.md" ] && [ -f "$PS_PROJECT/wiki/handoff.md" ] \
     && grep -q 'Task Pipeline' "$PS_PROJECT/CLAUDE.md" 2>/dev/null; then
    emit "[project-scaffolder] This project was scaffolded by v3 and has no phase state. Tell the user once that /2-foundation --upgrade migrates it to the v4 phase flow (phase state, secrets/, raw/, native skill location). Until then work as the project CLAUDE.md says."
  fi
  exit 0
fi

PHASE=$(head -n 1 "$STATE" | tr -cd 'a-z')

case "$PHASE" in
  brainstorm)
    NOW="Phase 1 of 5: BRAINSTORM. Questions only, one at a time. No code, no scaffolding, no design, no dependency installs. The only files written are docs/brief/BRIEF.md and raw/."
    GATE="Exit gate: the user explicitly approves docs/brief/BRIEF.md."
    NEXT="Next command after the gate: /2-foundation." ;;
  foundation)
    NOW="Phase 2 of 5: FOUNDATION. Build the second brain and the agent setup: CLAUDE.md, raw/, wiki/, project skills, agent roster, secrets/, guardrails. No application code and no design files."
    GATE="Exit gate: the structure check passes and the user confirms."
    NEXT="Next command after the gate: /3-design (or /4-build when the project has no user interface)." ;;
  design)
    NOW="Phase 3 of 5: DESIGN. Design system first, then one artboard page per section or feature, then slop audit and accessibility check. No application code."
    GATE="Exit gate: every section in scope is approved by the user and recorded in wiki/design/registry.md with its Artifact link."
    NEXT="Next command after the gate: /4-build." ;;
  build)
    NOW="Phase 4 of 5: BUILD. Platform decision, then milestone plan, then tasks through /task. Every task ends with verification and a bug hunt before it counts as done."
    GATE="Exit gate: the milestones in the release scope are closed with evidence."
    NEXT="Next command after the gate: /5-release." ;;
  release)
    NOW="Phase 5 of 5: RELEASE. Whole-project debug with the strongest model, mass test sweep, release gate, then version, changelog and tag. Never push or publish without the user saying so."
    GATE="Exit gate: no open confirmed finding, gate green, user approves the release."
    NEXT="After the release, /4-build opens the next milestone." ;;
  *)
    exit 0 ;;
esac

emit "[project-scaffolder] This project follows a strict phase sequence: 1 brainstorm, 2 foundation, 3 design, 4 build, 5 release. One phase at a time; a phase is left only through its exit gate.\n\n$NOW\n$GATE\n$NEXT\n\nModel routing is binding: Fable plans and verifies, Opus implements, Sonnet runs redundant checks and mass tests, Haiku is not used. Dispatch the plugin agents (architect, builder, designer, verifier, bug-hunter, design-critic, sweeper, persona-tester) instead of generic subagents and never override their model.\n\nSecrets: secrets/ may be read to use keys locally. Its contents are never committed, published, or copied into chat, wiki, logs, docs, code or Artifacts.\n\nRead first: CLAUDE.md, wiki/handoff.md, wiki/index.md. Load the project-scaffolder:phase-flow skill before acting on any phase command. In this project the phase flow replaces generic brainstorming and planning skills from other plugins for the same work."
