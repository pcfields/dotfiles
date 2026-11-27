---
name: pr-review
description: Review a pull request and draft friendly, labelled review comments (Needs a change, Worth a look, Small thoughts) that don't overwhelm the author. Light by default, with more detail or example code on request, and nothing posted until the user says which comments to post. Use whenever the user asks to review a pull request or merge request, or pastes a link to one from any host (GitHub, GitLab, Azure DevOps and so on).
---

# PR review

A review exists to leave the code healthier than it was, to catch problems
while they're cheap, and to share understanding. It doesn't have to make the
change perfect. The author should come away encouraged and clear on what, if
anything, must change before merging.

## 1. Understand the change

Read the PR: title, description, linked work item, the diff, and comments
other reviewers already made. Don't repeat a point someone else raised.
Understand what the change is for before judging how it does it.

If the repo is cloned locally (the current directory, or a path the user
gives), run this from it and read the file it names, if any; its rules add
to and override this file:

```bash
bash -c 'source ~/.agents/lib/local-context.sh && print_overlay pr-review'
```

## 2. Check code health (when the repo is cloned locally)

Without a local clone, skip this step and say so in the overview.

1. Fetch both branches and check out the PR's source branch in a temporary
   worktree, so the user's working copy is untouched:
   `git fetch origin <source> <target>`, then
   `git worktree add --detach "${TMPDIR:-/tmp}/pr-review-<number>" origin/<source>`.
2. In the worktree, run `code-health safeguard --base origin/<target> --json`.
   Its exit code is 1 when there are findings; that's expected.
3. Findings that are **new or worse** in this PR are candidates for
   "Worth a look": name the smell and the refactoring that fixes it.
   Findings that were already there are not the author's doing: leave them
   out of the review, unless the PR touches that code and the problem is a
   bug.
4. If `code-health --help` lists `change-report`, run
   `code-health change-report --base origin/<target>` in the worktree and
   give the user the image's path to look at. Never attach it to the PR
   yourself.
5. Keep the worktree until the user is done with this review, then remove
   it with `git worktree remove`.

## 3. Sort what you found

Each point gets exactly one of these labels, worded exactly like this every
time, so the team learns what they mean:

| Label | For | Raised |
|---|---|---|
| **Needs a change** | Bugs, data loss, security, broken behavior: must be sorted before merging | All of them |
| **Worth a look** | Design and code-health suggestions with real value, not blocking | Up to 3, the most valuable |
| **Small thoughts** | Tiny, optional things | Batched into one comment, up to 5 bullets |

Plus one positive comment: specific and genuine, about something done well
in this PR.

Everything else goes in a **Not raised** list for the user only: more
"worth a look" points, legacy problems, ideas for a later PR.

Don't raise: formatting a formatter or linter handles, personal style
preferences, points another reviewer already made, or vague "consider"
suggestions without a concrete reason. If the same issue repeats, raise it
once and list the other places.

## 4. Write the comments

Tone: friendly, suggestive and encouraging. Say "we", ask questions rather
than give orders, and name a refactoring in plain words too. Never write
"nit". Don't restate what the code does.

**Needs a change:** what's wrong and why, then a suggested fix.

> **Needs a change:** if `items` is empty, `items[0]` throws here and the
> whole order fails. Could we return early when there's nothing to process?

**Worth a look:** a suggestion, usually a question, and one sentence on why
it helps.

> **Worth a look:** could we pull the discount rules into their own
> function? `CalculateTotal` would read more simply, and the rules could get
> their own tests.

**Small thoughts:** one general comment for the whole PR, not attached to a
line.

> **Small thoughts (optional):** take them or leave them.
> - `OrderService.cs:42`: `tmp` could be `discountedTotal`.
> - `api.ts:17`: this `console.log` looks left over.

**Positive:** no label, on the line it's about.

> Nice, the guard clauses here make this much easier to follow.

**Opening comment:** a general comment with thanks and a key to the labels.
Include the key unless the user or an overlay says the team knows them:

> Thanks for this! A quick key to my comments: **Needs a change** = please
> sort before merging. **Worth a look** = a suggestion, fine to resolve
> without changing anything. **Small thoughts** = entirely optional.

**Detail level.** Light by default: one or two sentences per comment. When
the user asks for detail on a comment (or on all of them), add why it
matters in a sentence or two and a short example of the fix: at most about
10 lines, in the codebase's own language and style, as a suggestion rather
than the only answer.

## 5. Show the draft

Show, in this order:

1. **What this PR does:** two or three sentences.
2. **Code health:** one line, for example "2 files better, 1 worse:
   `PaymentGateway.cs` gained Complex Method", or why it wasn't checked.
3. **Draft review:** every comment numbered in posting order, starting with
   the opening comment. For each: its number, its file and line (or
   "general"), then the exact text that would be posted, as a quote.
4. **Not raised:** short bullets, for the user only.
5. One line on what the user can say next:
   `expand 2` · `simpler 3` · `all detailed` · `drop 4` · `raise <point>` ·
   `post 1, 2, 5` · `post all`

The user replies in plain words; those are examples, not syntax. After a
change, show only the comments that changed, in full, then the same line of
options.

## 6. Post only what the user picks

Nothing is posted until the user says which comments to post. Then post
exactly those: line comments on their file and line, and the opening and
small-thoughts comments as general PR comments. Afterwards, list what was
posted and where.

If the user says they'll post them, give each comment as a separate block
they can copy.

Never approve, reject or vote on the PR, resolve threads, or push to the
author's branch.

The review names a client's files and code: it belongs in that client's own
PR. Don't write it into files anywhere else.
