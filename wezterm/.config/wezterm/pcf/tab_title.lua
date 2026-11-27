local wezterm = require("wezterm")
local palette = require("pcf.palette")

local tab_title = {}

tab_title.shells = {
	pwsh = true,
	powershell = true,
	fish = true,
	bash = true,
	zsh = true,
	cmd = true,
	nu = true,
}

tab_title.process_name = function(pane)
	local base = (pane.foreground_process_name or ""):match("([^/\\]+)$")
	if not base then
		return nil
	end

	return (base:gsub("%.exe$", ""))
end

tab_title.cwd_basename = function(pane)
	local cwd = pane.current_working_dir
	if not cwd then
		return nil
	end

	-- 20240203 exposes current_working_dir as a Url object, not a string.
	local path = cwd.file_path or tostring(cwd)
	return path:gsub("[/\\]+$", ""):match("([^/\\]+)$")
end

-- WezTerm defaults a pane's title to its foreground process name until the
-- running program sets its own via an OSC escape sequence (lazygit, vim,
-- etc. do this). If the title doesn't match that default, trust it — this
-- also covers cases like Windows spawning a tool through an intermediate
-- shell (`pwsh -NoExit -Command lazygit`), where process detection only
-- ever sees "pwsh" but the tool has still announced its own title.
tab_title.looks_like_default_title = function(title, process, cwd_basename)
	if not title or title == "" then
		return true
	end

	local lowered = title:lower()

	-- A bare path: fish's idle title on Linux (`~/dotfiles`), or the
	-- executable path Windows consoles fall back to (`C:\...\cmd.exe`).
	if lowered:match("^[~/]") or lowered:match("^%a:\\") then
		return true
	end

	-- fish titles a running command as `<command> <cwd>`.
	local first_word = lowered:match("^(%S+)")
	if process and first_word == process:lower() then
		return true
	end

	if cwd_basename and lowered == cwd_basename:lower() then
		return true
	end

	return tab_title.shells[lowered] or false
end

-- Tools like lazygit title themselves "<repo> - <tool>". The location is
-- already on the workspace badge, so keep just the tool.
tab_title.strip_location_prefix = function(title, cwd_basename)
	if not cwd_basename then
		return title
	end

	local prefix = cwd_basename:lower() .. " - "
	if title:sub(1, #prefix):lower() == prefix and #title > #prefix then
		return title:sub(#prefix + 1)
	end

	return title
end

tab_title.describe = function(tab)
	if tab.tab_title and tab.tab_title ~= "" then
		return tab.tab_title
	end

	local pane = tab.active_pane
	local process = tab_title.process_name(pane)
	local cwd = tab_title.cwd_basename(pane)

	if not tab_title.looks_like_default_title(pane.title, process, cwd) then
		return tab_title.strip_location_prefix(pane.title, cwd)
	end

	-- A shell tells you nothing; where it is does. A tool names itself.
	if not process or tab_title.shells[process:lower()] then
		return cwd or process or pane.title
	end

	return process
end

tab_title.color = function(is_active, hover)
	if is_active then
		return palette.text
	end

	return hover and palette.subtle or palette.muted
end

tab_title.max_pips = 4

-- Pure: one pip per pane, so a count never reads as a second tab number.
-- Past the cap the rest collapse into a "+".
tab_title.pips = function(pane_count)
	local shown = math.min(pane_count, tab_title.max_pips)
	return ("▪"):rep(shown) .. (pane_count > shown and "+" or "")
end

-- Pure: small markers after the title, in order: zoom, then one pip per pane
-- (only when split).
tab_title.indicators = function(state)
	local pieces = {}

	if state.zoomed then
		table.insert(pieces, { text = "ZOOM", color = palette.love, bold = true })
	end

	if state.pane_count > 1 then
		table.insert(pieces, { text = tab_title.pips(state.pane_count), color = palette.subtle })
	end

	return pieces
end

tab_title.read_state = function(panes)
	local state = { pane_count = #panes, zoomed = false }

	for _, pane in ipairs(panes) do
		state.zoomed = state.zoomed or pane.is_zoomed
	end

	return state
end

tab_title.register = function()
	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		-- The handler's own `panes` argument covers only the active tab, so
		-- ask the mux for this tab's panes.
		local mux_tab = wezterm.mux.get_tab(tab.tab_id)
		local panes = mux_tab and mux_tab:panes_with_info() or {}
		local indicators = tab_title.indicators(tab_title.read_state(panes))

		-- Reserve room for the number and the indicators; only the title is
		-- truncated, so neither is ever cut off.
		local number = " " .. (tab.tab_index + 1) .. ":"
		local reserved = wezterm.column_width(number)
		for _, piece in ipairs(indicators) do
			reserved = reserved + wezterm.column_width(piece.text) + 1
		end
		local title = wezterm.truncate_right(" " .. tab_title.describe(tab) .. " ", math.max(0, max_width - reserved))

		-- ResetAttributes does not restore the tab bar colors here, so the
		-- title color is set explicitly (these match scheme.tab_bar).
		local items = {
			{ Foreground = { Color = palette.iris } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = number },
			{ Attribute = { Intensity = "Normal" } },
			{ Foreground = { Color = tab_title.color(tab.is_active, hover) } },
			{ Text = title },
		}

		for _, piece in ipairs(indicators) do
			table.insert(items, { Foreground = { Color = piece.color } })
			table.insert(items, { Attribute = { Intensity = piece.bold and "Bold" or "Normal" } })
			table.insert(items, { Text = piece.text .. " " })
		end

		return items
	end)
end

return tab_title
