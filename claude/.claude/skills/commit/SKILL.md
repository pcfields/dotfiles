---
name: commit
description: Plan and create conventional commits from the working tree, split by logical concern. Use whenever the user asks to commit or to draft a commit message.
---

## Current state

- Status: !`git status --short`
- Staged stat: !`git diff --cached --stat`
- Unstaged stat: !`git diff --stat`
- Recent commits (match their style): !`git log --oneline -10`

## Split by concern

One logical change per commit. Split by type of work, not by file: a feature,
an unrelated bug fix, a refactor, a dependency bump, and docs each get their
own commit, even when they touch the same file. Fixes to pre-existing bugs found
along the way are committed separately from the primary change.

Read the full diff (`git diff`, `git diff --cached`) before proposing anything.

## Procedure

1. Propose the split: for each commit, list the files or hunks and the drafted
   message. If everything is one concern, say so and propose one commit.
2. **Stop and wait for the user to confirm or adjust the plan.** Do not stage
   or commit before that.
3. For each commit in order:
   - Whole files: `git add <paths>`.
   - Part of a file: write only the wanted hunks to a patch file in the
     scratchpad and run `git apply --cached <patch>`. Never edit the working
     tree back to an intermediate state to stage it; that can lose work.
   - Verify with `git diff --cached` that exactly the intended change is
     staged, then `git commit`.
4. Finish with `git log --oneline -<n>` and `git status --short` so the user
   sees the result and anything left uncommitted.

## Message format

- `type(scope): summary`. Types: `feat`, `fix`, `refactor`, `docs`, `test`,
  `chore`, `perf`, `style`, `build`, `ci`. Use a scope when recent commits do.
- Summary of 72 characters or fewer, imperative mood, no trailing period.
- Add a body only when the summary can't carry the "why". Explain the
  motivation, don't restate the diff.
- No `Co-Authored-By` or other attribution trailers.

Never push, amend, or rewrite history as part of this skill unless the user
asks.
