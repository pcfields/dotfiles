# Problems and the refactorings that fix them

Name the problem first, then apply the refactoring beside it. Names follow
Kent Beck's *Tidy First?*, Martin Fowler's *Refactoring* (2nd ed.) and Eric
Normand's *Grokking Simplicity*.

Prefer functions and plain data. Don't introduce class hierarchies or
polymorphism to remove a conditional unless the codebase already works that
way.

## Tidyings (minutes each)

| Problem | Tidying |
|---|---|
| Body wrapped in a condition that only rules cases out | Guard clause: return early, un-nest the rest |
| Code nothing calls or reaches | Delete it; version control remembers |
| The same thing done two different ways in one file | Normalize: pick one way and use it everywhere |
| A long expression that has to be decoded | Explaining variable: name the intermediate result |
| A literal whose meaning isn't obvious | Explaining constant: give it a name |
| A function that reads a setting or global halfway down | Explicit parameter: pass the value in |
| A variable declared far from where it is first set or used | Move declaration and initialization together |
| A block doing several things with no visual breaks | Chunk statements: blank lines between the steps |
| A few lines with one clear purpose inside a bigger function | Extract helper, named after the purpose |
| Related code scattered, so a change means hunting | Cohesion order: move things that change together next to each other |
| A file you have to read out of order to follow | Reading order: main purpose first, helpers below |
| A comment that repeats the code | Delete it |
| Code that needed explaining to you just now | Explaining comment: write down what you learned |
| The call you wish you could write doesn't exist | New interface, old implementation: add it as a thin wrapper, then use it |

## Refactorings (structural)

| Problem | Refactoring |
|---|---|
| Long function, several jobs in one | Extract Function; Split Phase when the jobs run in sequence |
| Deep nesting, several nested chunks | Replace Nested Conditional with Guard Clauses; Decompose Conditional |
| Comment block beside a special-case `if` | Extract Function, named after what the comment says |
| Same process twice with one thing varying | Extract Function; Parameterize Function with the part that varies |
| Long parameter list | Introduce Parameter Object; Preserve Whole Object |
| File every feature has to touch | Move Function; split the module by responsibility |
| Files that always change together | Move Function so the shared concept lives in one place |
| Pieces split so small the whole can't be followed | Inline them back into one pile, then extract along better lines |
| Calculation buried in an action (logic mixed with I/O) | Extract the calculation: inputs as arguments, result returned, the action left as a thin caller |
| Hidden input or output (global, module state, a mutated argument) | Make it explicit: pass it in, return it |
| Data mutated in place | Copy-on-write: return a changed copy |
| Query that also changes something | Separate Query from Modifier |
| Catch-all that swallows the error | Catch only what can be handled; let the rest propagate. This changes behavior, so propose it separately |
