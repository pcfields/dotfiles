local wezterm = require("wezterm")

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

return workspace_history
