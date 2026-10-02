local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- ============================================================================
-- PLATFORM MODULE
-- ============================================================================

local platform = {
	is_windows = wezterm.target_triple:find("windows") ~= nil,
}

platform.shell = platform.is_windows and "pwsh.exe" or (os.getenv("SHELL") or "/usr/bin/fish")

platform.home_dir = wezterm.home_dir

platform.font_size = platform.is_windows and 10.5 or 11.0

-- ============================================================================
-- KEYMAP BUILDERS MODULE
-- ============================================================================

local keymap_builders = {}

keymap_builders.resize_pane = function(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize({ direction, 3 }),
	}
end

keymap_builders.split_pane = function(key, direction)
	return {
		key = key,
		action = wezterm.action.SplitPane({ direction = direction, size = { Percent = 40 } }),
	}
end

keymap_builders.go_to_tab = function(tab_number)
	return {
		mods = "LEADER",
		key = tostring(tab_number),
		action = wezterm.action.ActivateTab(tab_number - 1),
	}
end

-- Pure: the default copy mode keys with `y` also clearing the selection. The
-- built-in `y` copies and closes copy mode but leaves the text highlighted.
keymap_builders.copy_mode_keys = function(default_keys)
	local keys = {}

	for _, binding in ipairs(default_keys) do
		-- The default tables spell keys as "mapped:<char>"
		if binding.key == "mapped:y" and binding.mods == "NONE" then
			table.insert(keys, {
				key = binding.key,
				mods = binding.mods,
				action = wezterm.action.Multiple({
					wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
					wezterm.action.ClearSelection,
					wezterm.action.CopyMode("Close"),
				}),
			})
		else
			table.insert(keys, binding)
		end
	end

	return keys
end

-- ============================================================================
-- COMMAND SPAWNERS MODULE
-- ============================================================================

local command_spawners = {}

command_spawners.spawn_tool = function(label, command)
	local args
	if platform.is_windows then
		args = { "pwsh.exe", "-Command", command .. "; if (-not $?) { Read-Host 'Press enter to exit...' }" }
	elseif platform.shell:find("fish") then
		args = { platform.shell, "-c", command .. "; or read -P 'Press enter to exit...'" }
	else
		-- bash
		args = { platform.shell, "-c", command .. ' || read -p "Press enter to exit..."' }
	end
	return wezterm.action.SpawnCommandInNewTab({
		label = label,
		args = args,
	})
end

-- ============================================================================
-- UI CONFIGURATION MODULE
-- ============================================================================

-- Rosé Pine Moon palette (https://rosepinetheme.com/palette), named so the
-- tab bar and status bar can match the terminal's color scheme.
local palette = {
	base = "#232136",
	surface = "#2a273f",
	overlay = "#393552",
	muted = "#6e6a86",
	subtle = "#908caa",
	text = "#e0def4",
	gold = "#f6c177",
	iris = "#c4a7e7",
	love = "#eb6f92",
	foam = "#9ccfd8",
	-- Darker than the tab bar so the right status reads as recessed
	void = "#15131f",
}

-- ============================================================================
-- PROJECT PICKER
-- ============================================================================

local project_profiles = {
	work = {
		root = "C:/Projects",
	},
	personal = {
		root = platform.home_dir .. "/ws",
		folders = { "scratchpad", "learn", "personal", "clients" },
	},
}

local function is_folder(path)
	-- read_dir only succeeds on directories
	return (pcall(wezterm.read_dir, path))
end

-- Lists the directories directly under `directory`. The label is prefixed so
-- same-named projects in different folders stay distinct (and get distinct
-- workspace names).
local function subdirectories(directory, label_prefix)
	local projects = {}

	for _, path in ipairs(wezterm.glob(directory .. "/*")) do
		if is_folder(path) then
			table.insert(projects, { id = path, label = label_prefix .. path:match("([^/\\]+)$") })
		end
	end

	return projects
end

local function build_project_list(profile)
	local projects = { { id = platform.home_dir .. "/dotfiles", label = "dotfiles" } }

	local function add_from(directory, label_prefix)
		for _, project in ipairs(subdirectories(directory, label_prefix)) do
			table.insert(projects, project)
		end
	end

	if profile.folders then
		for _, folder in ipairs(profile.folders) do
			add_from(profile.root .. "/" .. folder, folder .. "/")
		end
	else
		add_from(profile.root, "")
	end

	return projects
end

local function display_project_list()
	local profile = platform.is_windows and project_profiles.work or project_profiles.personal

	return wezterm.action.InputSelector({
		title = "Choose a project",
		choices = build_project_list(profile),
		fuzzy = true,
		action = wezterm.action_callback(function(child_window, child_pane, id, label)
			if not label then
				return
			end

			child_window:perform_action(
				wezterm.action.SwitchToWorkspace({
					name = label,
					spawn = { label = "Workspace: " .. label, cwd = id },
				}),
				child_pane
			)
		end),
	})
end

-- ============================================================================
-- WORKSPACE HISTORY
-- ============================================================================

-- WezTerm has no "previous workspace", so remember it. The history is a plain
-- table { current = "a", previous = "b" } kept in wezterm.GLOBAL.

local workspace_history = {}

-- Pure: the history after `active` becomes the current workspace.
workspace_history.observe = function(history, active)
	if history.current == active then
		return history
	end

	return { current = active, previous = history.current }
end

-- Pure: where "go back" should land. Nil when there is no previous workspace
-- or it no longer exists, since switching to a missing name would create an
-- empty workspace.
workspace_history.back_target = function(history, workspace_names)
	for _, name in ipairs(workspace_names) do
		if name == history.previous then
			return name
		end
	end

	return nil
end

workspace_history.read = function()
	return wezterm.GLOBAL.workspace_history or {}
end

workspace_history.switch_back = wezterm.action_callback(function(window, pane)
	local history = workspace_history.read()
	local target = workspace_history.back_target(history, wezterm.mux.get_workspace_names())
	if not target then
		return
	end

	-- Record the swap now so pressing the key twice quickly still toggles
	wezterm.GLOBAL.workspace_history = workspace_history.observe(history, target)
	window:perform_action(wezterm.action.SwitchToWorkspace({ name = target }), pane)
end)

-- Every way of switching workspace (picker, launcher, cycle keys) passes
-- through here, so none needs wrapping.
workspace_history.register = function()
	wezterm.on("update-status", function(window)
		wezterm.GLOBAL.workspace_history = workspace_history.observe(workspace_history.read(), window:active_workspace())
	end)
end

workspace_history.register()

-- ============================================================================
-- APPLY CONFIGURATION
-- ============================================================================

-- Shell and Working Directory
config.default_cwd = platform.home_dir
config.default_prog = { platform.shell }

-- UI Settings
-- The built-in scheme leaves the tab bar in WezTerm's default greys, so
-- register a copy of it with tab colors taken from the same palette.
local color_scheme = "rose-pine-moon"
local scheme = wezterm.color.get_builtin_schemes()[color_scheme]
scheme.tab_bar = {
	inactive_tab_edge = palette.overlay,
	active_tab = { bg_color = palette.overlay, fg_color = palette.text },
	inactive_tab = { bg_color = palette.base, fg_color = palette.muted },
	inactive_tab_hover = { bg_color = palette.surface, fg_color = palette.subtle },
	new_tab = { bg_color = palette.base, fg_color = palette.muted },
	new_tab_hover = { bg_color = palette.surface, fg_color = palette.text },
}
-- The built-in selection is a faint fill that barely differs from the
-- background; a solid iris block with dark text is clearly visible.
scheme.selection_bg = palette.iris
scheme.selection_fg = palette.base
config.color_schemes = { [color_scheme .. "-tabs"] = scheme }
config.color_scheme = color_scheme .. "-tabs"

-- Tab bar font and background (the fancy tab bar draws these separately
-- from the terminal font)
config.window_frame = {
	font = wezterm.font({ family = "Monaspace Neon", weight = "DemiBold" }),
	font_size = 12.0,
	active_titlebar_bg = palette.base,
	inactive_titlebar_bg = palette.base,
	button_fg = palette.subtle,
	button_bg = palette.base,
	button_hover_fg = palette.text,
	button_hover_bg = palette.overlay,
}
config.font_size = platform.font_size
local no_ligatures = { "calt=0", "clig=0", "liga=0" }
config.font = wezterm.font_with_fallback({
	{ family = "Monaspace Neon", weight = "Regular", harfbuzz_features = no_ligatures },
	{ family = "JetBrains Mono", weight = "Regular", harfbuzz_features = no_ligatures },
})
-- Window buttons live in the tab bar instead of an OS title bar
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.tab_max_width = 32
config.inactive_pane_hsb = { saturation = 0.5, brightness = 0.4 }

-- Performance Settings
config.max_fps = 120
config.animation_fps = 120
config.front_end = "OpenGL" -- WebGpu flickers on Linux

-- Scrollback
config.scrollback_lines = 50000

-- Window behavior
config.window_close_confirmation = "AlwaysPrompt"
config.audible_bell = "Disabled"

config.mouse_bindings = {
	-- Change the default click behavior so that it only selects
	-- text and doesn't open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	},

	-- Bind 'Up' event of CTRL-Click to open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- Disable the 'Down' event of CTRL-Click to avoid weird program behaviors
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.Nop,
	},
}

-- Key Tables
config.key_tables = {
	copy_mode = keymap_builders.copy_mode_keys(wezterm.gui.default_key_tables().copy_mode),
	resize_panes = {
		keymap_builders.resize_pane("j", "Down"),
		keymap_builders.resize_pane("k", "Up"),
		keymap_builders.resize_pane("h", "Left"),
		keymap_builders.resize_pane("l", "Right"),
	},
	split_panes = {
		keymap_builders.split_pane("j", "Down"),
		keymap_builders.split_pane("k", "Up"),
		keymap_builders.split_pane("h", "Left"),
		keymap_builders.split_pane("l", "Right"),
	},
}

config.leader = {
	key = "Space",
	mods = "SHIFT",
	timeout_milliseconds = 2000,
}

-- Keybindings
config.keys = {
	-- Projects and Tools
	{ -- [F]ind project
		mods = "LEADER|SHIFT",
		key = "F",
		action = wezterm.action_callback(function(child_window, child_pane)
			child_window:perform_action(display_project_list(), child_pane)
		end),
	},
	{ mods = "LEADER", key = "g", action = command_spawners.spawn_tool("LazyGit", "lazygit") },
	{ mods = "LEADER", key = ";", action = command_spawners.spawn_tool("Claude", "claude") },
	{ mods = "LEADER", key = "f", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ mods = "LEADER", key = ".", action = wezterm.action.SwitchWorkspaceRelative(1) },
	{ mods = "LEADER", key = ",", action = wezterm.action.SwitchWorkspaceRelative(-1) },
	{ mods = "LEADER", key = "w", action = workspace_history.switch_back }, -- [w]orkspace: back to the last one

	-- Pane Management
	{ -- [s]plit pane
		mods = "LEADER",
		key = "s",
		action = wezterm.action.ActivateKeyTable({
			name = "split_panes",
			one_shot = false,
			timeout_milliseconds = 1000,
		}),
	},
	{ mods = "LEADER", key = "z", action = wezterm.action.TogglePaneZoomState },
	{ mods = "LEADER", key = "'", action = wezterm.action.RotatePanes("Clockwise") },
	{ mods = "LEADER", key = "m", action = wezterm.action.PaneSelect({ mode = "Activate" }) },
	{ mods = "LEADER|SHIFT", key = "M", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },

	{ mods = "LEADER", key = "h", action = wezterm.action.ActivatePaneDirection("Left") },
	{ mods = "LEADER", key = "j", action = wezterm.action.ActivatePaneDirection("Down") },
	{ mods = "LEADER", key = "k", action = wezterm.action.ActivatePaneDirection("Up") },
	{ mods = "LEADER", key = "l", action = wezterm.action.ActivatePaneDirection("Right") },
	{ -- [r]esize panes
		mods = "LEADER",
		key = "r",
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			one_shot = false,
			timeout_milliseconds = 1000,
		}),
	},

	-- Tab Management
	{ mods = "LEADER", key = "t", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "LEADER|SHIFT", key = "X", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "LEADER", key = "x", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER", key = "o", action = wezterm.action.ActivateTabRelative(1) },
	{ mods = "LEADER", key = "i", action = wezterm.action.ActivateTabRelative(-1) },
	{ mods = "LEADER|SHIFT", key = "O", action = wezterm.action.MoveTabRelative(1) },
	{ mods = "LEADER|SHIFT", key = "I", action = wezterm.action.MoveTabRelative(-1) },
	{ mods = "LEADER", key = "a", action = wezterm.action.ActivateLastTab }, -- [a]lternate tab
	keymap_builders.go_to_tab(1),
	keymap_builders.go_to_tab(2),
	keymap_builders.go_to_tab(3),
	keymap_builders.go_to_tab(4),
	keymap_builders.go_to_tab(5),
	keymap_builders.go_to_tab(6),

	-- Copy Mode and Scrolling
	{ mods = "LEADER", key = "y", action = wezterm.action.ActivateCopyMode },
	{ mods = "LEADER", key = "c", action = wezterm.action.QuickSelect },
	{ mods = "LEADER", key = "u", action = wezterm.action.ScrollByPage(-1) },
	{ mods = "LEADER", key = "d", action = wezterm.action.ScrollByPage(1) },
	{ mods = "LEADER", key = "?", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },
}

-- ============================================================================
-- TAB TITLE MODULE
-- ============================================================================

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

-- WezTerm defaults a pane's title to its foreground process name until the
-- running program sets its own via an OSC escape sequence (lazygit, vim,
-- etc. do this). If the title doesn't match that default, trust it — this
-- also covers cases like Windows spawning a tool through an intermediate
-- shell (`pwsh -NoExit -Command lazygit`), where process detection only
-- ever sees "pwsh" but the tool has still announced its own title.
tab_title.looks_like_default_title = function(title, process, cwd_basename)
	if not title or title == "" then
		return true
	end

	local lowered = title:lower()

	-- A bare path: fish's idle title on Linux (`~/dotfiles`), or the
	-- executable path Windows consoles fall back to (`C:\...\cmd.exe`).
	if lowered:match("^[~/]") or lowered:match("^%a:\\") then
		return true
	end

	-- fish titles a running command as `<command> <cwd>`.
	local first_word = lowered:match("^(%S+)")
	if process and first_word == process:lower() then
		return true
	end

	if cwd_basename and lowered == cwd_basename:lower() then
		return true
	end

	return tab_title.shells[lowered] or false
end

-- Tools like lazygit title themselves "<repo> - <tool>". The location is
-- already on the workspace badge, so keep just the tool.
tab_title.strip_location_prefix = function(title, cwd_basename)
	if not cwd_basename then
		return title
	end

	local prefix = cwd_basename:lower() .. " - "
	if title:sub(1, #prefix):lower() == prefix and #title > #prefix then
		return title:sub(#prefix + 1)
	end

	return title
end

tab_title.describe = function(tab)
	if tab.tab_title and tab.tab_title ~= "" then
		return tab.tab_title
	end

	local pane = tab.active_pane
	local process = tab_title.process_name(pane)
	local cwd = tab_title.cwd_basename(pane)

	if not tab_title.looks_like_default_title(pane.title, process, cwd) then
		return tab_title.strip_location_prefix(pane.title, cwd)
	end

	-- A shell tells you nothing; where it is does. A tool names itself.
	if not process or tab_title.shells[process:lower()] then
		return cwd or process or pane.title
	end

	return process
end

tab_title.color = function(is_active, hover)
	if is_active then
		return palette.text
	end

	return hover and palette.subtle or palette.muted
end

tab_title.max_pips = 4

-- Pure: one pip per pane, so a count never reads as a second tab number.
-- Past the cap the rest collapse into a "+".
tab_title.pips = function(pane_count)
	local shown = math.min(pane_count, tab_title.max_pips)
	return ("▪"):rep(shown) .. (pane_count > shown and "+" or "")
end

-- Pure: small markers after the title, in order: zoom, then one pip per pane
-- (only when split).
tab_title.indicators = function(state)
	local pieces = {}

	if state.zoomed then
		table.insert(pieces, { text = "ZOOM", color = palette.love, bold = true })
	end

	if state.pane_count > 1 then
		table.insert(pieces, { text = tab_title.pips(state.pane_count), color = palette.subtle })
	end

	return pieces
end

tab_title.read_state = function(panes)
	local state = { pane_count = #panes, zoomed = false }

	for _, pane in ipairs(panes) do
		state.zoomed = state.zoomed or pane.is_zoomed
	end

	return state
end

tab_title.register = function()
	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		-- The handler's own `panes` argument covers only the active tab, so
		-- ask the mux for this tab's panes.
		local mux_tab = wezterm.mux.get_tab(tab.tab_id)
		local panes = mux_tab and mux_tab:panes_with_info() or {}
		local indicators = tab_title.indicators(tab_title.read_state(panes))

		-- Reserve room for the number and the indicators; only the title is
		-- truncated, so neither is ever cut off.
		local number = " " .. (tab.tab_index + 1) .. ":"
		local reserved = wezterm.column_width(number)
		for _, piece in ipairs(indicators) do
			reserved = reserved + wezterm.column_width(piece.text) + 1
		end
		local title = wezterm.truncate_right(" " .. tab_title.describe(tab) .. " ", math.max(0, max_width - reserved))

		-- ResetAttributes does not restore the tab bar colors here, so the
		-- title color is set explicitly (these match scheme.tab_bar).
		local items = {
			{ Foreground = { Color = palette.iris } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = number },
			{ Attribute = { Intensity = "Normal" } },
			{ Foreground = { Color = tab_title.color(tab.is_active, hover) } },
			{ Text = title },
		}

		for _, piece in ipairs(indicators) do
			table.insert(items, { Foreground = { Color = piece.color } })
			table.insert(items, { Attribute = { Intensity = piece.bold and "Bold" or "Normal" } })
			table.insert(items, { Text = piece.text .. " " })
		end

		return items
	end)
end

tab_title.register()

-- ============================================================================
-- STATUS BAR MODULE
-- ============================================================================

local status_bar = {}

status_bar.colors = {
	text = palette.base,
	background = palette.iris,
	-- The workspace badge turns this color while the leader key is active
	leader_background = palette.gold,
	-- Background of each right status box
	box = palette.void,
}

status_bar.badge_background = function(window)
	if window:leader_is_active() then
		return status_bar.colors.leader_background
	end

	return status_bar.colors.background
end

status_bar.format_workspace_section = function(window)
	local colors = status_bar.colors
	local background = status_bar.badge_background(window)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = colors.text } },
		{ Text = " " .. wezterm.nerdfonts.cod_layers .. " " .. window:mux_window():get_workspace() .. "  " },
		"ResetAttributes",
		-- Gap and glyph sit on the bar color; the default background renders grey
		{ Background = { Color = palette.base } },
		{ Text = " " },
		{ Foreground = { Color = background } },
		{ Text = " 󰗘 " },
	}
end

status_bar.key_table_labels = {
	split_panes = "SPLIT",
	resize_panes = "RESIZE",
	copy_mode = "COPY",
	search_mode = "SEARCH",
}

-- Pure: what input mode is the window in? Nil when idle.
status_bar.mode_label = function(state)
	if state.leader_active then
		return "LEADER"
	end

	if state.key_table then
		return status_bar.key_table_labels[state.key_table] or state.key_table:upper()
	end

	return nil
end

-- A section is a list of segments: { text = "...", color = "#rrggbb", bold = true }.

-- Pure: the input mode as a section. Nil when idle.
status_bar.mode_section = function(state)
	local label = status_bar.mode_label(state)
	if not label then
		return nil
	end

	return { { text = label, color = palette.gold, bold = true } }
end

-- Pure: zoom state and pane count. Nil for a lone, unzoomed pane.
status_bar.pane_section = function(state)
	local segments = {}

	if state.zoomed then
		table.insert(segments, { text = "ZOOM", color = palette.love, bold = true })
	end

	if state.pane_count > 1 then
		table.insert(segments, { text = state.pane_count .. " panes", color = palette.text })
	end

	return #segments > 0 and segments or nil
end

status_bar.neighbour_name_width = 20

-- Pure: keep the end of a long name behind a leading "…". Workspace names
-- share a prefix (edocs.site.…), so the end is what tells them apart.
status_bar.shorten_name = function(name, width)
	if wezterm.column_width(name) <= width then
		return name
	end

	return "…" .. wezterm.truncate_left(name, width - 1)
end

-- Pure: "‹ prev ● next › (total)", where the marker stands for the current
-- workspace. With two workspaces previous and next are the same, so previous
-- is omitted. Nil with a single workspace.
status_bar.workspace_section = function(names, current)
	if #names < 2 then
		return nil
	end

	for index, name in ipairs(names) do
		if name == current then
			local previous = names[(index - 2) % #names + 1]
			local next_name = names[index % #names + 1]
			local function short(workspace)
				return status_bar.shorten_name(workspace, status_bar.neighbour_name_width)
			end

			-- Both names share a color; the marker between them is the current
			-- workspace, so neither name reads as "active"
			local segments = {}
			if previous ~= next_name then
				table.insert(segments, { text = "‹ " .. short(previous), color = palette.text })
			end
			table.insert(segments, { text = "●", color = palette.iris, bold = true })
			table.insert(segments, { text = short(next_name) .. " ›", color = palette.text })
			table.insert(segments, { text = "(" .. #names .. ")", color = palette.foam })

			return segments
		end
	end

	return nil
end

-- Pure: the non-empty sections of the right status, left to right.
status_bar.right_sections = function(state)
	local sections = {}

	local function add(section)
		if section then
			table.insert(sections, section)
		end
	end

	add(status_bar.mode_section(state))
	add(status_bar.pane_section(state))
	add(status_bar.workspace_section(state.workspace_names, state.workspace))

	return sections
end

-- Each section is a dark box, with a gap of tab bar color between boxes.
-- Empty when there is nothing to show.
status_bar.format_strip = function(sections)
	local items = {}

	for _, section in ipairs(sections) do
		table.insert(items, { Background = { Color = palette.base } })
		table.insert(items, { Text = " " })
		table.insert(items, { Background = { Color = status_bar.colors.box } })
		table.insert(items, { Text = " " })

		for segment_index, segment in ipairs(section) do
			if segment_index > 1 then
				table.insert(items, { Text = " " })
			end
			table.insert(items, { Foreground = { Color = segment.color } })
			table.insert(items, { Attribute = { Intensity = segment.bold and "Bold" or "Normal" } })
			table.insert(items, { Text = segment.text })
		end

		table.insert(items, { Text = " " })
	end

	table.insert(items, "ResetAttributes")

	return items
end

status_bar.read_state = function(window)
	local panes = window:active_tab():panes_with_info()
	local zoomed = false
	for _, pane in ipairs(panes) do
		zoomed = zoomed or pane.is_zoomed
	end

	return {
		leader_active = window:leader_is_active(),
		key_table = window:active_key_table(),
		zoomed = zoomed,
		pane_count = #panes,
		workspace = window:active_workspace(),
		workspace_names = wezterm.mux.get_workspace_names(),
	}
end

-- An error inside update-status blanks the whole bar. Build each side
-- separately so a bug on one side leaves the other intact, and log it.
status_bar.safe_format = function(build)
	local ok, result = pcall(build)
	if ok then
		return result
	end

	wezterm.log_error("status bar: " .. tostring(result))
	return ""
end

status_bar.register = function()
	wezterm.on("update-status", function(window)
		window:set_left_status(status_bar.safe_format(function()
			return wezterm.format(status_bar.format_workspace_section(window))
		end))

		window:set_right_status(status_bar.safe_format(function()
			local sections = status_bar.right_sections(status_bar.read_state(window))
			return wezterm.format(status_bar.format_strip(sections))
		end))
	end)
end

status_bar.register()

return config
