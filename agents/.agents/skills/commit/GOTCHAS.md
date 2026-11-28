# Gotchas

- When committing part of a file in a repo with a lint-staged formatter hook, back up the working file first and diff it after the commit: the hook's restore of unstaged changes can misplace lines when the formatter rewrote a staged hunk.
- When splitting a change into several commits, build each one before making the next: a shared file such as `lib.rs` or a module list can make an early commit name code that only arrives in a later one.
