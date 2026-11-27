local wezterm = require("wezterm")
local platform = require("pcf.platform")

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

return { picker = display_project_list }
