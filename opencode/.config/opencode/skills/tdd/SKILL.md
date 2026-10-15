---
name: tdd
description: Use when implementing a feature or bugfix for medium/high-risk work, before writing implementation code. Covers the test list, seam discipline, the red-green-refactor loop (including fake-it/triangulate), and anti-patterns to reject.
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass. This is
the technique used inside medium and high-risk work (see the core rule in
the global `AGENTS.md`) — not a mandate for every change. Based on Kent
Beck's Canon TDD (https://newsletter.kentbeck.com/p/canon-tdd).

## Test list

Before writing the first test, list the behavior variants expected —
normal cases, edges, errors. Keep it visible: a comment, a scratch note,
or the plan file. Convert exactly one item to a test at a time; don't
convert the whole list to tests before making any of them pass, and add
newly discovered cases back to the list instead of chasing them mid-test.

Picking order matters — prefer the case that teaches the most about the
design over the hardest one first. This is a skill that improves with
practice, not a fixed formula.

## Seams — where tests go

A seam is the public boundary you test at: the interface where you observe
behavior without reaching inside. Tests live at seams, never against
internals.

Agree the seam with the user (or from the plan file) before writing any
test. You can't test everything — agreeing seams up front is how testing
effort lands on the behaviors that matter instead of every internal
detail.

## The loop

### RED

Write one minimal test showing one behavior.

```
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };
  const result = await retryOperation(operation);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

Run it. **Verify it fails for the expected reason** — feature missing, not
a typo or setup error. A test that passes immediately is testing existing
behavior, not the change you're making.

### GREEN

Make it pass for real — "make it run, then make it right." Hardcoding a
return value to get to green fast is fine as a first step; a later test on
the list should force a more general solution (triangulation). What's
never allowed: faking it by deleting or weakening the assertion, or by
copying the computed output into the expected value — both destroy what
the test is for. No speculative generality beyond what the current test
demands, no unrelated refactors, no parameters or options the test doesn't
ask for.

### REFACTOR

Clean up only while green: remove duplication, improve names, extract
helpers. Structural redesign belongs in review, not this loop.

### VERIFY

Run the targeted test, then the relevant suite, typecheck, lint, and
build. Never claim "should pass" — run it, read the output, quote it.

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
  they prove nothing about whether they catch the bug they claim to test.
- **Tautological assertions** that recompute the expected value the same
  way the code does — they pass by construction and can't disagree.
- **Mocking internals** instead of testing through the public seam — the
  test breaks on refactors even when behavior hasn't changed. See Test
  doubles above.
- **Horizontal slicing** — writing every test on the list, then all
  implementation. Work vertically: one list item → one test → one minimal
  implementation → repeat until the list is empty.

## Exceptions

Documentation, pure configuration with no branching logic, generated
code, throwaway prototypes explicitly marked as such, and mechanical
renames verified by build/typecheck alone. State the exception explicitly
rather than silently skipping the loop.
