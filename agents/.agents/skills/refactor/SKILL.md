---
name: refactor
description: Refactor this, clean up this file, improve code health, reduce complexity, untangle this function, pay down tech debt, make this code AI-friendly. Improves the structure of existing code without changing behavior, as a quick tidy before a change or a full uplift of a file — in small tested steps, using named refactorings and a per-repo playbook of what worked. Use whenever the user asks to refactor, tidy or uplift code, or to act on a repo-health report.
---

Refactoring changes structure, never behavior. A bug found on the way is
reported, not fixed in the same commit.

Before removing or rewriting something that looks pointless, find out why it
is there: its callers, its tests, `git blame`. Never drop error handling to
make code look cleaner.

## Size it first

- **Tidy**: a few small cleanups, minutes each, that make the change in hand
  easier. Use the short path below.
- **Uplift**: improving a whole file or module for its own sake, usually
  because the user asked or a `repo-health` report pointed at it. Use steps
  1-7.

If a tidy turns out to need more than a handful of steps, stop and offer an
uplift instead of growing it.

## Tidy (short path)

1. Run the tests that cover the code and quote the result. If nothing covers
   it, say so and ask the user which they want before touching anything:
   - write a test for the current behavior first (through the public
     interface, as in the `tdd` skill), commit it, then tidy freely; or
   - go ahead without one, limited to tidyings that can't change behavior
     (delete dead code, rename, reorder, blank lines).

   Recommend the test when the project has a test suite and the tidying
   rearranges logic (guard clauses, extracted helpers).
2. Pick the tidyings from [refactorings.md](refactorings.md), list them with
   `file:line`, and wait for the user's yes.
3. Make them, run the tests again, and commit them separately from the
   behavior change (`refactor(scope): ...`).

No baseline, re-measuring or playbook entry.

## Uplift

### 1. Target and baseline

Take one file (or one function) at a time. If the user named no target, run
the `repo-health` skill and propose the worst hotspot.

Record the starting numbers:
`bash ~/.agents/skills/repo-health/scripts/repo-health.sh <file>`.

### 2. Safety net

The behavior being preserved must be covered by tests that pass now. Run
them first and quote the result.

If coverage is missing, write characterization tests through the public
interface (the `tdd` skill covers seams and test doubles) and commit them
separately, before any refactoring. If the code can't be tested as it stands
and no other check exists (a build, a replay, a snapshot of output), stop and
ask.

### 3. Diagnose

Read `docs/refactoring-playbook.md` if the repo has one; its recipes come
first because they already worked here.

Then name each problem and pick its fix from
[refactorings.md](refactorings.md).

Renames alone don't count. If the plan is only renames, the structural
problem hasn't been addressed yet.

### 4. Propose

List the steps in order, one refactoring each, with the `file:line` it
applies to. **Stop and wait for the user to confirm or adjust.**

### 5. One step at a time

For each step: make the one change, run the tests, quote the result, commit
(`refactor(scope): ...`, one refactoring per commit). If the tests fail,
undo the step rather than patching forward; after a second failure on the
same step, stop and ask.

### 6. Re-measure and stop

Run the script again and compare with the baseline. Re-read the code: stop
when the problems from step 3 are gone or the next step would not make the
code easier to change. Lower numbers with worse readability is a failure.

### 7. Record what worked

When a refactoring solved a problem that will recur in this codebase, add it
to `docs/refactoring-playbook.md` (create the file if missing, and say so).
Generic entries such as "Extract Function" add nothing; record the
codebase-specific shape, narrow enough to recognise mechanically:

```markdown
## Action Parameter

**Problem:** two functions with the same control structure that differ only
in which function they call (e.g. `scroll_x` and `scroll_y`).
**Applies when:** the bodies match line for line apart from the callee, and
the callees take the same arguments.
**Doesn't apply when:** the bodies have drifted apart; unify them first.
**Do:** extract the shared body into one function that takes the callee as a
parameter; the originals become one-line callers.
**First used:** `src/scroll.c`, commit abc1234.
```

## Report

For a tidy: what was tidied and the test result. For an uplift: before and
after numbers, the refactorings applied, the test result quoted,
what was deliberately left and why, and any playbook entries added.
