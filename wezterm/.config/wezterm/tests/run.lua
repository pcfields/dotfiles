-- Runs the WezTerm config tests inside WezTerm's own Lua:
--   wezterm --config-file wezterm/.config/wezterm/tests/run.lua show-keys
-- A config that raises an error makes WezTerm fall back to its defaults and
-- still exit 0, so the outcome is reported by os.exit and a final line.
local wezterm = require("wezterm")

local tests_dir = wezterm.config_dir
local config_path = tests_dir .. "/../wezterm.lua"
local test_files = {
	"tests.config_test",
	"tests.tab_title_test",
	"tests.status_bar_test",
	"tests.workspace_history_test",
	"tests.projects_test",
}

local harness, load_config

local function main()
	package.path = tests_dir .. "/../?.lua;" .. package.path
	local t = harness()
	local loaded = load_config(config_path)
	require("tests.fakes").install(loaded)

	for _, file in ipairs(test_files) do
		for _, case in ipairs(require(file)) do
			t.test(case.name, function()
				case.body(t, loaded)
			end)
		end
	end

	return t.report()
end

-- Loads the config with event handlers, action callbacks and logged errors
-- captured, so tests can call them the way WezTerm would.
function load_config(path)
	local loaded = { handlers = {}, callbacks = {}, errors = {} }

	wezterm.on = function(event, handler)
		loaded.handlers[event] = loaded.handlers[event] or {}
		table.insert(loaded.handlers[event], handler)
	end

	local action_callback = wezterm.action_callback
	wezterm.action_callback = function(callback)
		local action = action_callback(callback)
		loaded.callbacks[wezterm.json_encode(action)] = callback
		return action
	end

	wezterm.log_error = function(message)
		table.insert(loaded.errors, message)
	end

	loaded.config = dofile(path)
	return loaded
end

function harness()
	local passed, failures = 0, {}
	local t = {}

	function t.test(name, body)
		local ok, err = pcall(body)
		if ok then
			passed = passed + 1
		else
			table.insert(failures, name .. ": " .. tostring(err))
		end
	end

	function t.eq(actual, expected, label)
		if actual ~= expected then
			error(string.format("%s: expected %q, got %q", label or "value", tostring(expected), tostring(actual)), 2)
		end
	end

	function t.report()
		for _, failure in ipairs(failures) do
			io.stderr:write("FAIL  " .. failure .. "\n")
		end
		io.stderr:write(string.format("wezterm tests: %d passed, %d failed\n", passed, #failures))
		return #failures == 0
	end

	return t
end

local ok, result = pcall(main)
if not ok then
	io.stderr:write("wezterm tests: error: " .. tostring(result) .. "\n")
end
os.exit(ok and result and 0 or 1)
