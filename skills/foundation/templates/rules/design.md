---
paths:
  - "design/**"
---

# Design files

- `design/system/` holds the design system; `design/<section-slug>/` holds one section's artboards. `wiki/design/registry.md` records each section's status and link.
- An approved section changes only through `/3-design --section <name>`, which marks it `in-progress` in the registry. Build ports these files one to one and never edits them to fit the code.
