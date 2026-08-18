---
name: production-review
description: Use when reviewing a diff for spec compliance and engineering quality, typically via the /review command. Reports two axes separately with severity per finding.
---

# Production Review

Review the diff between the current state and a fixed point (a commit,
branch, or the merge-base with `main`) along two separate axes. Report
them separately — do not merge or rerank findings across axes. A change
can pass one and fail the other.

## Axis 1: Spec compliance

Does the change do what was asked?

- Requirements from the plan file (or the task description) that are
  missing or partially implemented.
- Behavior in the diff that wasn't asked for (scope creep).
- Requirements that look implemented but where the implementation looks
  wrong on inspection.

If there's no plan file or spec available, say so and skip this axis
rather than inventing requirements to check against.

## Axis 2: Engineering quality

- **Correctness** — edge cases, error handling, off-by-ones, concurrency.
- **Security** — anything touching the security-sensitive list in the
  global `AGENTS.md`: auth/authz, sessions, headers/CSP, CORS, tokens,
  secrets, input validation, query construction, uploads, rate limiting,
  payments, webhooks, production infra.
- **Tests** — do they test real behavior at the agreed seam, or internals?
  Any of the `tdd` skill's anti-patterns present?
- **Smells** — a reference baseline, not a hard rule; a project's own
  documented standards or linter always override these:
  - **Mysterious name** — rename it; if no honest name comes, the design
    is unclear.
  - **Duplicated code** — extract the shared shape.
  - **Feature envy** — a method reaching into another object's data more
    than its own; move it.
  - **Data clumps** — the same fields keep travelling together; bundle
    them.
  - **Shotgun surgery** — one logical change forces edits scattered across
    many files; gather what changes together.
  - **Speculative generality** — abstraction or parameters for needs the
    spec doesn't have; delete it.

## Severity

Tag every finding:

- **Critical** — must be fixed before this is considered done.
- **Important** — should be fixed; explain the risk if left as-is.
- **Minor** — worth mentioning, not blocking.

## Output

Report under two headings, `## Spec Compliance` and `## Engineering
Quality`, each with its findings and severities. End with a one-line count
per axis. This review is read-only and does not replace the user's own
read of the diff — it's a second opinion, not a gate that edits anything.
