# Refactoring playbook

Recipes that worked in this repo. Read before refactoring; the `refactor`
skill checks here first.

## Characterize an app-hosted Lua config inside the host

**Problem:** a Lua config that only runs inside its host (WezTerm) has no
test runner, and the host hides failures: a config that raises an error
makes `wezterm show-keys` load the defaults and still exit 0.
**Applies when:** the config's behavior lives in event handlers and
callbacks (`wezterm.on`, `wezterm.action_callback`) that only the GUI calls.
**Doesn't apply when:** the logic is already in plain modules with no host
API calls; test those directly.
**Do:**
- Write a runner config and run it with
  `wezterm --config-file tests/run.lua show-keys`. It gets the real
  `wezterm` API, and `os.exit(n)` sets the exit code.
- Before `dofile`-ing the config, replace `wezterm.on`,
  `wezterm.action_callback` and `wezterm.log_error` with functions that
  record what was registered. Tests then call the handlers with fake
  tab, pane and window tables, and replace `wezterm.mux` lookups the same way.
- Count a pass only when the runner's own summary line appears, so a broken
  runner fails too.
- For each step of a move-only refactor, diff a snapshot of
  `wezterm.json_encode(config)` and the `show-keys` output. Sort the
  built-in copy-mode table, whose order changes from run to run. Replace the
  `user-defined-N` callback numbers with one placeholder.
- Assert on the exact format items the handlers return. Splitting a
  `Text` item changes them even when the screen looks the same; the tests
  caught that once.

**First used:** `wezterm/.config/wezterm/tests/`, commit d14ed83; the split
that relied on it ends at d0fdb4f.

## Config slice modules

**Problem:** one long config file where each change means reading
hundreds of lines.
**Applies when:** the config is mostly assignments to one table
(`config.x = ...`).
**Doesn't apply when:** the sections depend on each other's intermediate
state; untangle that first.
**Do:**
- Move each concern into a module that returns a table of settings.
- The entry applies each table with a three-line `apply` loop and then calls
  the event modules' `register()` in the original order.
- Prepend `wezterm.config_dir` to `package.path`, so `--config-file` runs
  and worktrees load their own modules rather than the installed copy.

**First used:** `wezterm/.config/wezterm/`, commits 1df7c4a to b0353ec.
