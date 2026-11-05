---
name: pr-draft
description: Draft a pull request title and description for the current branch from its commits, diff and this session's context. Use whenever the user asks for a PR title, PR summary or PR description, or asks to "write up" a branch for review.
---

## Current state

From the repo, run `bash ~/.agents/skills/pr-draft/scripts/branch-state.sh`.
If the user names a base (e.g. `dev`), pass it as the argument:
`... branch-state.sh origin/dev`. It prints the context (work or personal),
the base, the branch, its commits, the files changed and anything uncommitted.

If it reports `context: work`, read [work.md](work.md) now; its rules add to
and override this file.

If there are uncommitted changes, say so: the description covers committed
work only.

## Gather before writing

1. Read the full diff against the base (`git diff <base>...HEAD`), skipping
   test and fixture files.
2. Pull decisions, trade-offs, known gaps and QA status from this session.
   Never invent them: if manual QA or a check wasn't confirmed in the
   conversation, don't claim it.
3. Note anything reviewers would otherwise trip over: unrelated or mechanical
   commits (formatter churn, import sorting), merges from the base, renamed
   files.

## Title

`type(scope): short summary`. Conventional-commit type of the main change,
scope only if the repo's commits use one, imperative or noun phrase,
≤ 72 characters, no trailing period.

## Description

Short and sweet: people struggle to read long PR descriptions, so aim for
well under 15 lines. Markdown.

The default is a **Summary** and nothing else: one sentence on what the change
does and why, then a few bullets of user-visible behaviour, each with a bold
lead-in.

Add one of these short sections only when a reviewer would otherwise miss it:

- **Key decisions**: the *why* behind a non-obvious choice (API quirk, edge
  case), in a bullet or two, not an essay.
- **Not included**: deliberate omissions and gaps, each with the reason.
- **Worth checking**: unconfirmed risks, or things that weren't tested, for
  reviewers.
- **Other changes in this PR**: unrelated commits, formatter churn, merges
  from the base.

No Testing section listing test cases or checks that passed: the tests are in
the diff and CI shows the checks. Mention testing only when it tells a reviewer
something they can't see, such as how to try it by hand.

Style: plain and specific. Reference endpoints, components and fields in
backticks. No marketing language, no restating the diff line by line, no emoji.

## Output

Show the title and the description as two separate fenced blocks (a plain one
for the title, a `markdown` one for the description) so each can be copied
as-is.

Don't push or create the PR; the user copies the draft.
