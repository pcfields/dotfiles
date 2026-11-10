# Gotchas

- When committing part of a file in a repo with a lint-staged formatter hook, back up the working file first and diff it after the commit: the hook's restore of unstaged changes can misplace lines when the formatter rewrote a staged hunk.
