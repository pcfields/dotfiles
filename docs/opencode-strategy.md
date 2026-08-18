# OpenCode Strategy

A global-only OpenCode configuration for a senior software engineer working
both solo and inside a professional team, optimized for production quality
and low, predictable AI spend. This lives entirely in
`~/.config/opencode/` — no per-project `.opencode/` folder is required, so
it works unmodified in every repo you open, including team repos you can't
add config files to.

## 1. Core Rule

> Use the lightest workflow that produces credible evidence for the
> change's risk.

- **Low risk** (typo, isolated function, trivial fix): implement and verify
  directly. No plan file.
- **Medium risk** (a feature in one module, a refactor with tests): write a
  short plan file first, then implement with TDD, then review, then commit.
- **High risk** (auth, migrations, cross-module changes, anything on the
  security-sensitive list in §7): write explicit acceptance criteria, work
  in an isolated branch/worktree, get an AI review plus your own review,
  and get explicit approval before any external or irreversible effect
  (push, deploy, publish).

Everything below exists to make this rule concrete and enforceable, not to
add ceremony for its own sake.

## 2. Grokking Simplicity Foundations

- **Data** is inert and shareable: plans, diffs, and review findings are
  written as files, not left buried in chat history.
- **Calculations** are pure reasoning: planning, risk classification, and
  review read data and produce data, without side effects.
- **Actions** are the only things allowed to mutate the world: edits, shell
  commands, commits. Actions are permission-gated and paired with a way to
  verify their effect.
- **Stratified design**: `plan` (strategy) sits above `build`
  (implementation); each layer depends only on the layer below it.
- Abstractions are introduced once a second real use case exists — YAGNI
  and DRY are applied deliberately, not as slogans.

## 3. TDD as a Technique, Not a Mandate

TDD is the default implementation technique inside **medium and high-risk**
work. It is not required for low-risk changes.

**Red → Green → Refactor:**

1. Agree the test seam (the public interface being tested) before writing
   any test.
2. **RED** — write one test for one behavior. Run it. Confirm it fails for
   the expected reason (missing behavior), not a typo or setup error.
3. **GREEN** — write the minimal code to pass. No speculative generality.
4. **REFACTOR** — clean up only while green.
5. **VERIFY** — run the targeted test, then the relevant suite, typecheck,
   lint, and build before claiming done.

**Bug fixes** always start with a failing regression test that reproduces
the reported symptom, regardless of risk tier.

**Anti-patterns to reject:** tests written after the implementation,
tautological assertions that recompute the code's own logic, mocking
internals instead of testing through the public seam, writing all tests
before any implementation.

**Exceptions:** documentation, pure config with no branching logic,
generated code, throwaway prototypes, mechanical renames verified by
build/typecheck alone.

## 4. Architecture

Two agents, three commands. Nothing else.

```text
~/.config/opencode/
├── opencode.jsonc          # default model, small_model, agents + commands registration
├── AGENTS.md               # ~120 lines: invariants, auto-detection, "ask when unsure"
├── agents/
│   ├── plan.md             # read-only: requirements, risk, plan file, acceptance criteria
│   └── build.md            # implementation: TDD loop, confirmation-gated mutations
├── skills/
│   ├── tdd/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── production-review/SKILL.md
│   └── verification-delivery/SKILL.md
└── commands/
    ├── commit.md           # Kimi: draft commit message from staged diff
    ├── test.md             # Kimi: write one test at a named seam
    └── review.md           # Sonnet 5: two-axis review of the current diff
```

### `plan` agent

- Read-only. Never edits files.
- Detects the project's conventions at the start of any non-trivial task
  (see §6).
- Produces: problem statement, 2-3 approaches with trade-offs, chosen
  approach, risk level, test seams, acceptance criteria, verification plan.
- For medium/high-risk work, writes the plan to a file (see §8) and tells
  you the path. For low-risk work, no file is needed — the plan can stay
  as a short chat answer.
- Asks before proceeding whenever the request is ambiguous (see §5).

### `build` agent

- Implements. Can edit files and run shell commands, gated by the
  permission rules in §7.
- If given a plan file path, reads only that file — not the planning
  conversation that produced it — and works from it.
- If no plan file is given, treats the task as low-risk: implement, verify,
  done.
- Runs TDD for medium/high-risk work (§3).
- Self-reviews its own diff for obvious issues before proposing a commit.
- Stops and asks at the boundaries defined in §5 and §7.

### Commands

- **`/commit`** — Kimi. Reads the staged diff, runs a secrets scan on
  staged files, drafts a Conventional Commits message, and presents it for
  your approval. Never commits without you confirming. Falls back to the
  current agent's model if Kimi/Zen is unavailable.
- **`/test`** — Kimi. Given a spec and a named seam (from a plan file, or
  described inline), writes one behavioral test, runs it, and confirms it
  fails for the expected reason. Does not write implementation code.
- **`/review`** — Sonnet 5. Reviews the current diff on two separate axes:
  **spec compliance** (did this build what was asked) and **engineering
  quality** (correctness, security, tests, obvious smells), each finding
  tagged critical/important/minor. Read-only — never edits files. Always
  paired with your own manual read of the diff, never a replacement for it.

No `review` agent, no `/plan` or `/doc` commands, no automatic model
routing based on task content — all model switching is either pinned to a
command or done manually via `/model`.

## 5. Ask When Unsure

This is a first-class invariant, not a fallback behavior. Both agents
**must ask, not assume**, when:

- Requirements admit more than one reasonable interpretation.
- A file or module about to be touched has an unexpected structure.
- The detected test/lint/build command doesn't match what was expected.
- Work is about to touch anything on the security-sensitive list (§7).
- Work is about to touch anything on the "never modify without cause"
  list (§7).
- A verification loop has failed once — ask before retrying with a
  different approach.
- Scope is expanding beyond what was named (unexpected changes outside the
  named module/package).
- A `.gitignore` change would be needed to keep a generated file (e.g. a
  plan file) out of version control.

**They must not ask** when the answer is already in the plan, or the
choice is trivial with no meaningful downside either way.

In practice, `plan` should absorb most of the ambiguity up front, so
`build` rarely needs to interrupt mid-implementation. When `build` does
ask, it's because reality diverged from the plan — which is exactly when
asking earns its cost.

## 6. Project Auto-Detection (Instead of Per-Project Config)

Since this configuration is global-only and no `.opencode/` folder is
committed to any repo, both agents detect project conventions at the start
of any non-trivial task rather than relying on committed config:

- **Package manager** — presence of `package-lock.json`, `pnpm-lock.yaml`,
  `yarn.lock`, `bun.lockb`, `Cargo.toml`, `go.mod`, `pyproject.toml`,
  `Gemfile`, `pom.xml`, etc.
- **Test / lint / typecheck / build commands** — from `package.json`
  scripts, `Makefile`, `justfile`, `Cargo.toml`, `pyproject.toml`, existing
  CI config, or `README.md`.
- **Existing conventions** — a project's own `AGENTS.md`,
  `CONTRIBUTING.md`, `.editorconfig`, linter/formatter config. These are
  respected silently; agents don't propose changes to team conventions
  unprompted.

If detection fails or is ambiguous, ask (per §5) rather than guessing.
Conservative defaults apply regardless of project type: don't run
destructive commands, don't touch lockfiles, don't push, don't deploy,
without explicit cause or approval.

## 7. Safety Invariants

**Never modify without explicit cause:** lockfiles, generated files,
migrations, CI configs, deployment configs, `.env*` files, secrets.

**Security-sensitive — requires a plan and explicit approval:**
auth/authz, sessions/cookies, headers/CSP, CORS, token storage, secrets
handling, input validation, query construction (SQL/NoSQL/LDAP), file
uploads, rate limiting, payments, webhooks, production infrastructure.

**Stop conditions — the only things that halt autonomous work:**

- Two failed verification loops on the same task.
- Unexpected changes appearing outside the named module/package.
- Any destructive or irreversible operation.
- A push to a shared branch, a publish, or a deploy.

**Isolated workspace:** non-trivial work happens on a branch or worktree.
Never implement directly on `main`/`master` without explicit consent.

**Evidence before claims:** never say "should pass" or "looks correct" —
run the actual verification command, read the actual output, quote it
before making any completion claim.

## 8. Plan File Convention

For medium and high-risk work, `plan` writes its output to a file instead
of leaving it in chat history. This keeps `build` focused on one clean
artifact and gives you something concrete to review before implementation
starts.

- **Location:** `docs/plans/` in the current repo.
- **Filename:** `YYYY-MM-DD-descriptive-topic.md` — the date keeps
  chronological sort; the topic must describe the concrete change, not a
  vague category.
  - Good: `2026-08-16-rate-limit-auth-endpoints.md`,
    `2026-08-16-migrate-user-sessions-to-redis.md`,
    `2026-08-16-fix-race-condition-in-order-processing.md`
  - Bad: `2026-08-16-auth-changes.md`, `2026-08-16-refactor.md`
- **Collisions:** if a file with the same date and slug already exists,
  append `-v2`, `-v3`, etc. rather than overwriting.
- **Version control:** you decide per task whether `docs/plans/` is
  committed or gitignored. If `plan` needs to modify `.gitignore` to keep a
  file out of version control, it asks first (§5).
- **Low-risk exception:** no plan file — going through `plan` → file →
  `build` for a trivial change is unnecessary ceremony.
- **Team visibility:** for high-risk work worth sharing, promote the plan
  file into a ticket, PR description, or `docs/decisions/` as a manual
  step. `plan` doesn't need to know about this — it's your call per task.

## 9. Model Palette

One default model, two automatic cheap paths (scoped to commands), manual
escalation for hard problems.

| Role | Model | Notes |
|---|---|---|
| `plan`, `build` (default) | Claude Sonnet 5 (Copilot) | Predictable cost, handles the large majority of real work well. |
| `small_model` | GPT-5.6 Luna | Automatic housekeeping only — session titles, compaction summaries. Set once, saves forever. |
| `/commit`, `/test` | Kimi (OpenCode Zen) | Cheap and capable enough for drafting commit messages and writing individual tests from a clear spec. |
| `/review` | Claude Sonnet 5 | Review is judgment work — worth the stronger model. |
| Manual escalation | Claude Opus (via `/model`) | For problems that have already stalled on Sonnet. Short bursts only — switch back to Sonnet once the hard part is solved. |

**Explicitly excluded:**

- **GPT-5.6 Sol** — excluded. High-effort Sol burns heavy hidden reasoning
  tokens on every response; this was the direct cause of a prior cost
  overrun and nothing about the model has changed. Sonnet 5 handles
  planning and review well enough at a fraction of the cost; when Sonnet
  truly isn't enough, escalate straight to Opus.
- **Claude Fable 5** — not included as a named escalation path. Opus alone
  is simpler to reason about and cheaper per unit; Fable's advantages
  mainly matter for multi-hour autonomous runs, which cuts against a
  cost-sensitive workflow.

**No automatic task-based routing.** OpenCode does not (as of writing)
inspect a task and pick a model based on difficulty. `small_model` is the
one genuinely automatic saving. `/commit`, `/test`, and `/review` are
automatic *within their scope* — type the command, get the pinned model.
Everything else is a manual `/model` switch, by design — simpler to reason
about than an automatic router, and it keeps you in control of spend.

### Evaluating OpenCode Zen's open-weight models

Kimi is the starting recommendation for `/commit` and `/test`, chosen for
its long-context handling. It is a starting point, not a permanent
commitment:

- **Kimi (Moonshot AI)** — strong at long context and structured coding
  tasks. Start here.
- **DeepSeek** — very strong at isolated, algorithmic code; weaker at
  multi-file coordination. Try if Kimi feels off for your style.
- **GLM (Zhipu)** — solid general-purpose coder, good tool use. Third
  option to try.
- **Grok Code (xAI)** — capable but less predictable behaviorally; lower
  priority to evaluate.

Trial each candidate for `/commit` and `/test` for about a week of normal
use before switching. Judge on: does the commit message actually reflect
the diff, does the test it writes actually test the right behavior at the
named seam, and does it fail RED for the right reason.

## 10. Cost-Reduction Techniques

**Prompt-side (permanent, no ceremony):**

- `AGENTS.md` capped at ~120 lines — every line is billed on every turn.
- Skill content loads only when a skill is invoked, never kept permanently
  resident in the core prompt.
- Reasoning/thinking effort kept low or off by default on Sonnet; raised
  manually only for tasks that need it.

**Session-side (habits):**

- One task per session where practical — long-running sessions re-read
  their full history on every turn.
- Start a new session once a task completes rather than continuing to
  layer unrelated work onto one long chat.
- Hand off state as files (plans, diffs), not accumulated chat history —
  this is the entire reason for the plan file convention in §8.
- Exclude large generated files and lockfiles from context where the
  project structure allows it.

**Model-side (deliberate, manual):**

- Default to Sonnet 5; don't reach for a frontier model preemptively.
- Use `/commit` and `/test` for the cheap, bounded work they're built for.
- Escalate to Opus only after Sonnet has genuinely stalled on a task, and
  drop back to Sonnet once the hard part is resolved.

## 11. Summary

Two agents (`plan`, `build`), three commands (`/commit`, `/test`,
`/review`), one default model (Sonnet 5), two scoped cheap paths (Luna for
housekeeping, Kimi for commits/tests), and one manual escalation path
(Opus). Risk determines how much process a change gets — plan files for
medium/high risk, direct implementation for low risk. Project conventions
are detected at runtime instead of configured per repo, so this setup
works unmodified in every project, solo or on a team.
