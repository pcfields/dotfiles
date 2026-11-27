local wezterm = require("wezterm")
local palette = require("pcf.palette")
local platform = require("pcf.platform")

-- The built-in scheme leaves the tab bar in WezTerm's default greys, so
-- register a copy of it with tab colors taken from the same palette.
local color_scheme = "rose-pine-moon"
local scheme = wezterm.color.get_builtin_schemes()[color_scheme]
scheme.tab_bar = {
	inactive_tab_edge = palette.overlay,
	active_tab = { bg_color = palette.overlay, fg_color = palette.text },
	inactive_tab = { bg_color = palette.base, fg_color = palette.muted },
	inactive_tab_hover = { bg_color = palette.surface, fg_color = palette.subtle },
	new_tab = { bg_color = palette.base, fg_color = palette.muted },
	new_tab_hover = { bg_color = palette.surface, fg_color = palette.text },
}
-- The built-in selection is a faint fill that barely differs from the
-- background; a solid iris block with dark text is clearly visible.
scheme.selection_bg = palette.iris
scheme.selection_fg = palette.base

local no_ligatures = { "calt=0", "clig=0", "liga=0" }

return {
	color_schemes = { [color_scheme .. "-tabs"] = scheme },
	color_scheme = color_scheme .. "-tabs",

	-- Tab bar font and background (the fancy tab bar draws these separately
	-- from the terminal font)
	window_frame = {
		font = wezterm.font({ family = "Monaspace Neon", weight = "DemiBold" }),
		font_size = 12.0,
		active_titlebar_bg = palette.base,
		inactive_titlebar_bg = palette.base,
		button_fg = palette.subtle,
		button_bg = palette.base,
		button_hover_fg = palette.text,
		button_hover_bg = palette.overlay,
	},
	font_size = platform.font_size,
	font = wezterm.font_with_fallback({
		{ family = "Monaspace Neon", weight = "Regular", harfbuzz_features = no_ligatures },
		{ family = "JetBrains Mono", weight = "Regular", harfbuzz_features = no_ligatures },
	}),
	-- Window buttons live in the tab bar instead of an OS title bar
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
	tab_max_width = 32,
	inactive_pane_hsb = { saturation = 0.5, brightness = 0.4 },
}
