---
name: pr-description
description: Draft a pull request title and description for the current branch from its commits, diff and this session's context, then offer to create the PR in Azure DevOps. Use whenever the user asks for a PR title, PR summary or PR description, or asks to "write up" a branch for review.
---

## Current state

- Branch: !`git branch --show-current`
- Commits on this branch vs origin/dev: !`git log --oneline --first-parent origin/dev..HEAD`
- Files changed vs origin/dev: !`git diff --stat origin/dev...HEAD`
- Uncommitted: !`git status --short`

The base defaults to `origin/dev`. If the user names another base (e.g. `main`), rerun the
log and diff against that instead. If there are uncommitted changes, say so — the description
covers committed work only.

## Gather before writing

1. Read the full diff against the base, skipping test and fixture files. Read test file names
   and `describe`/`it` titles only, to summarise what's covered.
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

Markdown, matching the team's existing PRs. Use only the sections that apply, in this order:

- **Summary** — one or two sentences on what the user can now do (name the story/ACs covered),
  then bullets of user-visible behaviour. Bold lead-in per bullet.
- **How it works / key decisions** — the *why* behind non-obvious choices: data shape, API
  quirks, edge cases. Name the section after its subject (e.g. "How the order is saved", "API").
- **Validation**, **Accessibility**, or other topic sections when the change has real content
  there.
- **Not included** — deliberate omissions and gaps (e.g. backend not ready), each with the reason.
- **Worth checking** — unconfirmed risks or things reviewers/QA should verify.
- **Other changes in this PR** — unrelated commits, formatter churn, merges from the base.
- **Testing** — what the automated tests cover (by behaviour, not file list), the checks run
  (tests, type-check, lint), and manual QA only if confirmed.

Style: plain, specific and short. Reference endpoints, components and fields in backticks.
No marketing language, no restating the diff line by line, no emoji.

## Output

Show the title and the description as two separate fenced blocks (a plain one for the title, a
`markdown` one for the description) so each can be copied as-is.

Then ask the user whether they want to **copy it themselves** or have you **create the PR in
Azure DevOps**. Stop and wait for the answer. Don't push or create anything before then.

## Creating the PR (only when the user chooses it)

1. Check `az` is installed and signed in (`az account show`) with the `azure-devops` extension
   (`az extension show --name azure-devops`). If not, say what's missing and leave the draft to
   copy instead.
2. If the branch isn't on the remote or is behind it, say so and ask before pushing
   (`git push -u origin <branch>`).
3. Ask for the target branch if it isn't clear from the base (e.g. "dev"). Save the description
   to a temporary file and create the PR with the repo's own remote detected:
   `az repos pr create --detect true --source-branch <branch> --target-branch <target> --title "<title>" --description "$(cat <file>)"`
4. Report the PR's URL from the command output. Don't add reviewers, set auto-complete or link
   work items unless the user asks.
