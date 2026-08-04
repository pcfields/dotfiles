---
name: explain-code
description: Use when asked to explain unfamiliar code to a human - what it does, why it's structured that way, and any non-obvious gotchas. Not for explaining code you just wrote.
---

## Output format

- **What it does** - 1-3 sentences, plumbing-level, not marketing copy.
- **Key control flow** - the path a request/call actually takes, naming the
  functions/files involved (`file:line` where useful) - not a line-by-line
  narration.
- **Why it's structured this way** - only if non-obvious (a constraint, a
  historical workaround, a performance reason) - skip if the structure is
  self-explanatory.
- **Gotchas** - anything that would surprise a reader: hidden state, order
  dependencies, silent failure modes, non-obvious invariants. Omit this
  section entirely if there are none - don't invent gotchas to fill it.

Keep it tight. Prefer pointing at the actual code over restating it in
prose.
