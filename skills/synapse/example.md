# Synapse — one full run, worked example

Task: "Show the renewal date on the home-screen widget". The builder found that date formatting without an explicit locale shows the wrong format on some devices. `/log-error` recorded it as `KE-007` and `ERR-012`.

```
Packet: primary skill app-widget · error KE-007 / ERR-012 · pattern "format dates with an explicit locale"

1. BACKUP   .claude/skills/app-widget/.history/SKILL-2026-04-16-1.md

2. PRIMARY  app-widget
            ## Anti-patterns   | Format a date with the device default | Pass the locale explicitly | ERR-012 |
            ## Patterns        the safe date-format helper, marked ✅
            metadata           tasks_completed 0 → 1 · maturity seed → growing · last_synapse_update 2026-04-16

3. MAP      app-widget ↔ app-domain       (shared concept: renewal dates)  → concerned
            app-widget ↔ app-brand-voice  (shared concept: microcopy)      → not concerned, skip

4. HOP      app-domain, new row in ## Common mistakes:
            | [SYNAPSE from app-widget, 2026-04-16] Dates formatted without an explicit locale show the wrong format on some devices | See ERR-012 |
            pending notes 4 → 5  → report "app-domain due for refactor"

5. GUARD    ERR-012 already exists (written by /log-error) → no new entry, cite it only

6. MAP      Recent propagations: | 2026-04-16 | app-widget | explicit locale for dates | app-domain |

7. REFACTOR user says yes → backup app-domain → fold the 5 notes into Rules / Anti-patterns
            → validate: entries kept ✅ · frontmatter ✅ · length ≥ 80% ✅ → pending notes 0

8. LOG      - synapse | - | - | OK | app-widget seed->growing; propagated app-domain; guardrail ERR-012
```
