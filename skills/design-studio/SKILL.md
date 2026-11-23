---
name: design-studio
description: Use when /3-design runs, when a build task stops on a missing or changed design element, or when the user wants to design, redesign or review a screen, section or feature of a phase-managed project.
---

# Design Studio — phase 3

Design happens before code, always in this order: **design system → artboards per section → critique → user approval → Artifact**. Every approved section has its own Artifact page, and `wiki/design/registry.md` links them all. Build ports the approved artboards one to one.

<HARD-GATE>
No application code in this phase; the phase guard refuses it. Artboards are never produced without an approved design system, and a section is never marked approved without a design-critic verdict of Approve and the user's explicit approval. Interaction modes do not skip either.
</HARD-GATE>

## Gate in

- **Phase entry (`/3-design`):** `.scaffolder/phase` is `foundation` and the foundation was confirmed (its log line exists), or it is already `design`. Write `design`.
- **Section re-entry (`/3-design --section <name>`)** from build or release: allowed without changing the phase. Mark the section `in-progress` in the registry; the build task that needed it waits.
- The brief says `has_interface: no` → stop and suggest `/4-build`.

Read: the brief (brand feel, references, constraints, accessibility requirement), `wiki/design/registry.md`, the working agreements in `CLAUDE.md`.

If the working agreements say design comes from an external source and is ported one to one, the job here is to import and register it: bring the source into `design/`, run the critique, record it. Do not redesign it.

## Skills this phase relies on

Check they are available at the start (the `/setup-check` command lists them). If one is missing, tell the user which and continue with the agents' built-in rules.

| Step | Skill |
|---|---|
| Design-system declaration, artboard composition | `web-design-skills:web-design-engineer` |
| Passive anti-slop gate while composing | `project-scaffolder:no-ai-design-slop` |
| Slop audit (read-only, findings P0–P3) | `project-scaffolder:audit-ai-design-slop` |
| Typography, color, layout, accessibility, final cross-check | `interfaces:better-typography`, `interfaces:better-colors`, `interfaces:better-layout`, `interfaces:better-accessibility`, `interfaces:better-interface` |

The `designer` agent loads the production skills; the `design-critic` agent loads the review skills. You direct, they produce and judge.

## Step 1 — The design system

1. Find out what exists. Call the Artifact tool with `action: "quickstart"` and `intent: "other"` (a design system is created with `intent: "other"`); its result lists the user's existing design systems and the Design System type. Also look in `design/system/`.
2. Ask the user, one question: reuse one of the listed design systems, extend one, or create a new one for this project. Recommend based on the brand feel.
3. To create or extend one, set the direction first with at most three questions, one at a time: the visual thesis in one sentence, the typeface direction, the color mood. Then dispatch `project-scaffolder:designer` with the direction, the brand inputs and the type's instructions (when creating from the Design System type, publish it first with its `type_url` and a title, and pass the instructions that result returns, verbatim).
   The system must define at least: color primitives and semantic roles (text, surface, border, accent, success, warning, danger, focus), type scale with line heights, spacing scale, radii, elevation, motion durations, and the rules for focus, disabled and error states.
4. Dispatch `project-scaffolder:design-critic` on the system: contrast of every semantic text and border pair against its surfaces, type scale readability, missing roles.
5. Loop designer ↔ critic until Approve, at most three rounds; then show the user what is still open.
6. Show the user the system (its Artifact link) and ask for approval. On approval, record it in the registry's **Design system** row with the link and the date, and log `## [date] decision | Design system approved`.

## Step 2 — Section inventory

Confirm the list of sections and features in the registry against the first-release scope. One row per section that a user sees as a distinct place or flow (onboarding, home, search, checkout, settings…). Ask the user to confirm the list and its order. Shared components that several sections need (navigation, forms, empty and error states) can be a section of their own, designed first.

## Step 3 — Each section, one at a time

For each section in order:

1. **Direction.** At most three questions, one at a time, only what the brief and the system do not settle: the primary task, the content priority, the states that matter. Record the answers in the registry row's notes.
2. **Create its Artifact.** Call the Artifact tool with `action: "quickstart"` and `intent: "design"`. Publish a new artifact from the Design type it names, with `type_url`, the title `{Project} — {Section}` and `auto_open: "after_first_write"`, and attach the approved design system as the type's instructions describe. Keep the instructions the result returns.
3. **Produce.** Dispatch `project-scaffolder:designer` with: the direction, the design system, the folder `design/<section-slug>/`, and the type's instructions verbatim. Required frames: default, empty, loading, error, and the smallest and largest target viewports; plus any state the flow needs (success, permission denied, offline…).
4. **Critique.** Dispatch `project-scaffolder:design-critic` on the produced frames with the system and the accessibility target from the brief (default WCAG 2.2 AA). Block → back to the designer with the findings. At most three rounds, then bring the open findings to the user.
5. **Publish.** Fill the Artifact with the designer's files exactly as the type's instructions say (data files published to its `url`, or the type's own store), so the page shows the frames. Open it for the user.
6. **Approval.** Show the link, the critic's verdict and any P2/P3 items left, and ask for approval. Change requests go back to step 3. On approval, update the registry row: status `approved`, Artifact link, local folder, critic verdict, date. Log `## [date] decision | Design approved: <section>`.

Never batch several sections into one Artifact, and never approve a section on the user's behalf.

## Gate out

When every section in the first-release scope is `approved`:

1. Run a consistency pass: dispatch `project-scaffolder:design-critic` once across all approved sections for cross-section drift (navigation, type roles, spacing, button styles).
2. Show the registry and ask the user to close the design phase.
3. Log `## [date] phase | Design complete` and give the next command: `/4-build`.

## Changes after approval

A change to an approved section reopens it: status `changed`, the build tasks that implemented it are listed in the row's notes, and the section goes through steps 3 to 6 again. The old Artifact stays as the record; the new one is linked next to it. Record a decision when the change alters scope or behaviour.

## Red flags

| Thought | Reality |
|---|---|
| "The system can be extracted later from the screens" | Screens designed without a system drift, and the critique has nothing to measure against. System first. |
| "This section is simple, one frame is enough" | The empty and error states are where most interfaces fail. Draw them. |
| "The critic is too strict, the user will like it" | Fix or bring the finding to the user with its evidence. Do not hide it. |
| "I'll put all sections in one Artifact to save time" | One page per section is how build finds the right design and how changes stay traceable. |
| "A quick prototype in the app is faster" | The phase guard refuses application code here. Artboards are the prototype. |
