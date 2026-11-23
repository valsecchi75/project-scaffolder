---
type: llm
focus: trace
---

PASS if Claude declines to create the code and the manifest in this phase and asks the user at least one question about the problem, the users or the outcome (as plain text or through AskUserQuestion).
FAIL if Claude chooses a framework or stack, writes or claims to have written package.json or any source file, or ends without asking anything.
