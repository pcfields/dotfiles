---
name: repo-health
description: Repo health report, code health, hotspots, which files change most, where is the tech debt, what should we refactor first, is this codebase AI-friendly. Investigates a git repo's history and source to rank the most-edited files by complexity, find files that change together, and report overall code health. Use whenever the user asks to assess, audit or investigate a codebase's health or pick refactoring targets.
---

## Measure

Read GOTCHAS.md before step 1.

From the repo, run `code-health repo`. Until it is on PATH, use
`uv run --project ~/.agents/tools/code-health code-health repo`. Options:
`--since "3 months ago"` (default 12 months; use about 1 month for a repo
mostly edited by agents), `--top <n>` rows per table, `--json`, and a path to
limit the report to one directory.

Every run also saves a snapshot and the page data in `.code-health/` at the
repo root, which it keeps out of `git status` through `.git/info/exclude`.

It prints:

- **Overview**: the window, commits, files scored, the green/yellow/red
  counts, average health (weighted by lines), hotspot health (the 10 busiest
  files, weighted by commits) and the worst file.
- **Refactor first**: changed files ranked by commits x (10 - score), with
  the smells found in each. This is where unhealthy code costs the most.
- **Change frequency**: the most-changed files with their scores.
- **Healthy but busy**: frequently changed files scoring 9 or more.
- **Change coupling**: files that keep changing in the same commit.
- **Author density**: files many authors edit. Empty for a solo repo.
- **Least healthy files**: yellow and red files, whether or not they change.
- **Worst findings**: the smells with the biggest penalty, with
  `function:line`, value and limit.
- **Not scored**: files skipped as unsupported, unparseable or excluded.
- **Trend**: earlier runs of the same path and scorer version.

Scores run from 1 to 10 (green 9 and up, yellow 4 and up, red below 4) and
come from the smells tree-sitter finds: Complex Method, Deep Nested
Complexity, Bumpy Road, Complex Conditional, Large Method, Excess Function
Arguments and Large File. They are not yet calibrated against other tools.
`.code-health.toml` at the repo root can exclude paths and change limits or
weights per path; `code-health review <file>` shows one file's findings.

## Investigate

The numbers say where to look, not what is wrong. Read the top 3-5 refactor
targets (more if the user asks) and look for:

- **Mixed responsibilities**: one function or file doing several unrelated
  jobs; a file that every feature has to touch (god class).
- **Deep nesting**, especially several nested chunks in one function.
- **Long functions** and **long parameter lists**.
- **Duplication**: the same process written twice with one thing varying.
- **Silent failure**: catch-all error handling that swallows the error.
- **Magic numbers** and unexplained literals.
- **A comment block beside a special-case `if`**: usually a separate
  responsibility that wants its own function.
- **Tests that mock the repo's own modules** (`vi.mock('./…')`,
  `jest.mock('../…')`): don't dismiss a red test file as mattering less;
  report the mocks as a design smell, since those tests block refactoring.

For each coupled pair, work out why they change together: a shared concept
split across files, or one file reaching into the other's details. Coupling
between a module and its test is expected; leave it out.

A hotspot that reads cleanly is fine: frequent change to healthy code is not a
problem. Say so instead of inventing findings.

## Report

Lead with the verdict in a sentence or two, then:

1. **Overview**: the window, commits, average and hotspot health, the
   green/yellow/red counts, and the trend if there are earlier runs.
2. **Refactor first**: up to five files, worst first. For each: the numbers
   from the tool, what is wrong with a `file:line` reference, and the named
   refactoring that would fix it (Extract Function, Replace Nested Conditional
   with Guard Clauses, Extract Class, Introduce Parameter Object, ...).
3. **Coupling worth acting on**, if any.
4. **Healthy but busy**: hotspots that need no work.
5. **Not measured**: anything under "Not scored" that matters here.

Report only. Don't refactor anything unless the user asks; when they do, use
the `refactor` skill.

## Visual report

After the written report, build the interactive page: a health trend, a
hotspot map (files as circles sized by lines, nested by folder, coloured by
change frequency or score band), a change-coupling wheel, the refactor-first
targets, the branchiest functions and the hotspot ranking.

1. Write `.code-health/repo/findings.json` from the report, in the same words:

   ```json
   {"verdict": "The one- or two-sentence verdict.",
    "targets": [{"path": "repo/relative/path.cs",
                 "issues": ["What is wrong, with `Name` and line numbers."],
                 "fix": "The named refactoring."}]}
   ```

   Targets go worst first. Each `path` must be exactly as the tool printed
   it, or that target is left off the page (the script says how many).
2. From the repo root, run
   `uv run --project ~/.agents/tools/code-health python ~/.agents/skills/repo-health/scripts/build-report.py`
   (any Python 3 works; uv's avoids broken shims). It writes
   `.code-health/repo/report.html`, with the data inlined.
3. Give the user the path. Where the Artifact tool is available, also publish
   that file as a private artifact (icon `chart`). On a later run in the same
   conversation, republish to the same URL. Say that the page is a snapshot of
   this run.

The page loads d3 from cdnjs, so opening the file offline shows no charts.
