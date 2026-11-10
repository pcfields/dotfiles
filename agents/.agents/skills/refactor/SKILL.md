---
name: refactor
description: Refactor this, clean up this file, improve code health, reduce complexity, untangle this function, pay down tech debt, make this code AI-friendly. Improves the structure of existing code without changing behavior — measured before and after, in small tested steps, using named refactorings and a per-repo playbook of what worked. Use whenever the user asks to refactor, tidy or uplift code, or to act on a repo-health report.
---

Refactoring changes structure, never behavior. A bug found on the way is
reported, not fixed in the same commit.

## 1. Target and baseline

Take one file (or one function) at a time. If the user named no target, run
the `repo-health` skill and propose the worst hotspot.

Record the starting numbers:
`bash ~/.agents/skills/repo-health/scripts/repo-health.sh <file>`.

## 2. Safety net

The behavior being preserved must be covered by tests that pass now. Run
them first and quote the result.

If coverage is missing, write characterization tests through the public
interface (the `tdd` skill covers seams and test doubles) and commit them
separately, before any refactoring. If the code can't be tested as it stands
and no other check exists (a build, a replay, a snapshot of output), stop and
ask.

## 3. Diagnose

Read `docs/refactoring-playbook.md` if the repo has one; its recipes come
first because they already worked here.

Then name each problem and pick the refactoring for it:

| Problem | Refactoring |
|---|---|
| Long function, several jobs in one | Extract Function; Split Phase when the jobs run in sequence |
| Deep nesting, several nested chunks | Replace Nested Conditional with Guard Clauses; Decompose Conditional |
| Comment block beside a special-case `if` | Extract Function, named after what the comment says |
| Same process twice with one thing varying | Extract Function; Parameterize Function with the part that varies |
| Long parameter list | Introduce Parameter Object; Preserve Whole Object |
| Magic number or unexplained literal | Replace Magic Literal with a named constant |
| File every feature has to touch | Move Function; split the module by responsibility |
| Files that always change together | Move Function so the shared concept lives in one place |
| Calculation buried in an action (logic mixed with I/O) | Extract the calculation: inputs as arguments, result returned, the action left as a thin caller |
| Hidden input or output (global, module state, a mutated argument) | Make it explicit: pass it in, return it |
| Data mutated in place | Copy-on-write: return a changed copy |
| Query that also changes something | Separate Query from Modifier |
| Catch-all that swallows the error | Catch only what can be handled; let the rest propagate. This changes behavior, so propose it separately |

Prefer functions and plain data. Don't introduce class hierarchies or
polymorphism to remove a conditional unless the codebase already works that
way.

Renames alone don't count. If the plan is only renames, the structural
problem hasn't been addressed yet.

## 4. Propose

List the steps in order, one refactoring each, with the `file:line` it
applies to. **Stop and wait for the user to confirm or adjust.**

## 5. One step at a time

For each step: make the one change, run the tests, quote the result, commit
(`refactor(scope): ...`, one refactoring per commit). If the tests fail,
undo the step rather than patching forward; after a second failure on the
same step, stop and ask.

## 6. Re-measure and stop

Run the script again and compare with the baseline. Re-read the code: stop
when the problems from step 3 are gone or the next step would not make the
code easier to change. Lower numbers with worse readability is a failure.

## 7. Record what worked

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

Before and after numbers, the refactorings applied, the test result quoted,
what was deliberately left and why, and any playbook entries added.
