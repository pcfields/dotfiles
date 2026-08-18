---
description: Two-axis review (spec compliance + engineering quality) of the diff since a fixed point, using the production-review skill. Read-only.
agent: plan
model: github-copilot/claude-sonnet-5
subtask: true
---

Review the diff since $ARGUMENTS (a commit, branch, or tag — if not given,
use the merge-base with `main`).

Commits in range:

!`git log $ARGUMENTS..HEAD --oneline`

Diff:

!`git diff $ARGUMENTS...HEAD`

Use the `production-review` skill: review both **Spec Compliance** and
**Engineering Quality** as separate axes, tag each finding
critical/important/minor, and report them under separate headings. If a
plan file exists for this work under `docs/plans/`, read it and use it as
the spec source. This review is read-only and does not replace the user's
own read of the diff.
