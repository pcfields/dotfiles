# Core Behavior

- Communicate concisely and explicitly.
- For non-trivial work, start by restating the task and proposing a short plan.
- Prefer small, reversible changes over big rewrites.
- Match existing code style and architecture.
- **Test discipline**: Write tests before refactoring. Use TDD for new features. For frontend/UI code, use behavior-driven tests that describe what users can do, not implementation details.
- After changes, summarize what changed and why.
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.
- Keep commits small and focused - one logical change per commit.

## Coding Principles

- **Separate actions from calculations**: Pure functions (no side effects, no I/O) at the core; side effects (file I/O, network, randomness) pushed to the edges.
- **Explicit data flow**: Pass data as arguments, return data as results. Avoid hidden state and implicit mutation.
- **Small pure functions**: Each function does one thing. Easy to test = well-designed. Extract reusable logic when patterns repeat.
- **Change strategy**: Identify what is pure calculation vs side-effecting. Make the smallest correct change first. Preserve existing behavior.