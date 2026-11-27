local wezterm = require("wezterm")
local platform = require("pcf.platform")
local projects = require("pcf.projects")
local workspace_history = require("pcf.workspace_history")

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

return {
	mouse_bindings = {
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
	},

	-- Key Tables
	key_tables = {
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
	},

	leader = {
		key = "Space",
		mods = "SHIFT",
		timeout_milliseconds = 2000,
	},

	-- Keybindings
	keys = {
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
	},
}
