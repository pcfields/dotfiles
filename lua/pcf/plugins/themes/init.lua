--------------------------------------------------------------
-- Theme Configuration
-- Available themes: nightfox | rosepine | oldworld
--------------------------------------------------------------

local themes = {
	nightfox = require("pcf.plugins.themes.nightfox"),
	rosepine = require("pcf.plugins.themes.rosepine"),
	oldworld = require("pcf.plugins.themes.oldworld"),
}

local M = {}

function M.setup(active_theme)
	local specs = {}

	for name, theme in pairs(themes) do
		table.insert(specs, theme.spec(name == active_theme))
	end

	return specs
end

return M
