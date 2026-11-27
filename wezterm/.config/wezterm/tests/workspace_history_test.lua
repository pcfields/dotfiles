-- LEADER w, back to the previous workspace.
local wezterm = require("wezterm")
local fakes = require("tests.fakes")

local cases, test = require("tests.cases")()

-- Visits each workspace in turn, then presses LEADER w `presses` times.
local function go_back(fields)
	wezterm.GLOBAL.workspace_history = nil
	for _, workspace in ipairs(fields.visits) do
		fakes.update_status({ workspace = workspace, workspace_names = fields.names })
	end

	local window = fakes.window({ workspace = fields.visits[#fields.visits] })
	for _ = 1, fields.presses or 1 do
		fakes.key_callback("LEADER", "w")(window, {})
	end
	return window.performed
end

local function switch_to(name)
	return wezterm.action.SwitchToWorkspace({ name = name })
end

test("LEADER w goes back to the previous workspace", function(t)
	local performed = go_back({ visits = { "a", "b" }, names = { "a", "b" } })
	t.eq(fakes.same_action(performed[1], switch_to("a")), true, "action")
end)

test("LEADER w pressed twice toggles back", function(t)
	local performed = go_back({ visits = { "a", "b" }, names = { "a", "b" }, presses = 2 })
	t.eq(fakes.same_action(performed[2], switch_to("b")), true, "action")
end)

test("LEADER w does nothing when the previous workspace is gone", function(t)
	t.eq(#go_back({ visits = { "a", "b" }, names = { "b" } }), 0, "actions")
end)

test("LEADER w does nothing with no history", function(t)
	t.eq(#go_back({ visits = {}, names = { "a" } }), 0, "actions")
end)

return cases
