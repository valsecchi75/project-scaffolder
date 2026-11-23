---
description: Phase 3 of 5. Design system first, then artboards for each section, slop and accessibility critique, user approval, one Artifact page per section. --section <name> reopens one section from a later phase.
argument-hint: "[--section <name>]"
model: fable
---

Load the `project-scaffolder:phase-flow` skill, then the `project-scaffolder:design-studio` skill, and follow it exactly.

Direct the work; the `designer` agent produces and the `design-critic` agent reviews. No section is approved without the critic's Approve and the user's explicit approval. The phase ends when every section in scope is approved in `wiki/design/registry.md`; the next command is `/4-build`.

Arguments: $ARGUMENTS
