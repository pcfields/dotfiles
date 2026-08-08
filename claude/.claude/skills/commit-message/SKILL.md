---
name: commit-message
description: Draft a conventional commit message from the currently staged diff. Invoke explicitly when the user wants a commit message drafted - not for actually running git commit.
disable-model-invocation: true
context: fork
model: haiku
---

## Diff

- Staged diff: !`git diff --cached`
- Staged file stat: !`git diff --cached --stat`

## Instructions

Draft a conventional commit message (`feat:`, `fix:`, `refactor:`, `docs:`,
`test:`, `chore:`, `perf:`, `style:`, `build:`, `ci:`) for the staged diff
above.

- One line summary (≤72 chars), imperative mood, no trailing period.
- Body only if the summary line can't carry the "why" - explain motivation,
  not a restatement of the diff.
- If the diff is empty, say so instead of inventing a message.
- If the staged diff clearly mixes unrelated concerns (e.g. a feature plus an
  unrelated bug fix or dependency bump), say so explicitly and recommend
  splitting into separate commits (unstage the unrelated hunks with
  `git restore --staged <path>` or `git add -p`) instead of drafting one
  message that papers over multiple logical changes.

Return only the drafted message (or the split recommendation) - do not run
`git commit`.
