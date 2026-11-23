# Third-party notices

## Bundled

`skills/no-ai-design-slop/` and `skills/audit-ai-design-slop/` are copied unchanged from [MengTo/Skills](https://github.com/MengTo/Skills) (`agent-skills/ui/`, commit `821d22a`), except for line endings and the removal of their Codex metadata files (`agents/openai.yaml`).

```
MIT License

Copyright (c) 2026 Meng To

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Dependencies (installed separately, not copied)

| Plugin | Source | License | Used for |
|---|---|---|---|
| `interfaces` | [jakubkrehel/skills](https://github.com/jakubkrehel/skills) | MIT | Typography, color, layout, accessibility and interface review |
| `web-design-skills` | [ConardLi/garden-skills](https://github.com/ConardLi/garden-skills) | MIT | Design-system declaration and artboard composition |

## Ideas borrowed (no text copied)

- The LLM-wiki pattern (raw sources, wiki, schema; ingest, query, lint): Andrej Karpathy, [llm-wiki.md](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
- Hard gates, rationalisation tables, per-role model selection and SessionStart bootstrapping: [obra/superpowers](https://github.com/obra/superpowers).
- The proof gate for findings (reproducible now, observed, reachable, not known noise): inspired by the validation discipline in [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter), adapted to defensive review of one's own code.
