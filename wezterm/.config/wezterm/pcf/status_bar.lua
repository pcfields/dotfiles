local wezterm = require("wezterm")
local palette = require("pcf.palette")

local status_bar = {}

status_bar.colors = {
	text = palette.base,
	background = palette.iris,
	-- The workspace badge turns this color while the leader key is active
	leader_background = palette.gold,
	-- Background of each right status box
	box = palette.void,
}

status_bar.badge_background = function(window)
	if window:leader_is_active() then
		return status_bar.colors.leader_background
	end

	return status_bar.colors.background
end

status_bar.format_workspace_section = function(window)
	local colors = status_bar.colors
	local background = status_bar.badge_background(window)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = colors.text } },
		{ Text = " " .. wezterm.nerdfonts.cod_layers .. " " .. window:mux_window():get_workspace() .. "  " },
		"ResetAttributes",
		-- Gap and glyph sit on the bar color; the default background renders grey
		{ Background = { Color = palette.base } },
		{ Text = " " },
		{ Foreground = { Color = background } },
		{ Text = " 󰗘 " },
	}
end

status_bar.key_table_labels = {
	split_panes = "SPLIT",
	resize_panes = "RESIZE",
	copy_mode = "COPY",
	search_mode = "SEARCH",
}

-- Pure: what input mode is the window in? Nil when idle.
status_bar.mode_label = function(state)
	if state.leader_active then
		return "LEADER"
	end

	if state.key_table then
		return status_bar.key_table_labels[state.key_table] or state.key_table:upper()
	end

	return nil
end

-- A section is a list of segments: { text = "...", color = "#rrggbb", bold = true }.

-- Pure: the input mode as a section. Nil when idle.
status_bar.mode_section = function(state)
	local label = status_bar.mode_label(state)
	if not label then
		return nil
	end

	return { { text = label, color = palette.gold, bold = true } }
end

-- Pure: zoom state and pane count. Nil for a lone, unzoomed pane.
status_bar.pane_section = function(state)
	local segments = {}

	if state.zoomed then
		table.insert(segments, { text = "ZOOM", color = palette.love, bold = true })
	end

	if state.pane_count > 1 then
		table.insert(segments, { text = state.pane_count .. " panes", color = palette.text })
	end

	return #segments > 0 and segments or nil
end

status_bar.neighbour_name_width = 20

-- Pure: keep the end of a long name behind a leading "…". Workspace names
-- share a prefix (edocs.site.…), so the end is what tells them apart.
status_bar.shorten_name = function(name, width)
	if wezterm.column_width(name) <= width then
		return name
	end

	return "…" .. wezterm.truncate_left(name, width - 1)
end

-- Pure: "󰅁 prev 󰇙 next 󰅂 (total)", where the marker stands for the current
-- workspace. With two workspaces previous and next are the same, so previous
-- is omitted. Nil with a single workspace.
status_bar.workspace_section = function(names, current)
	if #names < 2 then
		return nil
	end

	for index, name in ipairs(names) do
		if name == current then
			local previous = names[(index - 2) % #names + 1]
			local next_name = names[index % #names + 1]
			local function short(workspace)
				return status_bar.shorten_name(workspace, status_bar.neighbour_name_width)
			end

			-- Both names share a color; the marker between them is the current
			-- workspace, so neither name reads as "active"
			local segments = {}
			if previous ~= next_name then
				table.insert(segments, { text = "󰅁 " .. short(previous), color = palette.text })
			end
			table.insert(segments, { text = "󰇙", color = palette.love, bold = true })
			table.insert(segments, { text = short(next_name) .. " 󰅂", color = palette.text })
			table.insert(segments, { text = "(" .. #names .. ")", color = palette.foam })

			return segments
		end
	end

	return nil
end

-- Pure: the non-empty sections of the right status, left to right.
status_bar.right_sections = function(state)
	local sections = {}

	local function add(section)
		if section then
			table.insert(sections, section)
		end
	end

	add(status_bar.mode_section(state))
	add(status_bar.pane_section(state))
	add(status_bar.workspace_section(state.workspace_names, state.workspace))

	return sections
end

-- Each section is a dark box, with a gap of tab bar color between boxes.
-- Empty when there is nothing to show.
status_bar.format_strip = function(sections)
	local items = {}

	for _, section in ipairs(sections) do
		table.insert(items, { Background = { Color = palette.base } })
		table.insert(items, { Text = " " })
		table.insert(items, { Background = { Color = status_bar.colors.box } })
		table.insert(items, { Text = " " })

		for segment_index, segment in ipairs(section) do
			if segment_index > 1 then
				table.insert(items, { Text = " " })
			end
			table.insert(items, { Foreground = { Color = segment.color } })
			table.insert(items, { Attribute = { Intensity = segment.bold and "Bold" or "Normal" } })
			table.insert(items, { Text = segment.text })
		end

		table.insert(items, { Text = " " })
	end

	table.insert(items, "ResetAttributes")

	return items
end

status_bar.read_state = function(window)
	local panes = window:active_tab():panes_with_info()
	local zoomed = false
	for _, pane in ipairs(panes) do
		zoomed = zoomed or pane.is_zoomed
	end

	return {
		leader_active = window:leader_is_active(),
		key_table = window:active_key_table(),
		zoomed = zoomed,
		pane_count = #panes,
		workspace = window:active_workspace(),
		workspace_names = wezterm.mux.get_workspace_names(),
	}
end

-- An error inside update-status blanks the whole bar. Build each side
-- separately so a bug on one side leaves the other intact, and log it.
status_bar.safe_format = function(build)
	local ok, result = pcall(build)
	if ok then
		return result
	end

	wezterm.log_error("status bar: " .. tostring(result))
	return ""
end

status_bar.register = function()
	wezterm.on("update-status", function(window)
		window:set_left_status(status_bar.safe_format(function()
			return wezterm.format(status_bar.format_workspace_section(window))
		end))

		window:set_right_status(status_bar.safe_format(function()
			local sections = status_bar.right_sections(status_bar.read_state(window))
			return wezterm.format(status_bar.format_strip(sections))
		end))
	end)
end

return status_bar
