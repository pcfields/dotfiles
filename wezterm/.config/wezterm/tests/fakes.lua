-- Fake tabs, panes and windows standing in for the GUI, so tests can call the
-- config's event handlers and key callbacks the way WezTerm does.
local wezterm = require("wezterm")

local fakes = {}

-- Rosé Pine Moon, as the tests expect to see it drawn
fakes.rose_pine = {
	muted = "#6e6a86",
	subtle = "#908caa",
	text = "#e0def4",
	gold = "#f6c177",
	iris = "#c4a7e7",
	love = "#eb6f92",
}

local loaded
local mux_tabs = {}
local workspace_names = {}

function fakes.install(loaded_config)
	loaded = loaded_config
	wezterm.mux.get_tab = function(tab_id)
		return mux_tabs[tab_id]
	end
	wezterm.mux.get_workspace_names = function()
		return workspace_names
	end
end

function fakes.set_workspace_names(names)
	workspace_names = names
end

-- Runs format-tab-title for a tab described by `fields`, with `panes` as the
-- mux reports them.
function fakes.format_tab(fields)
	local handler = loaded.handlers["format-tab-title"][1]
	return handler(fakes.tab(fields), {}, {}, loaded.config, fields.hover or false, fields.max_width or 32)
end

function fakes.tab(fields)
	local tab_id = #mux_tabs + 1
	local panes = fields.panes or { {} }
	mux_tabs[tab_id] = {
		panes_with_info = function()
			return panes
		end,
	}

	return {
		tab_id = tab_id,
		tab_index = fields.index or 0,
		is_active = fields.is_active ~= false,
		tab_title = fields.tab_title or "",
		active_pane = {
			title = fields.title,
			foreground_process_name = fields.process,
			current_working_dir = fields.cwd and { file_path = fields.cwd },
		},
	}
end

-- Runs every update-status handler, in registration order, for a window
-- described by `state`. Returns the window with the statuses it was given.
function fakes.update_status(state)
	workspace_names = state.workspace_names or { state.workspace }
	local window = fakes.window(state)
	for _, handler in ipairs(loaded.handlers["update-status"]) do
		handler(window)
	end
	return window
end

function fakes.window(state)
	local window = { performed = {} }

	function window:leader_is_active()
		return state.leader or false
	end
	function window:active_key_table()
		return state.key_table
	end
	function window:active_workspace()
		return state.workspace
	end
	function window:mux_window()
		return { get_workspace = function()
			return state.workspace
		end }
	end
	function window:active_tab()
		return { panes_with_info = function()
			return state.panes or { {} }
		end }
	end
	function window:set_left_status(status)
		self.left = status
	end
	function window:set_right_status(status)
		self.right = status
	end
	function window:perform_action(action)
		table.insert(self.performed, action)
	end

	return window
end

-- The callback behind a key binding made with wezterm.action_callback
function fakes.key_callback(mods, key)
	for _, entry in ipairs(loaded.config.keys) do
		if entry.mods == mods and entry.key == key then
			return fakes.callback(entry.action)
		end
	end
end

function fakes.callback(action)
	return loaded.callbacks[wezterm.json_encode(action)]
end

-- The text of format items, without colors or attributes
function fakes.plain(items)
	local text = {}
	for _, item in ipairs(items) do
		if type(item) == "table" and item.Text then
			table.insert(text, item.Text)
		end
	end
	return table.concat(text)
end

-- The foreground color in effect where `text` is drawn
function fakes.color_of(items, text)
	local color
	for _, item in ipairs(items) do
		if type(item) == "table" and item.Foreground then
			color = item.Foreground.Color
		elseif type(item) == "table" and item.Text == text then
			return color
		end
	end
end

-- A formatted status string without its escape sequences
function fakes.strip(status)
	return (status:gsub("\27%[[%d;:]*m", ""):gsub("\27%(B", ""))
end

function fakes.has_background(status, hex)
	local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
	local sequence = string.format("48:2::%d:%d:%d", tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	return status:find(sequence, 1, true) ~= nil
end

function fakes.same_action(actual, expected)
	return wezterm.json_encode(actual) == wezterm.json_encode(expected)
end

return fakes
