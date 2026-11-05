Finished pr-draft output for a personal repo. Copy its shape (title, one-sentence
summary, bold-lead bullets, at most one or two extra sections), not its content.

```
feat(agents): detect work vs personal context in pr-draft
```

```markdown
## Summary

Makes `pr-draft` work in personal repos too: a script now picks the base and
rules from the origin URL instead of assuming the work setup.

- **Personal repos** use `origin/HEAD`, then `origin/main`, then `origin/master` as the base.
- **Azure DevOps repos** use `origin/dev` and load `work.md` for the ticket scope and extra sections.
- **Explicit base** still wins: `branch-state.sh origin/release` skips detection.

## Key decisions

- Context comes from the origin URL, matching both `dev.azure.com` and the
  older `visualstudio.com` style, so no per-repo config is needed.
```
