---
name: design-studio
description: Use when /3-design runs, when a build task stops on a missing or changed design element, or when the user wants to design, redesign or review a screen, section or feature of a phase-managed project.
---

# Design Studio — phase 3

Design happens before code, always in this order: **references → design system → artboards per section → critique → user approval → Artifact**. Every approved section has its own Artifact page, and `wiki/design/registry.md` links them all. Build ports the approved artboards one to one.

<HARD-GATE>
No application code in this phase; the phase guard refuses it. Artboards are never produced without an approved design system, and a section is never marked approved without a design-critic verdict of Approve and the user's explicit approval. Interaction modes do not skip either.
</HARD-GATE>

Questions and dispatch follow the phase-flow skill. Here an approval offers `Approve` and `Request changes` (details through Other), with a header naming the deliverable; the critic starts after the designer's report, the next designer round after the critic's.

## Gate in

- **Phase entry (`/3-design`):** `.scaffolder/phase` is `foundation` and the foundation was confirmed (its log line exists), or it is already `design`. Write `design`.
- **Section re-entry (`/3-design --section <name>`)** from build or release: allowed without changing the phase. Mark the section `in-progress` in the registry; the build task that needed it waits.
- The brief says `has_interface: no` → stop and suggest `/4-build`.

Read: the brief (brand feel, references, constraints, accessibility requirement), `wiki/design/registry.md`, the working agreements in `CLAUDE.md`. Read `entry.md` (in this skill's folder: artboard home, Local mode, browser check, Step 0 references) when the registry's `Artboard home` line says `Local` or still holds its placeholder, or the `References` line still holds its placeholder. In Local mode its rules replace every Artifact call below.

If the working agreements say design comes from an external source and is ported one to one, the job here is to import and register it: bring the source into `design/`, run the critique, record it. Do not redesign it.

## Skills this phase relies on

Check they are available at the start (`/setup-check` lists them); if one is missing, tell the user which and continue with the agents' built-in rules. The `designer` loads the production skills, the `design-critic` the review skills: `web-design-skills:web-design-engineer` (system declaration, composition), `project-scaffolder:no-ai-design-slop` (passive anti-slop gate), `project-scaffolder:audit-ai-design-slop` (read-only audit, P0–P3), `interfaces:better-typography`, `better-colors`, `better-layout`, `better-accessibility`, `better-interface` (final cross-check).

## Step 1 — The design system

1. Find out what exists. Call the Artifact tool with `action: "quickstart"` and `intent: "other"` (a design system is created with `intent: "other"`); its result lists the user's design systems and the Design System type, and is the mode check. Also look in `design/system/`; in Local mode, ask whether the user has a design system file or link to start from.
2. Ask one question: reuse one of the listed design systems, extend one, or create a new one. Recommend from the brand feel.
3. To create or extend one, set the direction with at most three questions, one at a time: the visual thesis in one sentence, the typeface direction, the color mood. Then dispatch `project-scaffolder:designer` with the direction, the brand inputs, the `References` line and the type's instructions (creating from the Design System type: publish it first with its `type_url` and a title, and pass the instructions that returns, verbatim). The system defines at least: color primitives and semantic roles (text, surface, border, accent, success, warning, danger, focus), type scale with line heights, spacing scale, radii, elevation, motion durations, and the focus, disabled and error states.
4. Dispatch `project-scaffolder:design-critic` on the system: contrast of every semantic text and border pair against its surfaces, type scale readability, missing roles. Contrast comes from `${CLAUDE_SKILL_DIR}/scripts/contrast.sh` (WCAG 2.x, read-only; `--self-test` checks it), never estimated: a report whose ratios did not come from it goes back to the critic.
5. Loop designer ↔ critic until Approve, at most three rounds; then show the user what is still open.
6. Show the system (its Artifact link) and ask for approval. On approval, record it in the registry's **Design system** row with link and date, and log `## [date] decision | Design system approved`.

## Step 2 — Section inventory

Confirm the registry's sections against the first-release scope: one row per place or flow a user sees as distinct (onboarding, home, search, checkout, settings…). Ask the user to confirm the list and its order. Shared components several sections need (navigation, forms, empty and error states) can be a section of their own, designed first.

## Step 3 — Each section, one at a time

1. **Direction.** At most three questions, one at a time, only what the brief and the system do not settle: the primary task, the content priority, the states that matter. Record the answers in the row's notes.
2. **Create its Artifact.** `quickstart` with `intent: "design"`; publish a new artifact from the Design type it names, with `type_url`, the title `{Project} — {Section}` and `auto_open: "after_first_write"`, and attach the approved design system as the type's instructions describe. Keep the instructions the result returns.
3. **Produce.** Dispatch `project-scaffolder:designer` with the direction, the system, the `References` line, the folder `design/<section-slug>/` and the type's instructions verbatim. Required frames: default, empty, loading, error, the smallest and largest target viewports, and any state the flow needs (success, permission denied, offline…). Empty and error states are where interfaces fail: never one frame only.
4. **Critique.** Dispatch `project-scaffolder:design-critic` on the frames with the system, the `References` line, the accessibility target (default WCAG 2.2 AA) and the `Browser check` value; when on, the page's URL (the Artifact link, or `file:///` plus the local page's path). Block → back to the designer with the findings. At most three rounds, then bring the open findings to the user with their evidence: never hide one.
5. **Publish.** Fill the Artifact with the designer's files exactly as the type's instructions say, so the page shows the frames, and open it for the user. Local mode: give the absolute path of `design/<section-slug>/index.html`.
6. **Approval.** Show the link, the critic's verdict, its measured-contrast summary, its `Browser check` line and the P2/P3 items left, and ask for approval. Change requests go back to point 3. On approval, update the row: status `approved`, Artifact link, local folder, critic verdict, date. Log `## [date] decision | Design approved: <section>`.

One Artifact per section, never several in one: that is how build finds the right design and changes stay traceable. Never approve a section on the user's behalf.

## Gate out

When every section in the first-release scope is `approved`:

1. Dispatch `project-scaffolder:design-critic` once across all approved sections for cross-section drift (navigation, type roles, spacing, button styles).
2. Show the registry and ask the user to close the design phase.
3. Log `## [date] phase | Design complete` (the command gate opens `/4-build` on this line) and give the next command: `/4-build`.

## Changes after approval

A change to an approved section reopens it: status `changed`, the build tasks that implemented it listed in the row's notes, and steps 3.3 to 3.6 again. The old Artifact stays as the record, the new one linked beside it; in Local mode, copy the old page to `index.<YYYY-MM-DD>.html` first. Record a decision when the change alters scope or behaviour.

## Red flags

| Thought | Reality |
|---|---|
| "The system can be extracted later from the screens" | Screens without a system drift, and the critique has nothing to measure against. System first. |
| "No Artifact tool, so design waits" | Local mode (`entry.md`): the same artboards as a self-contained page under `design/`. |
| "I'll browse a few competitor sites for inspiration" | References come from the user and from idea-research after the user accepts its cost. The designer gets the picked patterns, never the pages. |
| "A quick prototype in the app is faster" | The phase guard refuses application code here. Artboards are the prototype. |
