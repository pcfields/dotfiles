local wezterm = require("wezterm")

-- Modules load from beside this file, so a --config-file run or a worktree
-- uses its own copy rather than the installed one.
package.path = wezterm.config_dir .. "/?.lua;" .. package.path

local config = wezterm.config_builder()

local palette = require("pcf.palette")
local platform = require("pcf.platform")

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

local projects = require("pcf.projects")

local workspace_history = require("pcf.workspace_history")
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
			child_window:perform_action(projects.picker(), child_pane)
		end),
	},
	{ mods = "LEADER", key = "g", action = command_spawners.spawn_tool("LazyGit", "lazygit") },
	{ mods = "LEADER", key = "a", action = command_spawners.spawn_tool("Claude", "claude") }, -- [a]i
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
	{ mods = "LEADER",       key = "z", action = wezterm.action.TogglePaneZoomState },
	{ mods = "LEADER",       key = "'", action = wezterm.action.RotatePanes("Clockwise") },
	{ mods = "LEADER",       key = "m", action = wezterm.action.PaneSelect({ mode = "Activate" }) },
	{ mods = "LEADER|SHIFT", key = "M", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },

	{ mods = "LEADER",       key = "h", action = wezterm.action.ActivatePaneDirection("Left") },
	{ mods = "LEADER",       key = "j", action = wezterm.action.ActivatePaneDirection("Down") },
	{ mods = "LEADER",       key = "k", action = wezterm.action.ActivatePaneDirection("Up") },
	{ mods = "LEADER",       key = "l", action = wezterm.action.ActivatePaneDirection("Right") },
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
	{ mods = "LEADER",       key = "t", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "LEADER|SHIFT", key = "X", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "LEADER",       key = "x", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER",       key = "o", action = wezterm.action.ActivateTabRelative(1) },
	{ mods = "LEADER",       key = "i", action = wezterm.action.ActivateTabRelative(-1) },
	{ mods = "LEADER|SHIFT", key = "O", action = wezterm.action.MoveTabRelative(1) },
	{ mods = "LEADER|SHIFT", key = "I", action = wezterm.action.MoveTabRelative(-1) },
	{ mods = "LEADER",       key = "e", action = wezterm.action.ActivateLastTab }, -- last tab, pairs with w (last workspace)
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

local tab_title = require("pcf.tab_title")
tab_title.register()

local status_bar = require("pcf.status_bar")
status_bar.register()

return config
