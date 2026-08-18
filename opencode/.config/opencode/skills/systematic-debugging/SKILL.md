---
name: systematic-debugging
description: Use when investigating a bug or unexpected behavior, before making any fix. Enforces reproduce, localize, hypothesize, and verify over guessing.
---

# Systematic Debugging

Process over guessing. Don't patch symptoms — find the actual cause.

## 1. Reproduce

Run the failing test, script, or command yourself. Capture the exact
failure: error message, stack trace, or observed-vs-expected output. If
you can't reproduce it, say so and ask for more information rather than
guessing at a fix.

## 2. Localize

Narrow the failure to the smallest unit that reproduces it — a function, a
module, a specific input. Use logging, a debugger, or targeted print
statements over speculation. Read the actual code path involved before
forming a theory.

## 3. Hypothesize — one at a time

Form a single, specific hypothesis about the cause. State it explicitly:
"I believe X causes Y because Z." Test that one hypothesis before moving
to the next. Don't change multiple things at once and hope one of them
fixes it — you won't know which change mattered, and you may have masked
a different bug.

## 4. Fix minimally

Once the cause is confirmed, make the smallest change that addresses it.
Don't refactor surrounding code in the same pass — that's a separate,
reviewed step.

## 5. Regression test

Write a failing test that reproduces the original symptom, confirm it
fails against the old code (or fails without your fix), then confirm it
passes with the fix. This is the `tdd` skill's bug-fix rule — debugging
always ends by feeding into it, never by skipping it.

## 6. Verify no new breakage

Run the full relevant suite, not just the new test, before claiming the
bug is fixed.

## Anti-patterns

- Changing code without a reproduction — you can't confirm you fixed
  anything you never observed failing.
- Multiple simultaneous changes ("shotgun debugging") — you lose the
  ability to attribute the fix.
- Fixing the symptom at the call site instead of the cause in the
  function — check whether the same class of bug exists elsewhere before
  declaring it fixed.
- Declaring victory without a regression test — the same bug can resurface
  silently on the next change.
