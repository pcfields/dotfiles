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
	{ mods = "LEADER", key = "m", action = wezterm.action.TogglePaneZoomState },
	{ mods = "LEADER", key = "'", action = wezterm.action.RotatePanes("Clockwise") },
	{ mods = "LEADER", key = "v", action = wezterm.action.PaneSelect({ mode = "Activate" }) },

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

tab_title.describe = function(tab)
	if tab.tab_title and tab.tab_title ~= "" then
		return tab.tab_title
	end

	local pane = tab.active_pane
	local process = tab_title.process_name(pane)
	local cwd = tab_title.cwd_basename(pane)

	if not tab_title.looks_like_default_title(pane.title, process, cwd) then
		return pane.title
	end

	-- A shell tells you nothing; where it is does. A tool names itself.
	if not process or tab_title.shells[process:lower()] then
		return cwd or process or pane.title
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

-- ============================================================================
-- STATUS BAR MODULE
-- ============================================================================

local status_bar = {}

status_bar.colors = {
	text = palette.base,
	background = palette.iris,
	-- The workspace badge turns this color while the leader key is active
	leader_background = palette.gold,
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
		{ Foreground = { Color = background } },
		{ Text = " 󰗘 " },
		{ Background = { Color = background } },
	}
end

status_bar.register = function()
	wezterm.on("update-status", function(window)
		window:set_left_status(wezterm.format(status_bar.format_workspace_section(window)))
	end)
end

status_bar.register()

return config
