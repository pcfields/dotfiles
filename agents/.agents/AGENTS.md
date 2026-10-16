# Global instructions

Personal defaults for every project, on any machine, for any AI agent harness.
Project-level instructions add detail on top of this. Keep this file short: it
loads into every session. Anything the harness config can enforce (permissions,
hooks) belongs there, not here.

## Communication

- Be concise and direct. For non-trivial work, restate the task and propose a
  short plan before diving in; summarize what changed afterward.
- Don't ask for confirmation on read-only actions (reading files, searching,
  listing).
- Ask before ambiguous, high-impact changes, or anything touching auth,
  public APIs, schemas, or infra.
- Ask, don't assume, when requirements admit more than one reasonable
  interpretation, a file about to be touched has an unexpected structure, the
  detected test/lint/build command doesn't match expectations, or scope is
  expanding beyond what was named. After a verification loop fails once, ask
  before retrying differently. Don't ask when the answer is already in the
  plan or the choice is trivial.

## Core philosophy

- Tidy first (Kent Beck): before changing behavior, look for small tidyings
  that make the change easier (clearer names, extracted helpers, dead code
  removed). Keep tidyings in their own commits, separate from behavior
  changes. Propose them before doing them.
- Iterate and keep improving: plans, code and the product are expected to
  change as we learn. Revisit and update plans, tests and code when feedback
  or new facts show a better way; leave code cleaner than you found it.

## Working discipline

- Understand the current behavior and constraints before editing.
- Prefer small, reversible changes over big rewrites. Match existing style.
- If confidence is low, say so and propose a safe next step instead of
  guessing.
- Detect the project's setup instead of assuming it: package manager from
  lockfiles, test/lint/typecheck/build commands from `package.json` scripts,
  `Makefile`, `justfile`, CI config or the README, and conventions from the
  project's own instructions, `CONTRIBUTING.md`, `.editorconfig` and
  linter/formatter config. Respect team conventions silently; don't propose
  changing them unprompted. If detection is ambiguous, ask.

## Design

Grokking Simplicity (Eric Normand) is the anchor; the other ideas here are
applied through it.

- Separate data, calculations (pure functions, no I/O) and actions (side
  effects). Push actions to the edges: a functional core inside a thin
  imperative shell.
- Explicit data flow: pass data as arguments, return results. Avoid hidden
  state and implicit mutation; treat data as immutable (copy-on-write).
- Deep modules (John Ousterhout, *A Philosophy of Software Design*): a
  simple interface hiding real functionality. Pull complexity down into the
  module instead of pushing it onto callers. Every layer must add meaning;
  no pass-through wrappers.
- Simple design (Kent Beck): passes the tests, reveals intention, no
  duplication, fewest elements. No speculative abstraction.
- Intention-revealing names; each unit has a single responsibility.
- Extract a function when a pattern repeats, or to pull a calculation out of
  an action. Not just to make functions shorter.

## Testing

- Test behavior, not implementation (Kent C. Dodds): the more tests resemble
  how the software is used, the more confidence they give. Test through the
  public interface; a refactor that preserves behavior must not break a test.
- Calculations get fast, direct tests with plain values. Actions get fewer
  tests, through the real interface (DOM, HTTP, CLI).
- Mocking is a design smell. Needing a mock usually means logic is tangled
  with an action: extract the calculation instead. Preference order: real
  code, then an in-memory fake or Nullable (James Shore), then a mock only at
  a boundary you don't own (network, clock, randomness), placed as far out
  as possible (MSW rather than mocking `fetch`).
- Assert on outcomes (return values, resulting state, what the user sees),
  not on which internal functions were called. Never mock your own modules.
- The `tdd` skill has the procedure, test-double details and React rules.

## Coding style

- Prefer a single options object over many params. Positional is fine for 1-2
  params whose order is obvious; use an object at 3+, or whenever any param is
  optional, a boolean, or shares a type with another (so call sites are
  self-describing).
- Top-level functions use `function` declarations; use `const fn = ...` for
  helpers inside other functions. Put the file's main purpose at the top and
  its helper functions below it.

## Test-driven development

- Canon TDD (Kent Beck) is the default technique for new logic and bug
  fixes, when the project has a test suite: build a test list, take one test
  at a time, make it pass for real, refactor only while green. Use the `tdd`
  skill for the full procedure.

## Commits

- Conventional commits, one logical change each. Use the `commit` skill when
  preparing commits.

## Definition of done

- Run the project's tests and any linter/type-checker before calling a task
  complete. Fix failures or report them explicitly. Never declare done with
  red tests.
- For non-trivial changes (new logic, bug fixes; not docs or mechanical
  edits), run a low-effort code review on the diff before handing back, and
  note what was addressed vs. deliberately left.
- Evidence before claims: never say "should pass" or "looks correct". Run the
  verification command, read the output, and quote it before claiming
  completion.

## Safety

**Never modify without explicit cause:** lockfiles, generated files,
migrations, CI configs, deployment configs, `.env*` files, secrets.

**Security-sensitive, so plan first and get explicit approval:** auth/authz,
sessions/cookies, headers/CSP, CORS, token storage, secrets handling, input
validation, query construction (SQL/NoSQL/LDAP), file uploads, rate limiting,
payments, webhooks, production infrastructure.

**Stop and ask when:**

- Two verification loops have failed on the same task.
- Unexpected changes appear outside the named module or package.
- An operation is destructive or irreversible.
- A push to a shared branch, a publish, or a deploy is about to happen.

**Isolated workspace:** in shared or team repos, do non-trivial work on a
branch or worktree and never implement directly on `main`/`master` without
consent. In personal repos, committing to `main` is fine.
