local wezterm = require("wezterm")

local config = {} -- This table will hold the configuration.

-- ============================================================================
-- PLATFORM MODULE
-- ============================================================================

local platform = {
	is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc",
}

platform.shell = platform.is_windows and "pwsh.exe"
		or (os.getenv("SHELL") or "/usr/bin/fish")

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
		args = { "pwsh.exe", "-NoExit", "-Command", command }
	elseif platform.shell:find("fish") then
		args = { platform.shell, "-c", command .. "; or read -P 'Press enter to exit...'" }
	else
		-- bash, zsh, etc.
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

local ui_config = {
	color_scheme = "rose-pine-moon",
	font_size = platform.font_size,
	font_config = {
		primary = { family = "Monaspace Neon", weight = "Regular" },
		fallback = { family = "JetBrains Mono", weight = "Regular" },
		disable_ligatures = { "calt=0", "clig=0", "liga=0" },
	},
	window = {
		decorations = "RESIZE|TITLE",
		padding = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	tabs = {
		hide_if_only_one = false,
	},
	panes = {
		inactive_hsb = { saturation = 0.5, brightness = 0.4 },
	},
}

-- ============================================================================
-- PERFORMANCE CONFIGURATION MODULE
-- ============================================================================

local performance_config = {
	max_fps = 120,
	animation_fps = 120,
	front_end = "WebGpu",
}

-- ============================================================================
-- PROJECT PROFILES
-- ============================================================================

local project_profiles = {
	work = {
		root = "C:/Projects",
		manual = {
			{
				path = "C:/Projects/gliderbim.webapp/GliderBim.WebApp",
				label = "GliderBim WebApp",
			},
			-- Additional work projects can be added here
		},
		exclude = {
			"C:/Projects/gliderbim.webapp", -- Exclude parent folder since we use the inner path
		},
	},
	personal = {
		root = platform.home_dir .. "/ws",
		manual = {
			-- Specific personal projects can be added here
		},
		folders = { "scratchpad", "learn", "personal", "clients" },
	},
}

-- ============================================================================
-- SHARED CONFIGURATION (Platform-agnostic)
-- ============================================================================
local shared_config = {
	dotfiles = function()
		return platform.home_dir .. "/dotfiles"
	end,
}

-- ============================================================================
-- PROJECT UTILITIES MODULE
-- ============================================================================

local project_utils = {}

project_utils.is_folder = function(path)
	-- Use WezTerm's read_dir to check if path is actually a directory
	local success, _ = pcall(wezterm.read_dir, path)
	return success
end

project_utils.normalize_path = function(path)
	-- Normalize path separators and case for comparison
	return path:gsub("\\", "/"):lower()
end

project_utils.is_excluded = function(path, exclude_list)
	local normalized = project_utils.normalize_path(path)

	for _, excluded_path in ipairs(exclude_list or {}) do
		if normalized == project_utils.normalize_path(excluded_path) then
			return true
		end
	end

	return false
end

project_utils.add_paths_to_list = function(projects_list, options)
	local exclude_list = options.exclude or {}

	for _, project_directory in ipairs(options.directories) do
		local folder_name = project_directory:match("([^/\\]+)$") -- Handle both / and \ separators

		-- Only add if it's actually a directory and not excluded
		if project_utils.is_folder(project_directory) and not project_utils.is_excluded(project_directory, exclude_list) then
			table.insert(projects_list, { id = project_directory, label = folder_name })
		end
	end
end

-- ============================================================================
-- PROJECT DIRECTORY SCANNER
-- ============================================================================

local function add_subdirectories_for(root_directory)
	return wezterm.glob(root_directory .. "/*")
end

-- ============================================================================
-- PROJECT LIST BUILDER MODULE
-- ============================================================================

local project_list_builder = {}

project_list_builder.add_shared_entry = function(projects_list)
	table.insert(projects_list, { id = shared_config.dotfiles(), label = "dotfiles" })
end

project_list_builder.add_manual_projects = function(projects_list, projects, exclude)
	if not projects then
		return
	end

	local exclude_list = exclude or {}

	for _, project in ipairs(projects) do
		if not project_utils.is_excluded(project.path, exclude_list) then
			table.insert(projects_list, { id = project.path, label = project.label })
		end
	end
end

project_list_builder.add_directory_glob = function(projects_list, directories, exclude)
	if not directories then
		return
	end

	project_utils.add_paths_to_list(projects_list, {
		directories = directories,
		exclude = exclude,
	})
end

project_list_builder.add_project_folders = function(projects_list, root_path, folders, exclude)
	if not folders or #folders == 0 then
		return
	end

	for _, folder_name in ipairs(folders) do
		local project_path = root_path .. "/" .. folder_name
		project_utils.add_paths_to_list(projects_list, {
			directories = add_subdirectories_for(project_path),
			exclude = exclude,
		})
	end
end

project_list_builder.populate_from_profile = function(projects_list, profile)
	project_list_builder.add_shared_entry(projects_list)
	project_list_builder.add_manual_projects(projects_list, profile.manual, profile.exclude)

	if profile.folders then
		project_list_builder.add_project_folders(projects_list, profile.root, profile.folders, profile.exclude)
	else
		project_list_builder.add_directory_glob(projects_list, add_subdirectories_for(profile.root), profile.exclude)
	end
end

-- ============================================================================
-- PROJECT PROFILE SETUP
-- ============================================================================

local function setup_projects(projects_list, profile_key)
	local profile = project_profiles[profile_key]
	if not profile then
		return
	end

	project_list_builder.populate_from_profile(projects_list, profile)
end

-- ============================================================================
-- PROJECT LIST DISPLAY
-- ============================================================================

local function display_project_list()
	local projects_list = {}

	-- Dispatch to appropriate setup function based on platform
	if platform.is_windows then
		setup_projects(projects_list, "work")
	else
		setup_projects(projects_list, "personal")
	end

	return wezterm.action.InputSelector({
		title = "Choose a project",
		choices = projects_list,
		fuzzy = true,
		action = wezterm.action_callback(function(child_window, child_pane, id, label)
			if not label then
				return
			end

			local directory_name = label:match("([^/]+)$") -- get last segment of directory path

			child_window:perform_action(
				wezterm.action.SwitchToWorkspace({
					name = directory_name,
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

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Shell and Working Directory
config.default_cwd = platform.home_dir
config.default_prog = { platform.shell }

-- UI Settings
config.color_scheme = ui_config.color_scheme
config.font_size = ui_config.font_size
config.font = wezterm.font_with_fallback({
	{
		family = ui_config.font_config.primary.family,
		weight = ui_config.font_config.primary.weight,
		harfbuzz_features = ui_config.font_config.disable_ligatures,
	},
	{
		family = ui_config.font_config.fallback.family,
		weight = ui_config.font_config.fallback.weight,
		harfbuzz_features = ui_config.font_config.disable_ligatures,
	},
})
config.window_decorations = ui_config.window.decorations
config.window_padding = ui_config.window.padding
config.hide_tab_bar_if_only_one_tab = ui_config.tabs.hide_if_only_one
config.tab_max_width = 32
config.inactive_pane_hsb = ui_config.panes.inactive_hsb

-- Performance Settings
config.max_fps = performance_config.max_fps
config.animation_fps = performance_config.animation_fps
config.front_end = performance_config.front_end

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
	-- Copy/Paste
	{ mods = "CTRL|SHIFT", key = "c", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
	{ mods = "CTRL|SHIFT", key = "v", action = wezterm.action.PasteFrom("Clipboard") },

	-- Projects and Tools
	{
		mods = "LEADER",
		key = "p",
		action = wezterm.action_callback(function(child_window, child_pane)
			child_window:perform_action(display_project_list(), child_pane)
		end),
	},
	{ mods = "LEADER", key = "g", action = command_spawners.spawn_tool("LazyGit", "lazygit") },
	{ mods = "LEADER", key = ";", action = command_spawners.spawn_tool("OpenCode", "opencode") },
	{ mods = "LEADER", key = "w", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ mods = "LEADER", key = "n", action = wezterm.action.SwitchWorkspaceRelative(1) },
	{ mods = "LEADER", key = "b", action = wezterm.action.SwitchWorkspaceRelative(-1) },

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
	{ mods = "LEADER", key = "c", action = wezterm.action.RotatePanes("Clockwise") },
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
	{ mods = "LEADER", key = "q", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "LEADER", key = "x", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER", key = "o", action = wezterm.action.ActivateTabRelative(1) },
	{ mods = "LEADER", key = "i", action = wezterm.action.ActivateTabRelative(-1) },
	keymap_builders.go_to_tab(1),
	keymap_builders.go_to_tab(2),
	keymap_builders.go_to_tab(3),
	keymap_builders.go_to_tab(4),
	keymap_builders.go_to_tab(5),
	keymap_builders.go_to_tab(6),

	-- Copy Mode and Scrolling
	{ mods = "LEADER", key = "y", action = wezterm.action.ActivateCopyMode },
	{ mods = "LEADER", key = "f", action = wezterm.action.QuickSelect },
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

	if process and lowered == process:lower() then
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
	text = wezterm.color.parse("#fff"),
	background = wezterm.color.parse("#7b0849"),
}

status_bar.format_workspace_section = function(window)
	local colors = status_bar.colors

	return {
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.text } },
		{ Text = "   " .. window:mux_window():get_workspace() .. "  " },
		"ResetAttributes",
		{ Foreground = { Color = colors.background } },
		{ Text = "" },
		{ Background = { Color = colors.background } },
	}
end

status_bar.leader_prefix = function(window)
	if window:leader_is_active() then
		return "🔴🔴🔴⭕⭕⭕"
	end

	return ""
end

status_bar.register = function()
	wezterm.on("update-right-status", function(window)
		local left_status = {}

		-- Add leader indicator first (leftmost)
		table.insert(left_status, { Text = status_bar.leader_prefix(window) })

		-- Add workspace section to the right of leader indicator
		for _, element in ipairs(status_bar.format_workspace_section(window)) do
			table.insert(left_status, element)
		end

		window:set_left_status(wezterm.format(left_status))
		window:set_right_status("")
	end)
end

status_bar.register()

return config
