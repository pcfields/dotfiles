-- neutrals (dark to light)
local neutrals = {
	warm_bg = "#1c1e1c",
	dark_gray = "#3b4261",
	gray_light = "#4d5c7b",
	warm_gray = "#6b6462",
	muted_stone = "#7a7570",
	ash = "#767676",
	silver = "#c9c7cd",
}

-- purples / pinks (dark to light)
local purples = {
	dusty_rose = "#c27a8f",
	wisteria = "#a087bf",
	lilac = "#af87af",
	blush = "#c48fa5",
	rose = "#c4929b",
	mauve = "#b89cad",
}

-- blues (dark to light)
local blues = {
	slate = "#5f87af",
	steel_blue = "#6b8cba",
	storm = "#5f97b8",
	sky = "#87afaf",
	pale_blue = "#78a9ff",
	ice_blue = "#85b5ba",
	frost = "#8fbcdb",
}

-- greens / teals (dark to light)
local greens = {
	spruce = "#5f8787",
	sea = "#5a9e9b",
	fern = "#6b9f6b",
	sage = "#5faf5f",
	moss = "#5faf6f",
	aqua = "#5faba8",
	bright_green = "#00ff00",
	teal = "#7da8a0",
	dusty_sage = "#8a9a7b",
	olive = "#a8b070",
	mint = "#87d787",
}

-- warm / earth tones (dark to light)
local warms = {
	amber = "#af875f",
	sandy = "#c4a882",
	soft_clay = "#b8a07e",
	peach = "#d4a08a",
	terracotta = "#c4856a",
	orange = "#ff9e64",
}

-- flatten all groups into a single module
local M = {}

local groups = { neutrals, purples, blues, greens, warms }

for _, group in ipairs(groups) do
	for name, hex in pairs(group) do
		M[name] = hex
	end
end

return M
