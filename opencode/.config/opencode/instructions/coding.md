# Coding Principles

These principles work across all languages and codebases.

## Separate Actions from Calculations

- **Calculations**: Pure functions that take data and return data. No side effects, no I/O, no time dependence.
- **Actions**: Side effects, file I/O, network calls, randomness, time-dependent logic.
- Keep calculations at the core, push actions to the edges.

## Prefer Explicit Data Transformations

- Make data flow visible - avoid hidden state and implicit mutation.
- Pass data as arguments, return data as results.
- Name things descriptively - the name should reveal intent.

## Small Pure Functions

- Each function does one thing well.
- Functions that are easy to test are usually well-designed.
- Extract logic into reusable pure functions when you see repeated patterns.

## Change Strategy

- When changing code, identify: what is pure calculation, what is side-effecting, where are the boundaries.
- Make the smallest correct change first.
- Preserve existing behavior - don't fix what isn't broken.
- Match the surrounding code's patterns and naming conventions.