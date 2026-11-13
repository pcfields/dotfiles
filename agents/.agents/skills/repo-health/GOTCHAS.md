# Gotchas

- Global `submodule.recurse=true` makes `git grep --untracked` fail ("no source files"): run with `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=submodule.recurse GIT_CONFIG_VALUE_0=false`.
- Under mise, `lizard` may only exist for another Python (e.g. "lizard is not provided by the active python@3.15"): wrap the run in `mise exec python@<version that has it> -- bash ...`.
