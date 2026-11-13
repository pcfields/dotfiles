Finished pr-draft output. Copy its shape (title, one-sentence summary,
bold-lead bullets, at most one or two extra sections), not its content.

```
feat(cart): keep the cart when a session expires
```

```markdown
## Summary

Keeps a shopper's cart when their session expires, so signing back in restores
it.

- **Expired sessions** save the cart against the account before sign-out.
- **Signing in** merges the saved cart with anything added while signed out.
- **Quantities** are capped at current stock when the two carts merge.

## Not included

- Guest carts: `POST /cart/merge` needs an account id, so they are still
  emptied.
```
