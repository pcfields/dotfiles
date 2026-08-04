---
name: bug-debugging
description: Use when investigating a reported bug - reproduce, form a hypothesis, isolate the cause, apply the smallest correct fix, and verify. Keeps debugging from turning into unfocused speculative changes.
---

## Discipline

1. **Reproduce first.** Don't propose a fix before you can trigger the bug
   (a failing test, a repro script, or manual steps). If you can't
   reproduce it, say so and ask for more detail rather than guessing.
2. **Form one hypothesis at a time.** State it explicitly before touching
   code: "I think X causes Y because Z." Don't shotgun multiple speculative
   changes at once.
3. **Isolate before fixing.** Narrow down to the smallest piece of code that
   exhibits the bug (add a print/log/test, bisect, or read the actual
   execution path) before editing.
4. **Smallest correct fix.** Fix the root cause, not the symptom. Don't
   refactor unrelated code while you're in there.
5. **Verify.** Re-run the repro and the existing test suite for that area
   to confirm the fix works and nothing else broke. Add a regression test
   for the specific bug if the codebase has tests.

## Rules

- If the hypothesis is wrong, say so explicitly and form a new one - don't
  quietly pivot without noting the previous guess failed.
- If root-causing requires info only the user has (intended behavior,
  which environment it happens in), ask instead of assuming.
