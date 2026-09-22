# WezTerm Config Improvements — Work Order

> A scoped, executable work order for `wezterm/.wezterm.lua`, written to be handed
> to an AI agent. It covers correctness fixes and low-risk workflow additions only.
> Larger architectural changes are listed under "Out of scope" and must not be
> attempted as part of this work.

Target file: `wezterm/.wezterm.lua` (single file; symlinked by
`install/stow-dotfiles.sh` on Linux and `install/windows/setup-windows-symlinks.ps1:50`
on Windows — no install-script changes are needed for this work).

Pinned WezTerm version: **20240203-110809-5046fc22**. Every API used below was
verified against that build. Do not substitute newer APIs.

## Before you start

1. **`AGENTS.md` requires confirmation before making changes**, even obvious ones.
   Present the diff for a task and get an explicit go-ahead before applying it.
2. **This file is indented with TABS.** Match it.
3. **Do not run `stylua` on this file.** The only stylua config in the repo
   (`nvim/.config/nvim/.stylua.toml`) is scoped to the Neovim package and specifies
   2-space indentation. Running it here reformats all ~490 lines and destroys the
   diff. It will also collapse the deliberate column alignment at lines 386-389.
4. **Keep the existing structure.** The file is organized into banner-delimited
   "modules" (`-- ===== PLATFORM MODULE =====` etc). Add to the relevant existing
   module; do not introduce new top-level sections unless a task says to.
5. **Follow the repo's coding principles** (`CLAUDE.md`): keep pure calculations
   separate from actions, pass data as arguments, small single-purpose functions.
   Several tasks below are specified that way deliberately.
6. Work one task at a time and commit per the plan at the end. Do not batch
   everything into one commit.

## Verifying each change

The config parses in a subprocess without touching the running terminal:

```bash
cd ~/dotfiles
wezterm --config-file wezterm/.wezterm.lua show-keys    # exit 0 == config parses
```

`show-keys` prints the resolved leader, key tables, and every binding, so it also
confirms new keys landed and nothing collides. For runtime behavior, reload a live
window with `CTRL+SHIFT+R`.

After each task: run `show-keys`, confirm exit 0, and grep its output for whatever
the task added.

---

## Task 1 — Rebuild the project list on demand (bug)

**Problem.** At line 386 the action is `display_project_list()` — note the call
parentheses. It executes once, when the config parses, so `wezterm.glob` runs at
load time and the `choices` list is baked in. A repo cloned after startup does not
appear in `LEADER+p` until the config reloads. It also puts a `read_dir` call per
candidate directory (`project_utils.is_folder`, line 146) on the config-load path.

**Change.** Defer it to keypress time:

```lua
	{
		mods = "LEADER",
		key = "p",
		action = wezterm.action_callback(function(child_window, child_pane)
			child_window:perform_action(display_project_list(), child_pane)
		end),
	},
```

**Verify.** `show-keys` still lists a `LEADER p` binding. Create a new directory
under a scanned root, press `LEADER+p` without reloading, confirm it appears.

---

## Task 2 — Stop workspace names from colliding (bug)

**Problem.** In the `InputSelector` callback (lines 272-286):

```lua
	local directory_name = label:match("([^/]+)$") -- get last segment of directory path
```

The comment is wrong: this matches against `label`, not the path. For globbed
entries the label is already a bare folder name, so the match is a no-op; for
manual entries it yields display text with spaces (`My Project`) as a
workspace name. The real bug is that two projects sharing a folder name under
different roots produce the *same* workspace name, so opening the second one
silently switches to the first one's workspace instead of opening it.

**Change.** Add two pure functions to the `PROJECT UTILITIES MODULE`:

```lua
project_utils.workspace_name = function(label)
	-- Workspace names are identifiers, not display text. Extra parens discard
	-- gsub's second return value (the substitution count).
	return (label:gsub("%s+", "-"))
end

project_utils.disambiguate_labels = function(projects_list)
	local counts = {}
	for _, project in ipairs(projects_list) do
		counts[project.label] = (counts[project.label] or 0) + 1
	end

	for _, project in ipairs(projects_list) do
		if counts[project.label] > 1 then
			local parent = project.id:match("([^/\\]+)[/\\][^/\\]+$")
			if parent then
				project.label = parent .. "/" .. project.label
			end
		end
	end

	return projects_list
end
```

In `display_project_list`, run the disambiguation pass after the list is populated
and before building the selector:

```lua
	project_utils.disambiguate_labels(projects_list)
```

then derive the workspace name from the label:

```lua
	child_window:perform_action(
		wezterm.action.SwitchToWorkspace({
			name = project_utils.workspace_name(label),
			spawn = { label = "Workspace: " .. label, cwd = id },
		}),
		child_pane
	)
```

Delete the now-unused `directory_name` line and its incorrect comment.

**Verify.** Two directories with the same basename under different scanned roots
both appear in `LEADER+p`, distinguished by parent, and each opens its own
workspace. Check the workspace name in the status bar contains no spaces.

---

## Task 3 — Honor `exclude` for every project source (bug)

**Problem.** `profile.exclude` is threaded only into `add_directory_glob`
(line 237). `add_manual_projects` and `add_project_folders` ignore it, so an
exclusion added for a `folders`-sourced or manual project silently does nothing.

**Change.** Extract the exclusion predicate now that it is needed in more than one
place (this satisfies "extract only when a pattern actually repeats"):

```lua
project_utils.is_excluded = function(path, exclude_list)
	local normalized = project_utils.normalize_path(path)

	for _, excluded_path in ipairs(exclude_list or {}) do
		if normalized == project_utils.normalize_path(excluded_path) then
			return true
		end
	end

	return false
end
```

Rewrite `project_utils.add_paths_to_list` to call it instead of its inline loop.
Then thread `exclude` through the two builders that drop it:

- `add_manual_projects(projects_list, projects, exclude)` — skip any project whose
  `path` is excluded.
- `add_project_folders(projects_list, root_path, folders, exclude)` — pass
  `exclude = exclude` in the `add_paths_to_list` options table.
- `populate_from_profile` — pass `profile.exclude` to both.

**Verify.** Add a temporary `exclude` entry for a project that reaches the list via
`folders`, confirm it disappears from `LEADER+p`, then remove the temporary entry.

---

## Task 4 — Remove the no-op status bar attribute (dead code)

**Problem.** `status_bar.format_workspace_section` ends (line 460) with
`{ Background = { Color = colors.background } }` after the powerline arrow. No text
follows it, so it paints nothing — it is a leftover, and it is confusing sitting
next to the deliberate `"ResetAttributes"`.

**Change.** Delete that final table entry. Leave the rest of the function alone.

**Verify.** Status bar renders identically: leader dots, magenta workspace segment,
arrow, nothing trailing.

---

## Task 5 — Add scrollback search and raise the buffer (feature)

**Problem.** Copy mode (`LEADER+y`) and QuickSelect (`LEADER+f`) are bound, but
nothing is bound to `Search` — the action you actually want when hunting through
build or test output. `scrollback_lines = 10000` (line 329) is also low for MSBuild
and test-runner output.

**Change.** `/` is unused as a leader key. Add to `config.keys`, in the
"Copy Mode and Scrolling" group:

```lua
	{ mods = "LEADER", key = "/", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },
```

And raise the buffer:

```lua
config.scrollback_lines = 50000
```

**Verify.** `show-keys | grep -i search` shows the binding. `LEADER+/` opens the
search overlay and prefills from the current selection when there is one.

---

## Task 6 — Give QuickSelect useful patterns (feature)

**Problem.** `LEADER+f` runs QuickSelect with only the built-in patterns, so it
mostly offers URLs. Adding patterns turns it into a two-keystroke "yank the SHA" or
"grab the file:line".

**Change.** `quick_select_patterns` is **additive** — the built-in patterns still
apply. These are Rust regex strings in Lua literals, so backslashes are doubled:

```lua
config.quick_select_patterns = {
	"[0-9a-f]{7,40}", -- git object hashes
	"[^\\s'\"]+:\\d+(:\\d+)?", -- file:line and file:line:col from compilers and stack traces
	"\\b\\d{1,3}(\\.\\d{1,3}){3}\\b", -- IPv4
	"[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}", -- UUID
}
```

Place it near the `Scrollback` / `Window behavior` settings in the
`APPLY CONFIGURATION` section.

**Verify.** Run `git log --oneline`, press `LEADER+f`, confirm short SHAs get
labels. Trigger a compiler error and confirm the `file:line` span is selectable.

---

## Task 7 — Informative tab titles (feature)

**Problem.** `hide_tab_bar_if_only_one_tab = false` keeps the tab bar permanently
visible, but tabs label themselves from the foreground process, so several project
shells look identical. With `lazygit` and `opencode` tabs in the mix this is the
main thing making the bar hard to scan.

**Change.** Add a `TAB TITLE MODULE` banner section next to the `STATUS BAR MODULE`,
keeping calculations pure and the event registration separate:

```lua
local tab_title = {}

tab_title.shells = {
	pwsh = true,
	powershell = true,
	fish = true,
	bash = true,
	zsh = true,
	cmd = true,
	nu = true,
}

tab_title.process_name = function(pane)
	local base = (pane.foreground_process_name or ""):match("([^/\\]+)$")
	if not base then
		return nil
	end

	return (base:gsub("%.exe$", ""))
end

tab_title.cwd_basename = function(pane)
	local cwd = pane.current_working_dir
	if not cwd then
		return nil
	end

	-- 20240203 exposes current_working_dir as a Url object, not a string.
	local path = cwd.file_path or tostring(cwd)
	return path:gsub("[/\\]+$", ""):match("([^/\\]+)$")
end

tab_title.describe = function(tab)
	if tab.tab_title and tab.tab_title ~= "" then
		return tab.tab_title
	end

	local pane = tab.active_pane
	local process = tab_title.process_name(pane)

	-- A shell tells you nothing; where it is does. A tool names itself.
	if not process or tab_title.shells[process:lower()] then
		return tab_title.cwd_basename(pane) or process or pane.title
	end

	return process
end

tab_title.register = function()
	wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
		local text = " " .. (tab.tab_index + 1) .. ": " .. tab_title.describe(tab) .. " "
		return wezterm.truncate_right(text, max_width)
	end)
end

tab_title.register()
```

Note: the `label` passed to `SpawnCommandInNewTab` (line 63) sets the *launcher
menu* label, not the tab title, so `lazygit` and `opencode` tabs will be named by
their process — which is the desired result here.

**Verify.** Open a project shell tab (shows the directory name), a `LEADER+g`
lazygit tab (shows `lazygit`), and confirm both are prefixed `1:`, `2:`, and that
long names truncate rather than overflow.

---

## Task 8 — Small polish (feature + chore)

Each of these is independent; apply them together but split the commit as noted.

**8a. Workspace and tab movement keys.** Workspaces are used heavily but only
reachable through the fuzzy launcher (`LEADER+w`), and there is no way to reorder
tabs. Free leader keys: `n`, `b`. Add to `config.keys`:

```lua
	{ mods = "LEADER",       key = "n", action = wezterm.action.SwitchWorkspaceRelative(1) },
	{ mods = "LEADER",       key = "b", action = wezterm.action.SwitchWorkspaceRelative(-1) },
	{ mods = "LEADER|SHIFT", key = "o", action = wezterm.action.MoveTabRelative(1) },
	{ mods = "LEADER|SHIFT", key = "i", action = wezterm.action.MoveTabRelative(-1) },
```

`LEADER|SHIFT+o/i` deliberately mirrors the existing `LEADER+o/i` tab *activation*
pair. Confirm with `show-keys` that none of these collide.

**8b. Platform-aware font size.** `font_size = 10.0` is hardcoded (line 76) and will
not suit a HiDPI Linux display. Move it into the platform module:

```lua
platform.font_size = platform.is_windows and 10.0 or 11.0
```

and have `ui_config.font_size` read `platform.font_size`. Ask the user for their
preferred Linux value rather than assuming 11.0.

**8c. Disable the audible bell.**

```lua
config.audible_bell = "Disabled"
```

**8d. Restore missing-glyph warnings.** `warn_about_missing_glyphs = false`
(line 317) suppresses a genuinely useful diagnostic. It was verified that the
current font stack resolves all glyphs in use (see "Verified, no action needed"),
so the warning should be quiet in practice. Delete the line — `true` is the default.
If it turns out to be noisy in daily use, revert this one item only.

**Verify.** `show-keys` exit 0 and the four new bindings present; reload and confirm
no glyph warning appears in a normal session.

---

## Commit plan

Per `CLAUDE.md`: small commits, conventional prefixes, split by *type* of work, no
`Co-Authored-By` trailers.

| # | Message | Contents |
|---|---|---|
| 1 | `docs(wezterm): add config improvement work order` | this file |
| 2 | `fix(wezterm): rebuild project list on demand` | Task 1 |
| 3 | `fix(wezterm): stop workspace names from colliding` | Task 2 |
| 4 | `fix(wezterm): honor project exclude list for all sources` | Task 3 |
| 5 | `refactor(wezterm): drop no-op status bar background attribute` | Task 4 |
| 6 | `feat(wezterm): add scrollback search and quick select patterns` | Tasks 5, 6 |
| 7 | `feat(wezterm): show tab index and context in tab titles` | Task 7 |
| 8 | `feat(wezterm): add workspace switching and tab movement keys` | Task 8a |
| 9 | `chore(wezterm): platform font size, quiet bell, glyph warnings` | Tasks 8b-8d |

Commits 2-4 are all `fix:` but are separate logical changes; keep them apart. If a
task turns out to be larger than expected, stop and report rather than folding it
into an adjacent commit.

## Definition of done

There is no test suite — this repo is validated by re-running the relevant step
(`CLAUDE.md`). For this work that means:

1. `wezterm --config-file wezterm/.wezterm.lua show-keys` exits 0.
2. A live window reloaded with `CTRL+SHIFT+R` shows no config error.
3. Each task's own Verify step performed manually.
4. Run the `code-review` skill (medium effort) on the full diff before handing
   back, and report what was addressed vs. deliberately left.

## Out of scope

Do not attempt these as part of this work order. They are real improvements, but
they change startup behavior, add dependencies, or touch the install scripts, and
each needs its own discussion first.

- **Local unix domain** (`unix_domains` plus `default_gui_startup_args`) so shells
  and builds survive the GUI restarting. The largest single workflow gain
  available, and the one thing this config lacks versus tmux.
- **`resurrect.wezterm`** for saving and restoring workspace layouts across reboots.
- **`smart-splits.nvim`** wezterm plugin for seamless `CTRL+h/j/k/l` traversal
  between Neovim splits and WezTerm panes.
- **Workspace launch layouts** — making `LEADER+p` spawn an editor pane, a shell,
  and a lazygit tab instead of a single pane.
- **`hyperlink_rules`** for clickable ticket and PR references. Blocked on the
  local-private extraction below, since the URLs are employer-specific.
- **`wezterm/local-private.lua`** (untracked, mirroring the existing
  `powershell/local-private.ps1` pattern) for employer-specific config such as
  the hyperlink rules above. The work profile no longer pins individual
  projects, so no employer project paths are committed; it only scans the
  `C:/Projects` root.
- **Splitting the file into modules** under `wezterm/.config/wezterm/`, mirroring
  the Neovim `lua/pcf/` layout. The eight `=====` banner comments are doing the job
  real files should. Requires a change to the Windows symlink script.
- **Profile selection keyed on platform** (line 262) — Linux can never see work
  projects and Windows can never see personal ones. Should key on hostname or an
  env var instead.

## Verified, no action needed

Recorded so these are not re-raised:

- **Nerd Font glyphs are fine.** `Monaspace Neon` and `JetBrains Mono` are not
  patched Nerd Fonts, which looks like a bug, but WezTerm appends its own built-in
  `Symbols Nerd Font Mono` to every fallback chain. Confirmed with
  `wezterm ls-fonts --text ...`: the powerline arrow is drawn by WezTerm itself
  (`custom_block_glyphs`), and devicons resolve to
  `Symbols Nerd Font Mono, <built-in>`. Oh My Posh renders correctly. No third
  fallback family is needed.
