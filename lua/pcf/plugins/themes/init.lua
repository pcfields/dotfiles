--------------------------------------------------------------
-- Theme Configuration
-- Change active_theme to switch colorschemes
-- Configure variants/styles inside each theme's own file
--
-- nightfox  >>  nightfox | carbonfox | duskfox | terafox || Light>> dawnfox | dayfox
-- rosepine  >>  rose-pine | rose-pine-main | rose-pine-moon | rose-pine-dawn
-- oldworld  >>  oldworld (variants: default | oled | cooler)
-- kanagawa  >>  kanagawa | kanagawa-wave | kanagawa-dragon | kanagawa-lotus
--------------------------------------------------------------

local active_theme = "oldworld"

local themes = {
	nightfox = require("pcf.plugins.themes.nightfox"),
	rosepine = require("pcf.plugins.themes.rosepine"),
	oldworld = require("pcf.plugins.themes.oldworld"),
	kanagawa = require("pcf.plugins.themes.kanagawa"),
}

local specs = {}

for name, theme in pairs(themes) do
	table.insert(specs, theme.spec(name == active_theme))
end

return specs
