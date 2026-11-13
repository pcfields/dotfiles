Finished pr-draft output for a personal repo. Copy its shape (title, one-sentence
summary, bold-lead bullets, at most one or two extra sections), not its content.

```
feat(agents): read pr-draft context and overlays from ~/.agents-local
```

```markdown
## Summary

Moves employer-specific PR rules out of this public repo: `pr-draft` now reads
its context and any extra rules from a local folder.

- **Context** comes from the first `contexts.txt` line whose pattern occurs in the origin URL, else `default`.
- **Overlays** are optional: the script prints an `overlay:` line only when that context has a file for the skill.
- **Explicit base** still wins: `branch-state.sh origin/release` skips detection.

## Key decisions

- The folder is plain files outside the repo, not a second repo, so a machine
  without it runs every skill as written.
```
