---
name: pr-draft
description: Draft a pull request title and description for the current branch from its commits, diff and this session's context. Use whenever the user asks for a PR title, PR summary or PR description, or asks to "write up" a branch for review.
---

## Current state

Start by finding the base: `git symbolic-ref --short refs/remotes/origin/HEAD` (e.g.
`origin/main`). If that fails, try `origin/main`, then `origin/master`. If the user names another
base (e.g. `dev`), use that instead. Then run, with `<base>` substituted:

- Branch: `git branch --show-current`
- Commits on this branch vs the base: `git log --oneline --first-parent <base>..HEAD`
- Files changed vs the base: `git diff --stat <base>...HEAD`
- Uncommitted: `git status --short`

If there are uncommitted changes, say so — the description covers committed work only.

## Gather before writing

1. Read the full diff against the base, skipping test and fixture files.
2. Take the ticket number from the branch name (`feat/6905/...` → `6905`). If there isn't one,
   leave the scope out.
3. Pull decisions, trade-offs, known gaps, backend limitations and QA status from this session.
   Never invent them: if manual QA or a check wasn't confirmed in the conversation, don't claim it.
4. Note anything reviewers would otherwise trip over: unrelated or mechanical commits (formatter
   churn, import sorting), merges from the base, renamed files.

## Title

`type(ticket): short summary` — conventional-commit type of the main change, ticket as scope,
imperative or noun phrase, ≤ 72 characters, no trailing period.

## Description

Short and sweet: people struggle to read long PR descriptions, so aim for well under 15 lines.
Markdown, matching the team's existing PRs.

The default is a **Summary** and nothing else: one sentence on what the user can now do (name the
story/ACs covered), then a few bullets of user-visible behaviour, each with a bold lead-in.

Add one of these short sections only when a reviewer would otherwise miss it:

- **Key decisions** — the *why* behind a non-obvious choice (API quirk, edge case), in a bullet
  or two, not an essay.
- **Not included** — deliberate omissions and gaps (e.g. backend not ready), each with the reason.
- **Worth checking** — unconfirmed risks, or things that weren't tested, for reviewers/QA.
- **Other changes in this PR** — unrelated commits, formatter churn, merges from the base.

No Testing section listing test cases or checks that passed: the tests are in the diff and CI
shows the checks. Mention testing only when it tells a reviewer something they can't see, such
as how to try it by hand.

Style: plain and specific. Reference endpoints, components and fields in backticks.
No marketing language, no restating the diff line by line, no emoji.

## Output

Show the title and the description as two separate fenced blocks (a plain one for the title, a
`markdown` one for the description) so each can be copied as-is.

Don't push or create the PR; the user copies the draft.
