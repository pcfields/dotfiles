# Gotchas

- Global `submodule.recurse=true` makes `git grep --untracked` fail ("no source files"): run with `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=submodule.recurse GIT_CONFIG_VALUE_0=false`.
- Under mise, `python`/`python3` for `build-report.py` may point at a version that isn't installed ("Failed to install core:python"): run it with `/usr/bin/python3` (stdlib only).
- Under mise, `lizard` may only exist for another Python (e.g. "lizard is not provided by the active python@3.15"): wrap the run in `mise exec python@<version that has it> -- bash ...`.
- Don't dismiss red test files as "mattering less": grep hotspot tests for mocks of the repo's own modules (`vi.mock('./…')`, `jest.mock('../…')`) and report it as a design smell, since those tests block refactoring.
