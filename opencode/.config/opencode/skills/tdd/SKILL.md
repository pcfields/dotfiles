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
  test breaks on refactors even when behavior hasn't changed.
- **Horizontal slicing** — writing every test on the list, then all
  implementation. Work vertically: one list item → one test → one minimal
  implementation → repeat until the list is empty.

## Exceptions

Documentation, pure configuration with no branching logic, generated
code, throwaway prototypes explicitly marked as such, and mechanical
renames verified by build/typecheck alone. State the exception explicitly
rather than silently skipping the loop.
