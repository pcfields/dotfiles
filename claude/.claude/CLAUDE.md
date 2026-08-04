# Global instructions

Personal defaults for every project, on any machine. Project-level CLAUDE.md
adds detail on top of this — keep this file short since it loads into every
session's context.

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
- If confidence is low, say so and propose a safe next step instead of
  guessing.

## Coding principles

- Separate calculations (pure functions, no I/O) from actions (side effects).
  Push side effects to the edges.
- Explicit data flow: pass data as arguments, return results. Avoid hidden
  state and implicit mutation.
- Small functions that each do one thing. Extract only when a pattern
  actually repeats — no speculative abstraction.

## Commits

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`,
  `chore:`, `perf:`, `style:`, `build:`, `ci:`.
- Small, focused commits — one logical change each.

## Delegation map

Prefer the cheapest tool that can correctly do the job.

| Need | Use |
|---|---|
| Find files, search code, map a codebase before planning | built-in `Explore` agent |
| Multi-step research/execution that isn't code search | built-in `general-purpose` agent |
| Single-file mechanical edit (rename, config tweak, constant, typo) | `small-edits` subagent (Haiku) |
| README / comments / changelog only | `docs` subagent (Haiku) |
| Generate tests for existing code | `test-writer` subagent (Haiku) |
| Review a diff or check for security issues | built-in `review` / `security-review` / `simplify` skills — don't reinvent these |

## Skills map

| Task | Skill |
|---|---|
| Draft a commit message from staged changes | `commit-message` |
| Investigating a bug | `bug-debugging` |
| Explaining unfamiliar code to a human | `explain-code` |

## Cost efficiency

- Default to low/medium reasoning effort; reserve high effort for genuinely
  hard architectural or correctness questions.
- Prefer Grep/Glob over reading whole files; read only the slice you need.
- Batch independent reads/searches in parallel instead of sequentially.
- Delegate search, exploration, and mechanical edits per the table above
  instead of doing them in the main loop.
- Use `/clear` between unrelated tasks rather than letting context grow
  across topics.
