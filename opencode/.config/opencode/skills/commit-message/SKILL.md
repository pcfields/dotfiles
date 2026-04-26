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

1. Run `git status` and `git diff` to see changes
2. Determine the type and scope
3. Write a concise description (under 50 chars)
4. Add body only if needed for context
5. Reference issues if applicable (e.g., "Fixes #123")

## Rules

- Use imperative mood: "add" not "added" or "adds"
- Keep first line under 50 characters
- Wrap body at 72 characters
- Reference issues in footer when applicable
- One logical change per commit