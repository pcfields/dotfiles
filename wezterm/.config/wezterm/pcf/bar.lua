-- Shared by the tab titles and the status bar, so both draw panes the same way.
local palette = require("pcf.palette")

local bar = {}

-- A segment is a piece of bar text: { text = "...", color = "#rrggbb", bold = true }.
bar.zoom_segment = { text = "ZOOM", color = palette.love, bold = true }

-- Pure: how many panes there are and whether one of them is zoomed.
function bar.pane_state(panes)
	local state = { pane_count = #panes, zoomed = false }

	for _, pane in ipairs(panes) do
		state.zoomed = state.zoomed or pane.is_zoomed
	end

	return state
end

-- Pure: the format items that draw a segment.
function bar.segment_items(segment)
	return {
		{ Foreground = { Color = segment.color } },
		{ Attribute = { Intensity = segment.bold and "Bold" or "Normal" } },
		{ Text = segment.text },
	}
end

return bar
