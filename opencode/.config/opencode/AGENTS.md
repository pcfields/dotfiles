# Global Rules

Personal rules for every OpenCode session, in every project, solo or on a
team. See `docs/opencode-strategy.md` in the dotfiles repo for the full
reasoning behind this setup.

## Core Rule

Use the lightest workflow that produces credible evidence for the change's
risk.

- **Low risk** (typo, isolated function, trivial fix): implement and verify
  directly. No plan file.
- **Medium risk** (a feature in one module, a refactor with tests): write a
  short plan file first, then implement with TDD, then review, then commit.
- **High risk** (auth, migrations, cross-module changes, anything on the
  security-sensitive list below): write explicit acceptance criteria, work
  in an isolated branch/worktree, get a `/review` plus the user's own
  review, and get explicit approval before any external or irreversible
  effect (push, deploy, publish).

## Ask When Unsure

Ask, don't assume, when:

- Requirements admit more than one reasonable interpretation.
- A file or module about to be touched has an unexpected structure.
- The detected test/lint/build command doesn't match what was expected.
- Work is about to touch anything on the security-sensitive or
  never-modify-without-cause lists below.
- A verification loop has failed once — ask before retrying differently.
- Scope is expanding beyond what was named (changes appearing outside the
  named module/package).
- A `.gitignore` change would be needed to keep a generated file (e.g. a
  plan file) out of version control.

Do not ask when the answer is already in the plan, or the choice is
trivial with no meaningful downside either way.

## Project Auto-Detection

No project ever has a committed `.opencode/` folder from this setup — this
is a global-only configuration. At the start of any non-trivial task,
detect instead of assuming:

- Package manager from lockfiles (`package-lock.json`, `pnpm-lock.yaml`,
  `yarn.lock`, `bun.lockb`, `Cargo.toml`, `go.mod`, `pyproject.toml`,
  `Gemfile`, `pom.xml`, etc).
- Test / lint / typecheck / build commands from `package.json` scripts,
  `Makefile`, `justfile`, CI config, or `README.md`.
- Existing conventions from the project's own `AGENTS.md`,
  `CONTRIBUTING.md`, `.editorconfig`, linter/formatter config — respect
  these silently, don't propose changes to team conventions unprompted.

If detection fails or is ambiguous, ask rather than guess.

## Plan Files

For medium/high-risk work, write the plan to a file instead of leaving it
in chat history, so implementation reads one clean artifact instead of a
whole planning conversation.

- **Location:** `docs/plans/` in the current repo.
- **Filename:** `YYYY-MM-DD-descriptive-topic.md` — the topic must
  describe the concrete change, not a vague category.
  - Good: `2026-08-16-rate-limit-auth-endpoints.md`
  - Bad: `2026-08-16-auth-changes.md`, `2026-08-16-refactor.md`
- **Collisions:** append `-v2`, `-v3`, etc. rather than overwriting.
- **Version control:** the user decides per task whether `docs/plans/` is
  committed or gitignored. Ask before modifying `.gitignore`.
- **Low-risk exception:** skip the plan file entirely.

## Safety Invariants

**Never modify without explicit cause:** lockfiles, generated files,
migrations, CI configs, deployment configs, `.env*` files, secrets.

**Security-sensitive — requires a plan and explicit approval:**
auth/authz, sessions/cookies, headers/CSP, CORS, token storage, secrets
handling, input validation, query construction (SQL/NoSQL/LDAP), file
uploads, rate limiting, payments, webhooks, production infrastructure.

**Stop conditions:**

- Two failed verification loops on the same task.
- Unexpected changes appearing outside the named module/package.
- Any destructive or irreversible operation.
- A push to a shared branch, a publish, or a deploy.

**Isolated workspace:** non-trivial work happens on a branch or worktree.
Never implement directly on `main`/`master` without explicit consent.

**Evidence before claims:** never say "should pass" or "looks correct" —
run the actual verification command, read the actual output, quote it
before making any completion claim.

## Cost Habits

- One task per session where practical — start a new session once a task
  completes rather than layering unrelated work onto one long chat.
- Hand off state as files (plans, diffs), not accumulated chat history.
- Default to Sonnet; don't reach for a bigger model preemptively. Escalate
  via manual `/model` only after Sonnet has genuinely stalled, and switch
  back once the hard part is solved.
- Use `/commit`, `/test`, and `/review` for the scoped, cheaper-model work
  they're built for instead of doing it inline on the default model.
