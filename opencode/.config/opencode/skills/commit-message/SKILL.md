---
name: commit-message
description: Generate conventional commit messages based on git diff. Creates small, focused commits following conventional commits spec.
keywords:
  - commit
  - git commit
  - conventional
  - commit message
---

# Commit Message

Use this skill to generate and create git commits.

## When to Use

- Creating commits for changes
- Generating commit messages from diffs

## Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Types

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes nor adds
- `docs`: Documentation only
- `test`: Adding or updating tests
- `chore`: Build, tooling, dependencies
- `style`: Formatting, no code change
- `perf`: Performance improvement
- `ci`: CI configuration changes

## Workflow

1. Run `git status` and `git diff` (and `git diff --cached` if anything is staged) to see all changes.
2. Group the changes by logical concern — feature work, bug fixes, refactors, chores/tooling, docs, tests — even if they touch the same file. An unrelated pre-existing bug fixed along the way is its own commit, not folded into the primary change.
3. If a single file mixes concerns (e.g. `package.json` with both a new dependency and unrelated script fixes), split it: stage/commit an intermediate version for each concern rather than committing it all at once.
4. For each group, determine the type and scope, and write a concise description (under 50 chars).
5. Add a body only if needed for context (the "why", not the "what").
6. Reference issues if applicable (e.g., "Fixes #123").
7. Present the full ordered list of proposed commits before creating any of them.

## Rules

- Use imperative mood: "add" not "added" or "adds"
- Keep first line under 50 characters
- Wrap body at 72 characters
- Reference issues in footer when applicable
- One logical change per commit — never mix feature work, bug fixes, and chores in a single commit just because they touched the same files
- Split proactively; don't wait to be asked to break work into multiple commits