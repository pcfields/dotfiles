---
name: tdd
description: Drive new logic or a bug fix with Canon TDD — build a test list, take tests one at a time, make each pass for real, refactor only while green. Use before writing implementation code for non-trivial changes, when the project has a test suite.
---

# Canon TDD

Based on Kent Beck's Canon TDD (https://newsletter.kentbeck.com/p/canon-tdd).
Five steps, repeated until the list is empty.

## 1. Test list

Before writing any test, list the behavior variants expected: normal
cases, edges, errors. Keep the list visible — a comment, a scratch note,
or the plan file — and add to it as you learn more. Cross items off as
they pass.

## 2. Pick one item, write one test

Convert exactly one list item into a concrete, runnable test: setup,
invocation, assertion. Don't write the next test yet, and don't convert
the whole list to tests before making any of them pass — that creates
rework and delays feedback.

Picking order matters: prefer the case that teaches the most about the
design, or the simplest degenerate case, over the hardest one. This is a
skill that improves with practice, not a fixed formula.

Run the test and confirm it fails for the expected reason — missing
behavior, not a typo or setup error.

## 3. Make it pass — for real

"Make it run, then make it right." Faking the body — hardcoding a return
value to get to green fast — is fine as a first step; the next test's job
is to force a more general solution (triangulation). Never fake it by
deleting or weakening the assertion, or by copying the computed output
into the expected value — both destroy what the test is for.

All previously-passing tests must stay passing. If this test surfaces a
case you hadn't considered, add it to the list — don't chase it now.

## 4. Refactor (optional)

Only while everything is green. Clean up duplication, names, structure.
Keep this separate from making the test pass — don't mix the two modes.

## 5. Repeat

Go back to step 2 until the list is empty.

## Bug fixes

Always start with a failing regression test that reproduces the reported
symptom. No fix lands without one, except in the rare case where the bug
is untestable at any reasonable seam — justify that explicitly if so.

## Anti-patterns — reject these

- **Tests written after the implementation.** They never watched red, so
  they prove nothing about whether they'd catch the bug they claim to
  test.
- **Tautological assertions** that recompute the expected value the same
  way the code does — they pass by construction and can't disagree.
- **Mocking internals** instead of testing through the public seam — the
  test breaks on refactors even when behavior hasn't changed.
- **Horizontal slicing** — writing every test on the list before making
  any of them pass. Work one item at a time.

## Exceptions

Documentation, pure configuration with no branching logic, generated
code, throwaway prototypes explicitly marked as such, and mechanical
renames verified by build/typecheck alone. State the exception explicitly
rather than silently skipping the loop.
