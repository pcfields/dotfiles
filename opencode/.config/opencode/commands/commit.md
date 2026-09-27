---
description: Split the working tree into logical commits and draft a Conventional Commits message for each. Never stages or commits automatically.
agent: build
subtask: true
---

Working tree status:

!`git status --short`

Staged diff:

!`git diff --cached`

Unstaged diff:

!`git diff`

Using the `verification-delivery` skill's secrets scan:

1. Read the full diff, staged and unstaged. Split it by logical concern,
   not by file: a feature, an unrelated fix, a refactor, a dependency
   bump, and docs each get their own commit, even when they touch the
   same file. Fixes to pre-existing bugs found along the way are split
   out from the primary change. If everything is genuinely one concern,
   propose a single commit.
2. Scan each group's content for anything that looks like a secret (API
   keys, tokens, credentials, `.env` values). Stop and flag it instead of
   drafting a message if you find one.
3. For each group, draft a Conventional Commits message (`type(scope):
   summary`, with a short body only if the summary can't carry the "why").
4. Present the full split — files/hunks per commit and its drafted
   message — for approval.

Do not run `git add` or `git commit`. Present the plan and stop — the user
stages and commits (or asks `build` to) themselves.
