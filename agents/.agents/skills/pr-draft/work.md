# Work PRs (Azure DevOps)

Read when `branch-state.sh` reports `context: work`. These rules add to
SKILL.md and win where the two differ.

## Base

PRs merge into `dev`, not the default branch. The script already uses
`origin/dev`; pass another base only if the user names one.

## Title

`type(ticket): short summary`. Take the ticket number from the branch name
(`feat/6905/...` → `feat(6905): ...`). If the branch has none, leave the scope
out.

## Description

Match the team's existing PRs, and keep SKILL.md's length limit.

- **Summary** opens by naming the story and the ACs covered, then bullets of
  user-visible behaviour, each with a bold lead-in.
- **Not included** also covers backend limitations (e.g. endpoint not ready).
- **Worth checking** goes after Not included. Name manual QA only if it was
  confirmed in this session.
