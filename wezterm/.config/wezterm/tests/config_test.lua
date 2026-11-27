-- The returned config: what WezTerm reads once at load time.
local wezterm = require("wezterm")
local fakes = require("tests.fakes")

local cases, test = require("tests.cases")()

local function binding(list, mods, key)
	for _, entry in ipairs(list) do
		if entry.mods == mods and entry.key == key then
			return entry
		end
	end
end

test("leader is SHIFT+Space for two seconds", function(t, loaded)
	t.eq(loaded.config.leader.key, "Space")
	t.eq(loaded.config.leader.mods, "SHIFT")
	t.eq(loaded.config.leader.timeout_milliseconds, 2000)
end)

test("loading logs no errors", function(t, loaded)
	t.eq(#loaded.errors, 0, "errors: " .. table.concat(loaded.errors, "; "))
end)

test("registers one tab title handler and two status handlers", function(t, loaded)
	t.eq(#(loaded.handlers["format-tab-title"] or {}), 1, "format-tab-title")
	t.eq(#(loaded.handlers["update-status"] or {}), 2, "update-status")
end)

test("LEADER 1 to 6 jump to tabs 0 to 5", function(t, loaded)
	for number = 1, 6 do
		local entry = binding(loaded.config.keys, "LEADER", tostring(number))
		t.eq(fakes.same_action(entry.action, wezterm.action.ActivateTab(number - 1)), true, "tab " .. number)
	end
end)

test("copy mode y copies, clears the selection and closes", function(t, loaded)
	local entry = binding(loaded.config.key_tables.copy_mode, "NONE", "mapped:y")
	local expected = wezterm.action.Multiple({
		wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
		wezterm.action.ClearSelection,
		wezterm.action.CopyMode("Close"),
	})
	t.eq(fakes.same_action(entry.action, expected), true, "action")
end)

test("copy mode keeps the other default keys", function(t, loaded)
	local copy_mode = loaded.config.key_tables.copy_mode
	t.eq(#copy_mode, #wezterm.gui.default_key_tables().copy_mode, "binding count")
	local quit = binding(copy_mode, "NONE", "mapped:q")
	t.eq(fakes.same_action(quit.action, wezterm.action.CopyMode("Close")), true, "q")
end)

return cases
