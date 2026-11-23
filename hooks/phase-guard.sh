#!/usr/bin/env bash
# PreToolUse guard for Write/Edit/NotebookEdit (project-scaffolder v4).
# Makes the phase sequence mechanical: while the project is in an early phase,
# files that belong to a later phase cannot be written.
#
#   brainstorm  -> questions only: just the brief, raw sources and phase state
#   foundation  -> knowledge base and agent setup: no application code
#   design      -> design files and knowledge base: no application code
#   build, release -> unrestricted
#
# No .scaffolder/phase file means the project is not phase-gated: pass through.
# Shell writes are not parsed here; the phase skills forbid them in prose.

INPUT=$(cat)
. "$(dirname "$0")/lib.sh"

STATE="$PS_PROJECT/.scaffolder/phase"
[ -f "$STATE" ] || exit 0
PHASE=$(head -n 1 "$STATE" | tr -cd 'a-z')

FILE=$(ps_field "$INPUT" file_path)
[ -z "$FILE" ] && FILE=$(ps_field "$INPUT" notebook_path)
[ -z "$FILE" ] && exit 0
REL=$(ps_rel "$FILE")
[ -z "$REL" ] && exit 0

case "$PHASE" in
  brainstorm)
    case "$REL" in
      docs/brief/*|raw/*|.scaffolder/*) exit 0 ;;
    esac
    ps_deny "project-scaffolder: phase 1 (brainstorm) is questions only. Nothing is written except docs/brief/ and raw/. Get the brief approved, then run /2-foundation."
    ;;
  foundation)
    case "$REL" in
      claude.md|readme.md|.gitignore|.env.example) exit 0 ;;
      wiki/*|raw/*|docs/*|.claude/*|guardrails/*|daily-log/*|logs/*|secrets/*|.scaffolder/*) exit 0 ;;
    esac
    ps_deny "project-scaffolder: phase 2 (foundation) builds the knowledge base and the agent setup, not the product. Application and design files wait for /3-design and /4-build."
    ;;
  design)
    case "$REL" in
      claude.md) exit 0 ;;
      design/*|wiki/*|raw/*|docs/*|guardrails/*|daily-log/*|logs/*|.scaffolder/*|.claude/skills/*) exit 0 ;;
    esac
    ps_deny "project-scaffolder: phase 3 (design) produces the design system and artboards under design/. Application code waits for /4-build, after the design is approved."
    ;;
esac
exit 0
