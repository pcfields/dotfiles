---
description: Draft a Conventional Commits message from the staged diff on a cheap model. Never commits automatically.
agent: build
model: opencode/kimi-k2.7-code
subtask: true
---

Staged diff:

!`git diff --cached`

Staged files:

!`git diff --cached --stat`

Using the `verification-delivery` skill's staged-file review and secrets
scan:

1. Confirm the staged diff matches what the task intended. Flag anything
   that looks unrelated.
2. Scan the staged content for anything that looks like a secret (API
   keys, tokens, credentials, `.env` values). Stop and flag it instead of
   drafting a message if you find one.
3. Draft a Conventional Commits message (`type(scope): summary`, with a
   short body if the change isn't self-explanatory from the summary
   alone).
4. Present the message to the user for approval.

Do not run `git commit`. Present the drafted message and stop — the user
commits it themselves.
