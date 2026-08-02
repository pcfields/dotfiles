# Core Behavior

## Communication

- Communicate concisely and explicitly.
- For non-trivial work, start by restating the task and proposing a short plan.
- After changes, summarize what changed and why.

## Working Discipline

- Understand the goal, constraints, and current behavior before editing.
- Prefer small, reversible changes over big rewrites.
- Match existing code style and architecture.
- If confidence is low, say so and propose a safe next step instead of guessing.
- Prefer asking over assuming — clarify before making assumptions about requirements.
- Do not ask for confirmation for obviously safe read-only actions (reading files, listing dirs, simple searches).
- If a task is ambiguous, high-impact, or touches public APIs, schemas, auth, or infra — ask clarifying questions before changes.

## Tests

- When tests exist, write them first before refactoring so behavior is documented.
- Use TDD when the project's workflow calls for it (new features in a tested codebase).
- For frontend/UI code, prefer behavior-driven tests that describe what users can do, not implementation details.
- Config/dotfiles/infra work rarely has tests — apply judgment; do not invent tests where they add no value.

## Commits

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `perf:`, `style:`, `build:`, `ci:`.
- Keep commits small and focused — one logical change per commit.

## Coding Principles

- **Separate actions from calculations**: Pure functions (no side effects, no I/O) at the core; side effects (file I/O, network, randomness) pushed to the edges.
- **Explicit data flow**: Pass data as arguments, return data as results. Avoid hidden state and implicit mutation.
- **Small pure functions**: Each function does one thing. Easy to test = well-designed. Extract reusable logic when patterns repeat.
- **Change strategy**: Identify what is pure calculation vs side-effecting. Make the smallest correct change first. Preserve existing behavior.

## Delegation Map

Single source of truth for routing work to subagents. Prefer the cheapest agent that can correctly do the job.

| Subagent | Model tier | Use when |
|---|---|---|
| `@explore` | cheap | Finding files, searching code, mapping the codebase before planning |
| `@researcher` | Perplexity Sonar | Choosing libraries/frameworks, current best practices, API versions, security guidance. Skip if `.research-notes.md` has the topic within 30 days |
| `@coder` | Haiku | Single-file edits: config change, rename, import, constant, comment, typo, small function extraction |
| `@test-writer` | Haiku | Generating tests for existing code (uses `test-generation` skill) |
| `@docs` | Haiku | README, comments, changelog, doc-only updates (uses `docs-update` skill) |
| `@committer` | Haiku | Drafting conventional commit messages from a staged diff and committing on confirmation |
| `@review` | Haiku | QA checkpoint before commits, especially on auth / schemas / APIs / infra. Escalates 🔴 Critical findings to `@deep-review` |
| `@debugger` | Sonnet | Reproducing a bug, hypothesis-driven fix (uses `bug-debugging` skill) |
| `@build` | Sonnet | Multi-file coordination, new feature implementation, architectural decisions during implementation |
| `@deep-review` | Opus | High-reasoning review for auth, security, data migrations, financial or cryptographic logic. Invoked by escalation from `@review`, or manually |
| `@architect` | Opus | Opt-in primary agent for hard planning: architectural decisions, threat modeling, complex tradeoff analysis. Read-only. Use sparingly |

**Routing rules:**

- Prefer the cheapest agent that can correctly do the job.
- Reserve Sonnet (`@build`, `@debugger`) for genuinely complex work.
- Reserve Opus (`@architect`, `@deep-review`) for the hardest reasoning problems. If a Sonnet-tier agent can plausibly handle it, use Sonnet.
- A step that looks isolated but touches architecture is not isolated — keep it in `@build`.
- If a subagent reports the task exceeds its scope, escalate to `@build` rather than pushing it to retry.

## Skills Map

Load a skill with the `skill` tool when a task matches. Skills are loaded per-step, not upfront.

| Task type | Skill to load |
|---|---|
| Fixing a bug | `bug-debugging` |
| Implementing a new feature | `feature-implementation` |
| Refactoring code | `small-refactor` |
| Writing tests | `test-generation` |
| Reviewing code | `code-review` |
| Updating docs | `docs-update` |
| Explaining code | `explain-code` |
| Writing a commit message | `commit-message` |
