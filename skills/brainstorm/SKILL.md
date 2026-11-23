---
name: brainstorm
description: Use when /1-brainstorm runs, or when the user describes a new product idea or a brief and wants to start a project with this plugin.
---

# Brainstorm — phase 1: questions only

The goal is a brief the user recognises as theirs, with nothing important left implicit. You get there only by asking. You do not propose solutions, platforms, stacks, screens or names in this phase.

<HARD-GATE>
In this phase you write exactly three things: `.scaffolder/phase`, files under `raw/`, and `docs/brief/BRIEF.md`. You do not scaffold, install, design, choose a platform or write code, and you do not invoke planning, design or implementation skills. Every interaction mode asks these questions: Autopilot and Autonomous start applying in phase 4.
</HARD-GATE>

## Start

1. Read `.scaffolder/phase` if it exists. If the project is already past brainstorm, say so and offer `/phase-status` instead. To revise the brief of a later-phase project, edit it directly and record a decision; do not reset the phase.
2. Create `.scaffolder/phase` containing `brainstorm`.
3. Save what the user gave you, verbatim, to `raw/brief-original.md` with the date on top. Pasted documents and links the user provides go to `raw/` too, one file each. `raw/` is never edited afterwards.
4. Read everything in `raw/` and any existing `CLAUDE.md` or docs. Never ask what they already answer.

## How to ask

- **One question per message.** Wait for the answer before the next one.
- Prefer multiple choice: two to four concrete options, your recommendation first with a one-line reason, and always room for the user's own answer. Use the AskUserQuestion tool when it is available.
- Ask only questions whose answer changes what gets built. If you can predict the answer from the brief, state it as an assumption at the end instead of asking.
- Go deeper where answers are vague. "For everyone" is not a target user; ask who would be most upset if the product disappeared.
- Reflect back every few answers in one sentence ("So far: …"), so drift surfaces early.
- If the user says "you decide", record the item as `[HYPOTHESIS]` with your default and move on; it will be confirmed when the brief is reviewed.

## What to cover

Work through these in order and skip what the sources already settle. Typical total: twelve to twenty questions.

1. **Problem.** Who has it, how they cope today, what that costs them.
2. **Target user.** The primary person; secondary users; who pays, if different.
3. **Outcome.** What the user can do after that they could not before; how success is measured in numbers.
4. **Scope of the first release.** The three to five things it must do; what it must explicitly not do.
5. **Content and data.** What the product stores or shows, where it comes from, what is personal or sensitive.
6. **Constraints.** Devices and contexts of use, offline needs, languages, accessibility requirements, regulations, deadline, budget, existing systems to integrate. These are inputs to the platform decision in phase 4; do not decide the platform now.
7. **Business.** How it makes or saves money; pricing intuition; distribution channel.
8. **References.** Products the user admires or wants to differ from, and why. Ask for links; store them in `raw/references.md`.
9. **Brand feel.** Three adjectives; what it must never feel like. This feeds the design phase.
10. **Interface.** Does the product have a user interface? If not, phase 3 will be skipped.
11. **Risks.** What would make the user abandon the project.
12. **Working agreements** — standing rules that bind every later task:
    - where design comes from (designed here in phase 3, or ported from an existing source, and whether a port is one to one);
    - generative models for images, video or voice, if the product produces media;
    - reference projects on disk to reuse code or patterns from, and what to take;
    - external services that will need keys (names only; the keys go into `secrets/` in phase 2);
    - any other rule: approvals, forbidden tools, cost limits.
13. **Interaction mode for phases 4 and 5.** Normal (asks before non-trivial decisions), Autopilot (asks only irreversible, cost or security decisions), Autonomous (asks only when blocked). Gates and cost decisions are always asked.

## Assumption check

Before writing the brief, show one table of every assumption you are carrying:

| Assumption | Source | Confidence | Tag |
|---|---|---|---|

Ask the user to confirm or correct the low-confidence rows. This is still a question, so it counts as part of the phase.

## The brief

Write `docs/brief/BRIEF.md` from `templates/BRIEF.md` (in this skill's folder). Fill every section from the answers; mark gaps `[HYPOTHESIS]` rather than leaving them blank. Keep it under about 150 lines.

Present it and ask for approval explicitly. On change requests, edit and ask again. When the user approves:

1. Set `status: approved` and `approved: <today>` in the brief's frontmatter.
2. Report in at most six lines: the one-sentence product, the target user, the scope count, whether there is an interface, the open hypotheses, and the next command: `/2-foundation`.

Do not create the wiki, `CLAUDE.md` or any other file now. That is phase 2.

## Red flags

| Thought | Reality |
|---|---|
| "The brief is clear, I can skip to the brief" | Write down your predicted answers as assumptions and ask the user to confirm them. That takes one message. |
| "I'll suggest a stack so they can react to it" | The platform is decided in phase 4 against the constraints gathered here. Ask about the constraints. |
| "Two questions at once saves time" | Two questions get one answer. Ask one. |
| "The user is in Autonomous mode" | Modes start in phase 4. Ask. |
| "I'll just create the folder structure while we talk" | The phase guard will refuse it, and it would anchor decisions not yet made. |
