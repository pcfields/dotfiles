# code-health

Scores code health per file and flags new or worse code smells. See
`docs/plans/code-health.md` in the dotfiles repo for the design.

## About

### Why it exists

Agentic coding is fast, but agents write complex code that they then can't
safely change. Each edit makes the next one riskier, and agents rarely
notice the code getting harder to work in.

Research presented by Adam Tornhill (CodeScene, GOTO 2026, "AI-Friendly
Code") reports:

- AI breaks code about 60% more often at a Code Health of 9 than at 10.
  Code that agents can work in safely starts around 9.5, so aim for 10.
- Unaided, a frontier agent fixes about 20% of code smells. With a tool that
  gives it the score and names each smell, it fixes 90–100%.

What changes the outcome is feedback that names each problem, not a better
model.

### How it works

It's a loop:

1. The agent writes code.
2. `code-health` scores each changed file from 1 to 10 and lists each smell,
   for example a method that is too complex, nested too deep or takes too
   many arguments, with a suggested refactoring.
3. The agent refactors.
4. The tool scores the file again, until nothing new or worse remains.

A hook runs the check every time the agent finishes, so it doesn't depend on
the agent remembering to ask. Only findings the change introduced or made
worse block the agent. Existing problems in legacy files are reported but
don't fail. Only the user can accept a finding, never the agent.

### Why build our own

CodeScene sells this loop as its CodeHealth MCP server. This tool is a
smaller, free version that:

- runs on any machine, Linux or Windows, in any project
- works with any agent harness, because it's a plain CLI with thin adapters
- covers the languages used here: C#, TypeScript and JavaScript, Python,
  bash, PowerShell, Lua and Rust
- keeps project history local and out of shared repos

Its scores are not calibrated against CodeScene yet. Treat a score as a
guide to compare versions of the same file, not as an absolute measure.
