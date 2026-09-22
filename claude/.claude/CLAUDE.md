# Global instructions

Personal defaults for every project, on any machine. Project-level CLAUDE.md
adds detail on top of this. Keep this file short: it loads into every session.
Anything a setting or hook can enforce belongs in `settings.json`, not here.

## Communication

- Be concise and direct. For non-trivial work, restate the task and propose a
  short plan before diving in; summarize what changed afterward.
- Don't ask for confirmation on read-only actions (reading files, searching,
  listing).
- Ask before ambiguous, high-impact changes, or anything touching auth,
  public APIs, schemas, or infra.

## Working discipline

- Understand the current behavior and constraints before editing.
- Prefer small, reversible changes over big rewrites. Match existing style.
- For bug fixes, reproduce the bug with a failing test first when the project
  has a test suite, then make it pass.
- If confidence is low, say so and propose a safe next step instead of
  guessing.

## Coding principles

- Separate calculations (pure functions, no I/O) from actions (side effects).
  Push side effects to the edges.
- Explicit data flow: pass data as arguments, return results. Avoid hidden
  state and implicit mutation.
- Small functions that each do one thing. Extract only when a pattern
  actually repeats. No speculative abstraction.

## Commits

- Conventional commits, one logical change each. Use the `commit` skill when
  preparing commits.

## Definition of done

- Run the project's tests and any linter/type-checker before calling a task
  complete. Fix failures or report them explicitly. Never declare done with
  red tests.
- For non-trivial changes (new logic, bug fixes; not docs or mechanical
  edits), run `/code-review low` on the diff before handing back, and note
  what was addressed vs. deliberately left.
