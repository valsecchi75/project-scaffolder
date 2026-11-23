# When Fable is missing

Read this when a Fable agent fails on a usage or rate limit, or when an agent report opens with `⚠ This agent switched to <model>`.

- A fallback chain (`fallbackModel` in the user's settings, or `--fallback-model`) switches only when a model is overloaded or unavailable, never on a usage or rate limit, and a plugin cannot set it: recommend it (`/setup-check`), never assume it. A report that opens with `⚠ This agent switched to <model>` ran on that fallback.
- A Fable agent that fails on a usage limit: ask the user (AskUserQuestion) to wait for the reset and retry, or to re-dispatch the same agent now with the Agent tool's `model: "opus"` (it overrides the agent's own model; the only `model` override this flow allows). Add a `T-NNN` line to `wiki/todo.md` (`debug`, P1) to repeat that step on Fable.
- In every case say it plainly, name what ran on which model, and log a `fallback` step line (pipeline-logger format).
- Verification, bug hunting and release debug done on another model are repeated on Fable when it is back; never present them as equivalent.
