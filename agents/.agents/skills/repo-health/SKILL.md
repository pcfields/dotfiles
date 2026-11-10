---
name: repo-health
description: Repo health report, code health, hotspots, which files change most, where is the tech debt, what should we refactor first, is this codebase AI-friendly. Investigates a git repo's history and source to rank the most-edited files by complexity, find files that change together, and report overall code health. Use whenever the user asks to assess, audit or investigate a codebase's health or pick refactoring targets.
---

## Measure

From the repo, run `bash ~/.agents/skills/repo-health/scripts/repo-health.sh`.
Options: `--since "3 months ago"` (default 12 months; use about 1 month for a
repo mostly edited by agents), `--top <n>` rows per table, and a path to limit
the report to one directory.

It prints:

- **Hotspots**: files ranked by commits x complexity. This is where unhealthy
  code costs the most, because it is changed the most.
- **Change coupling**: files that keep changing in the same commit.
- **Author density**: files many authors edit. Empty for a solo repo.
- **Least healthy files**: yellow and red files, whether or not they change.
- **Functions over the limits**: functions that are long, branchy (`ccn` is
  cyclomatic complexity) or take many parameters. Needs `lizard`; without it
  the section says so, and you find these by reading.

Complexity comes from indentation. Grades use rough thresholds on file length,
nesting depth and, with `lizard`, the worst function. They rank files; they
are not a calibrated score. Lockfiles, JSON, Markdown and other data are left
out.

## Investigate

The numbers say where to look, not what is wrong. Read the top 3-5 hotspots
(more if the user asks) and look for:

- **Mixed responsibilities**: one function or file doing several unrelated
  jobs; a file that every feature has to touch (god class).
- **Deep nesting**, especially several nested chunks in one function.
- **Long functions** and **long parameter lists**.
- **Duplication**: the same process written twice with one thing varying.
- **Silent failure**: catch-all error handling that swallows the error.
- **Magic numbers** and unexplained literals.
- **A comment block beside a special-case `if`**: usually a separate
  responsibility that wants its own function.

For each coupled pair, work out why they change together: a shared concept
split across files, or one file reaching into the other's details. Coupling
between a module and its test is expected; leave it out.

A hotspot that reads cleanly is fine: frequent change to healthy code is not a
problem. Say so instead of inventing findings.

## Report

Lead with the verdict in a sentence or two, then:

1. **Overview**: the window, commits, and the green/yellow/red counts.
2. **Refactor first**: up to five files, worst first. For each: the numbers
   from the script, what is wrong with a `file:line` reference, and the named
   refactoring that would fix it (Extract Function, Replace Nested Conditional
   with Guard Clauses, Extract Class, Introduce Parameter Object, ...).
3. **Coupling worth acting on**, if any.
4. **Healthy but busy**: hotspots that need no work.
5. **Not measured**: anything the script skipped that matters here, and
   whether function metrics were available.

Report only. Don't refactor anything unless the user asks; when they do, use
the `refactor` skill.
