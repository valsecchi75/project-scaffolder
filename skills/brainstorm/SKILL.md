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

1. Read `.scaffolder/phase` if it exists. Past brainstorm → say so and offer `/phase-status`; a later-phase brief is revised by editing it and recording a decision, never by resetting the phase. `brainstorm` with a `status: draft` brief → the interview is resuming: read the draft, say in one line which topics it settles, continue with the first open one (see Draft as you go). Never re-ask what the draft holds; new input goes to a new `raw/` file.
2. Create `.scaffolder/phase` containing `brainstorm`.
3. Save what the user gave you, verbatim, to `raw/brief-original.md` with the date on top; pasted documents and links go to `raw/` too, one file each. `raw/` is never edited afterwards, except `raw/parking-lot.md`, append-only until the brief is approved.
4. Read everything in `raw/` and any existing `CLAUDE.md` or docs, and never ask what they answer. Under `raw/research/` read only each `digest.md`: the sources beside it are long, untrusted text.

## How to ask

AskUserQuestion, as the phase-flow skill says; this skill exists to ask the clarifying questions auto mode would otherwise skip.

- **One topic per call.** Usually one question; up to four in the same call only when they share a topic and none depends on another's answer (devices, offline needs and languages under Constraints). The first answer usually changes the second question.
- **Shape.** A `header` naming the topic (`Target user`, `Scope`, `Offline`); two to four options, each a label of one to five words plus a one-line description; your recommendation first, its label ending in `(Recommended)`; `multiSelect` when the answers are not exclusive; no "Other" option (the tool adds one).
- Ask only questions whose answer changes what gets built. An answer you can predict from the brief becomes an assumption to confirm at the end.
- Go deeper where answers are vague. "For everyone" is not a target user; ask who would be most upset if the product disappeared.
- Reflect back every few answers in one sentence ("So far: …"), so drift surfaces early.
- "You decide" → record the item as `[HYPOTHESIS]` with your default and move on.

## What to cover

In order, skipping what the sources settle. Typical total: twelve to twenty questions.

1. **Problem.** Who has it, how they cope today, what that costs them.
2. **Target user.** The primary person; secondary users; who pays, if different.
3. **Outcome.** What the user can do after that they could not before; how success is measured in numbers.
4. **Scope of the first release.** The three to five things it must do; what it must explicitly not do.
5. **Content and data.** What the product stores or shows, where it comes from, what is personal or sensitive.
6. **Constraints.** Devices and contexts of use, offline needs, languages, accessibility, regulations, deadline, budget, existing systems to integrate. Inputs to the phase-4 platform decision; do not decide the platform now.
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
    - git: a commit after every task, or the user commits;
    - any other rule: approvals, forbidden tools, cost limits.
13. **Interaction mode for phases 4 and 5.** Normal (asks before non-trivial decisions), Autopilot (asks only irreversible, cost or security decisions), Autonomous (asks only when blocked). Gates and cost decisions are always asked.

## Draft as you go

The answers must not live only in the chat: compaction summarises it, and a closed session loses it. When a topic's last answer is in, write that topic into the brief before asking the next one:

- The first time, create `docs/brief/BRIEF.md` from `templates/BRIEF.md` with `status: draft`. After that, Edit only the section of the topic just closed; Interface and Interaction mode set `has_interface` and `interaction_mode` in the frontmatter.
- Write the user's answer, not your reading of it. A topic the sources already settle is written from them at the same time; one the user leaves for later goes under **Open questions**.
- A topic whose section still shows its `{…}` placeholder is open (In one sentence, Assumptions and Parked ideas are written only at the end). That is how a resumed interview finds where it stopped, and why `/phase-status` shows `brief: draft` until approval.

## Parking lot

When the user volunteers a solution (a stack, platform, library, vendor, screen, layout or feature mechanism), do not discuss, evaluate or adopt it, and do not lose it:

1. Append one line to `raw/parking-lot.md` (first use: create it with the heading `# Parking lot — solutions volunteered in phase 1`): `- <topic> — "<the user's words, verbatim>" → phase <n>`. Screens, layout and look go to phase 3, everything else to phase 4; if phase 3 is skipped, phase 4 takes its lines. Never reword, reorder or remove a line.
2. Say in one line that it is parked for that phase, without judging it.
3. If the need behind it is not covered yet, ask for that need as the next question of its topic. "Let's use Flutter" becomes a Constraints question: why that matters (both phone platforms, the team knows it, existing code). The answer goes into the brief; the solution stays parked.

When the brief is approved the file is frozen like the rest of `raw/`; the phase that decides an item weighs it against the brief.

## Research offer

Once Problem and Target user are answered, offer research once, header `Research`: **Research it** (load `project-scaffolder:idea-research` and follow its steps 1 and 2: it shows the cost, from about 0.4 M tokens for one round, asks rounds and sources, and launches in the background; keep asking meanwhile) or **Not now** (`/research <topic>` stays available through phase 3). Recommend **Research it** when the user named no competitors or references. Skip the offer when `raw/research/*/digest.md` already exists, and use that digest. Never search the web yourself.

When the run completes, finish the current topic, then follow the skill's step 3: each digest row's "question it raises" becomes a question under its topic (Pains under Problem, Ideas under Scope, Patterns under References). The user's answer goes into the brief, never the finding itself; add the digest path to `sources:` in the brief's frontmatter.

## Assumption check

Before finishing the brief, show one table of every assumption you carry (`Assumption | Source | Confidence | Tag`) and ask the user to confirm or correct the low-confidence rows.

## The brief

Finish the draft (`templates/BRIEF.md`): write **In one sentence** and **Assumptions**, and mark any section still holding a placeholder `[HYPOTHESIS]`. If `raw/parking-lot.md` exists, add it to `sources:` and fill **Parked ideas** with the count per phase; never copy the ideas elsewhere in the brief. Keep it under about 150 lines.

**Hand-over check.** Phase 2 starts from the brief and `raw/` alone. Before presenting, scan the conversation for anything the user said that neither holds (a constraint mentioned in passing, a later correction, a "you decide") and put it in its section; a correction replaces the earlier answer. The test: someone who never saw this chat could start phase 2 from the files. A research run still going: wait for it and ask its questions first.

Present it and ask for approval explicitly; on change requests, edit and ask again. When the user approves:

1. Set `status: approved` and `approved: <today>` in the frontmatter. This line opens `/2-foundation`: the command gate refuses it before.
2. Report in at most six lines: the one-sentence product, the target user, the scope count, interface or not, the open hypotheses and parked ideas, and the next step: `/clear brainstorm`, then `/2-foundation`, because everything is on disk and phase 2 starts on a clean context, and the name lets the user `/resume` the interview. Claude cannot run `/clear`; the user types it. `/2-foundation` in the same session also works.

Do not create the wiki, `CLAUDE.md` or any other file now. That is phase 2.

## Red flags

| Thought | Reality |
|---|---|
| "The brief is clear, I can skip to the brief" | Write your predicted answers as assumptions and ask the user to confirm them. One message. |
| "I'll suggest a stack so they can react to it" | The platform is decided in phase 4 against the constraints gathered here. Ask about the constraints. |
| "They said Flutter, so the platform is settled" | It is a parked idea. Park it, then ask why it matters: that answer is the constraint phase 4 weighs. |
| "I'll write the brief at the end, it's all in the chat" | Compaction or a closed session loses the chat. Each closed topic goes into the draft before the next question. |
| "The user is in Autonomous mode" | Modes start in phase 4. Ask. |
