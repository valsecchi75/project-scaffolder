#!/usr/bin/env bash
# A phase-4 project whose current milestone M1 has no plan (no docs/plans/).
set -e
mkdir -p .scaffolder docs/brief wiki/product src
printf 'build\n' > .scaffolder/phase
printf '# Brief\n\nA family task list. Approved.\n' > docs/brief/BRIEF.md
printf '# Roadmap\n\n## M1 - Task list basics\n\nStatus: in progress (current). Goal: create, complete and export tasks.\n' > wiki/product/roadmap.md
printf 'export const tasks = [];\n' > src/tasks.js
