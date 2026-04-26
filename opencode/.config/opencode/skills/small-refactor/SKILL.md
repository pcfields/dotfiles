---
name: small-refactor
description: Rename symbols, extract functions, inline code, simplify conditionals. Use for small, localized refactors.
keywords:
  - refactor
  - rename
  - extract
  - inline
  - simplify
  - rename function
  - extract method
---

# Small Refactor

Use this skill when performing small, localized refactoring.

## When to Use

- Renaming variables, functions, classes, or files
- Extracting a small pure function from existing logic
- Inlining simple functions
- Simplifying conditionals or boolean expressions
- Reordering parameters

## When NOT to Use

- Large-scale architectural changes
- Cross-module refactoring
- Database schema changes
- API changes that affect consumers

## Workflow

1. Restate the requested refactor and list the exact symbols/files involved
2. Read only the relevant function(s) and immediate context
3. Plan the smallest set of edits needed
4. Apply changes while preserving behavior
5. Show a concise before/after explanation

## Constraints

- Do NOT introduce new dependencies or abstractions
- Do NOT change public APIs or behavior
- Do NOT edit files outside the ones explicitly named
- Preserve existing naming conventions
- Keep changes minimal and reversible