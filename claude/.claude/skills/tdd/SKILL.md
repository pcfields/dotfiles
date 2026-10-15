---
name: tdd
description: Drive new logic or a bug fix with Canon TDD — build a test list, take tests one at a time, make each pass for real, refactor only while green. Use before writing implementation code for non-trivial changes, when the project has a test suite.
---

# Canon TDD

Based on Kent Beck's Canon TDD (https://newsletter.kentbeck.com/p/canon-tdd).
Five steps, repeated until the list is empty.

## Seams — where tests go

A seam is the public boundary you test at: the interface where you observe
behavior without reaching inside. Tests live at seams, never against
internals.

Agree the seam with the user (or take it from the plan file) before writing
any test. You can't test everything; agreeing seams up front puts testing
effort on the behaviors that matter instead of every internal detail.

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

## 5. Verify and repeat

Run the targeted test, then the relevant suite. Go back to step 2 until the
list is empty. Before calling the work done, also run the typecheck, lint
and build. Never claim "should pass": run it, read the output, quote it.

## Test doubles

Mocks are a design smell, not a first resort. Before reaching for one, ask
whether a calculation is tangled inside an action. If it is, extract it and
test it with plain values; no double needed.

Preference order:

1. **Real code.** Calculations never need doubles.
2. **In-memory fake or Nullable** for infrastructure you own: a working,
   simplified implementation, such as an in-memory repository or a wrapper
   with a `createNull()` mode (James Shore, "Testing Without Mocks"). Assert
   on the resulting state or output.
3. **Stub or mock** only at a boundary you don't own (network, clock,
   randomness, third-party SDKs), placed as far out as possible: MSW at the
   HTTP layer rather than mocking `fetch` or an API module. Wrap third-party
   code you depend on and fake the wrapper.

Never mock the unit under test or your own modules it calls. Don't assert
on which internal functions were called or in what order; assert on
outcomes. Checking a call is only acceptable when the call itself is the
observable behavior at a boundary, e.g. "sends exactly one email".

## React components

Test the way a user would, with Testing Library (Kent C. Dodds):

- Query by role first (`getByRole` with its accessible name), then label,
  then text. `getByTestId` is a last resort.
- Drive interactions with `user-event`, not `fireEvent`. Use `findBy*` or
  `waitFor` for async results.
- Don't assert on component state, props, hooks or instance methods.
- No shallow rendering: render with real children. Snapshots don't replace
  behavioral assertions.
- Logic with meaning of its own (pricing, validation, formatting rules)
  belongs in a calculation outside the component, tested directly. Anything
  else is tested through the rendered component.

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
  test breaks on refactors even when behavior hasn't changed. See Test
  doubles above.
- **Horizontal slicing** — writing every test on the list before making
  any of them pass. Work one item at a time.

## Exceptions

Documentation, pure configuration with no branching logic, generated
code, throwaway prototypes explicitly marked as such, and mechanical
renames verified by build/typecheck alone. State the exception explicitly
rather than silently skipping the loop.
