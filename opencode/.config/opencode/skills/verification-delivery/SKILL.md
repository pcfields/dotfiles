---
name: verification-delivery
description: Use before claiming any work is complete, fixed, or passing, and before drafting a commit message. Requires fresh verification evidence and a secrets check.
---

# Verification & Delivery

Evidence before claims, always. Violating the letter of this rule is
violating the spirit of it.

## The gate

Before any completion claim:

1. Identify the command that proves the claim (test, lint, typecheck,
   build).
2. Run it fresh, in full — not a partial check, not a memory of an earlier
   run.
3. Read the full output: exit code, failure count, warnings.
4. Only then state the claim, with the evidence attached.

Never say "should pass," "looks correct," or "probably works." If you
haven't run the command in this task, you cannot claim it passes.

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | Fresh test run, 0 failures | Earlier run, "should pass" |
| Lint clean | Fresh linter output, 0 errors | Partial check |
| Build succeeds | Fresh build, exit 0 | Lint passing |
| Bug fixed | Regression test: red before fix, green after | Code changed, assumed fixed |

## Before drafting a commit

- **Staged-file review** — confirm what's actually staged matches what was
  intended. Flag anything staged that looks unrelated to the task.
- **Secrets scan** — check staged content for API keys, tokens, private
  keys, `.env` values, credentials. If anything looks like a secret, stop
  and flag it before drafting a message.
- **Test-evidence summary** — one line stating what was run and the
  result, sourced from the gate above, not restated from memory.

This skill drafts and checks; it never runs `git commit` itself. The user
reviews and commits.

## Red flags — stop

- Wording like "should", "probably", "seems to".
- Expressing satisfaction before verification.
- About to suggest a commit without having run verification in this task.
- Trusting a subagent's success report without checking the diff yourself.
