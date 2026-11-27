-- The LEADER SHIFT+F project picker.
local wezterm = require("wezterm")
local fakes = require("tests.fakes")

local cases, test = require("tests.cases")()

local function open_picker()
	local window = fakes.window({ workspace = "a" })
	fakes.key_callback("LEADER|SHIFT", "F")(window, {})
	return window.performed[1].InputSelector
end

-- Runs the picker's selection callback; returns the actions it performed
local function choose(id, label)
	local window = fakes.window({ workspace = "a" })
	fakes.callback(open_picker().action)(window, {}, id, label)
	return window.performed
end

test("LEADER SHIFT+F opens a fuzzy picker listing dotfiles first", function(t)
	local picker = open_picker()
	t.eq(picker.title, "Choose a project", "title")
	t.eq(picker.fuzzy, true, "fuzzy")
	t.eq(picker.choices[1].label, "dotfiles", "first choice")
	t.eq(picker.choices[1].id, wezterm.home_dir .. "/dotfiles", "first id")
end)

test("choosing a project switches to a workspace named after it", function(t)
	local performed = choose("/home/me/ws/learn/rust", "learn/rust")
	local expected = wezterm.action.SwitchToWorkspace({
		name = "learn/rust",
		spawn = { label = "Workspace: learn/rust", cwd = "/home/me/ws/learn/rust" },
	})
	t.eq(fakes.same_action(performed[1], expected), true, "action")
end)

test("cancelling the picker does nothing", function(t)
	t.eq(#choose(nil, nil), 0, "actions")
end)

return cases
